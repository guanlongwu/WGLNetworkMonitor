//
//  WGLNetworkReachabilityManager.m
//  WGLNetworker
//
//  Created by wugl on 2019/3/18.
//  Copyright © 2019年 WGLKit. All rights reserved.
//

#import "WGLNetworkReachabilityManager.h"
#if !TARGET_OS_WATCH

#import <netinet/in.h>
#import <netinet6/in6.h>
#import <arpa/inet.h>
#import <ifaddrs.h>
#import <netdb.h>

typedef void (^WGLNetworkReachabilityStatusBlock)(WGLNetworkReachabilityStatus status);

NSString * WGLStringFromNetworkReachabilityStatus(WGLNetworkReachabilityStatus status) {
    switch (status) {
        case WGLNetworkReachabilityStatusNotReachable:
            return NSLocalizedStringFromTable(@"Not Reachable", @"WGLNetworking", nil);
        case WGLNetworkReachabilityStatusReachableViaWWAN:
            return NSLocalizedStringFromTable(@"Reachable via WWAN", @"WGLNetworking", nil);
        case WGLNetworkReachabilityStatusReachableViaWiFi:
            return NSLocalizedStringFromTable(@"Reachable via WiFi", @"WGLNetworking", nil);
        case WGLNetworkReachabilityStatusUnknown:
        default:
            return NSLocalizedStringFromTable(@"Unknown", @"WGLNetworking", nil);
    }
}

//通过SCNetworkReachabilityFlags获取相对应的网络状态WGLNetworkReachabilityStatus
static WGLNetworkReachabilityStatus WGLNetworkReachabilityStatusForFlags(SCNetworkReachabilityFlags flags) {
    BOOL isReachable = ((flags & kSCNetworkReachabilityFlagsReachable) != 0);
    BOOL needsConnection = ((flags & kSCNetworkReachabilityFlagsConnectionRequired) != 0);
    BOOL canConnectionAutomatically = (((flags & kSCNetworkReachabilityFlagsConnectionOnDemand ) != 0) || ((flags & kSCNetworkReachabilityFlagsConnectionOnTraffic) != 0));
    BOOL canConnectWithoutUserInteraction = (canConnectionAutomatically && (flags & kSCNetworkReachabilityFlagsInterventionRequired) == 0);
    BOOL isNetworkReachable = (isReachable && (!needsConnection || canConnectWithoutUserInteraction));
    
    WGLNetworkReachabilityStatus status = WGLNetworkReachabilityStatusUnknown;
    if (isNetworkReachable == NO) {
        status = WGLNetworkReachabilityStatusNotReachable;
    }
#if    TARGET_OS_IPHONE
    else if ((flags & kSCNetworkReachabilityFlagsIsWWAN) != 0) {
        status = WGLNetworkReachabilityStatusReachableViaWWAN;
    }
#endif
    else {
        status = WGLNetworkReachabilityStatusReachableViaWiFi;
    }
    
    return status;
}

/**
 将网络状态更改通知处理，放到一个主线程队列中排队处理。
 这样做是为了确保以与发送时相同的顺序来接收通知。
 如果直接发送通知，则可能在稍后更新后处理排队通知（对于较早的状态条件），从而导致侦听器处于错误状态
 */
static void WGLPostReachabilityStatusChange(SCNetworkReachabilityFlags flags, WGLNetworkReachabilityStatusBlock block) {
    WGLNetworkReachabilityStatus status = WGLNetworkReachabilityStatusForFlags(flags);
    dispatch_async(dispatch_get_main_queue(), ^{
        if (block) {
            block(status);
        }
        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        NSDictionary *userInfo = @{ WGLNetworkingReachabilityNotificationStatusItem: @(status) };
        [notificationCenter postNotificationName:WGLNetworkingReachabilityDidChangeNotification object:nil userInfo:userInfo];
    });
}

//SCNetworkReachabilitySetCallback回调函数
static void WGLNetworkReachabilityCallback(SCNetworkReachabilityRef __unused target, SCNetworkReachabilityFlags flags, void *info) {
    WGLPostReachabilityStatusChange(flags, (__bridge WGLNetworkReachabilityStatusBlock)info);
}


static const void * WGLNetworkReachabilityRetainCallback(const void *info) {
    return Block_copy(info);
}

static void WGLNetworkReachabilityReleaseCallback(const void *info) {
    if (info) {
        Block_release(info);
    }
}


@interface WGLNetworkReachabilityManager ()
@property (readonly, nonatomic, assign) SCNetworkReachabilityRef networkReachability;
@property (readwrite, nonatomic, assign) WGLNetworkReachabilityStatus networkReachabilityStatus;
@property (readwrite, nonatomic, copy) WGLNetworkReachabilityStatusBlock networkReachabilityStatusBlock;    //状态回调block
@end

@implementation WGLNetworkReachabilityManager

+ (instancetype)sharedManager {
    static WGLNetworkReachabilityManager *_sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedManager = [self manager];
    });
    
    return _sharedManager;
}

+ (instancetype)managerForDomain:(NSString *)domain {
    SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithName(kCFAllocatorDefault, [domain UTF8String]);
    
    WGLNetworkReachabilityManager *manager = [[self alloc] initWithReachability:reachability];
    
    CFRelease(reachability);
    
    return manager;
}

+ (instancetype)managerForAddress:(const void *)address {
    SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, (const struct sockaddr *)address);
    WGLNetworkReachabilityManager *manager = [[self alloc] initWithReachability:reachability];
    
    CFRelease(reachability);
    
    return manager;
}

+ (instancetype)manager
{
#if (defined(__IPHONE_OS_VERSION_MIN_REQUIRED) && __IPHONE_OS_VERSION_MIN_REQUIRED >= 90000) || (defined(__MAC_OS_X_VERSION_MIN_REQUIRED) && __MAC_OS_X_VERSION_MIN_REQUIRED >= 101100)
    struct sockaddr_in6 address;
    bzero(&address, sizeof(address));
    address.sin6_len = sizeof(address);
    address.sin6_family = AF_INET6;
#else
    struct sockaddr_in address;
    bzero(&address, sizeof(address));
    address.sin_len = sizeof(address);
    address.sin_family = AF_INET;
#endif
    return [self managerForAddress:&address];
}

- (instancetype)initWithReachability:(SCNetworkReachabilityRef)reachability {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _networkReachability = CFRetain(reachability);
    self.networkReachabilityStatus = WGLNetworkReachabilityStatusUnknown;
    
    return self;
}

- (instancetype)init NS_UNAVAILABLE
{
    return nil;
}

- (void)dealloc {
    [self stopMonitoring];
    
    if (_networkReachability != NULL) {
        CFRelease(_networkReachability);
    }
}

#pragma mark - 网络是否可用

- (BOOL)isReachable {
    return [self isReachableViaWWAN] || [self isReachableViaWiFi];
}

- (BOOL)isReachableViaWWAN {
    return self.networkReachabilityStatus == WGLNetworkReachabilityStatusReachableViaWWAN;
}

- (BOOL)isReachableViaWiFi {
    return self.networkReachabilityStatus == WGLNetworkReachabilityStatusReachableViaWiFi;
}

#pragma mark - 开始监控/结束监控

- (void)startMonitoring {
    [self stopMonitoring];
    
    if (!self.networkReachability) {
        return;
    }
    
    __weak __typeof(self)weakSelf = self;
    WGLNetworkReachabilityStatusBlock callback = ^(WGLNetworkReachabilityStatus status) {
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        
        //网络状态变化会回调到这里
        strongSelf.networkReachabilityStatus = status;
        if (strongSelf.networkReachabilityStatusBlock) {
            strongSelf.networkReachabilityStatusBlock(status);
        }
        
    };
    
    SCNetworkReachabilityContext context = {0, (__bridge void *)callback, WGLNetworkReachabilityRetainCallback, WGLNetworkReachabilityReleaseCallback, NULL};
    SCNetworkReachabilitySetCallback(self.networkReachability, WGLNetworkReachabilityCallback, &context);
    SCNetworkReachabilityScheduleWithRunLoop(self.networkReachability, CFRunLoopGetMain(), kCFRunLoopCommonModes);
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),^{
        SCNetworkReachabilityFlags flags;
        if (SCNetworkReachabilityGetFlags(self.networkReachability, &flags)) {
            WGLPostReachabilityStatusChange(flags, callback);
        }
    });
}

- (void)stopMonitoring {
    if (!self.networkReachability) {
        return;
    }
    
    SCNetworkReachabilityUnscheduleFromRunLoop(self.networkReachability, CFRunLoopGetMain(), kCFRunLoopCommonModes);
}

#pragma mark -

- (NSString *)localizedNetworkReachabilityStatusString {
    return WGLStringFromNetworkReachabilityStatus(self.networkReachabilityStatus);
}

#pragma mark - 设置回调block

- (void)setReachabilityStatusChangeBlock:(void (^)(WGLNetworkReachabilityStatus status))block {
    self.networkReachabilityStatusBlock = block;
}

#pragma mark - NSKeyValueObserving

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
    if ([key isEqualToString:@"reachable"] || [key isEqualToString:@"reachableViaWWAN"] || [key isEqualToString:@"reachableViaWiFi"]) {
        return [NSSet setWithObject:@"networkReachabilityStatus"];
    }
    
    return [super keyPathsForValuesAffectingValueForKey:key];
}

@end
#endif
