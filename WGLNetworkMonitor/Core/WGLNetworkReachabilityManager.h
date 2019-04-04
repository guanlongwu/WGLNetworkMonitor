//
//  WGLNetworkReachabilityManager.h
//  WGLNetworker
//
//  Created by wugl on 2019/3/18.
//  Copyright © 2019年 WGLKit. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WGLNetworkCommon.h"

#if !TARGET_OS_WATCH
#import <SystemConfiguration/SystemConfiguration.h>


NS_ASSUME_NONNULL_BEGIN

@interface WGLNetworkReachabilityManager : NSObject

/**
 当前网络可达状态.
 */
@property (readonly, nonatomic, assign) WGLNetworkReachabilityStatus networkReachabilityStatus;

/**
 当前网络是否可访问.
 */
@property (readonly, nonatomic, assign, getter = isReachable) BOOL reachable;

/**
 是否可通过WWAN访问网络
 */
@property (readonly, nonatomic, assign, getter = isReachableViaWWAN) BOOL reachableViaWWAN;

/**
 是否可通过WiFi访问网络
 */
@property (readonly, nonatomic, assign, getter = isReachableViaWiFi) BOOL reachableViaWiFi;


+ (instancetype)sharedManager;

/**
 使用默认套接字地址创建并返回网络可访问性管理器.
 */
+ (instancetype)manager;

/**
 创建并返回指定域的网络可访问性管理器
 */
+ (instancetype)managerForDomain:(NSString *)domain;

/**
 为套接字地址创建并返回网络可访问性管理器。
 */
+ (instancetype)managerForAddress:(const void *)address;

/**
 Initializes an instance of a network reachability manager from the specified reachability object.
 
 @param reachability The reachability object to monitor.
 
 @return An initialized network reachability manager, actively monitoring the specified reachability.
 */
- (instancetype)initWithReachability:(SCNetworkReachabilityRef)reachability NS_DESIGNATED_INITIALIZER;

/**
 开始监视网络可达性状态的变化。
 */
- (void)startMonitoring;

/**
 开始监视网络可达性状态的变化。
 */
- (void)stopMonitoring;

/**
 返回当前网络可访问性状态的本地化字符串表示形式。
 */
- (NSString *)localizedNetworkReachabilityStatusString;

/**
 设置当`baseURL`主机的网络可用性发生变化时要执行的回调。

 @param block 当`baseURL`主机的网络可用性发生变化时要执行的块对象。
 该块没有返回值，只取一个参数，表示从设备到`baseURL`的各种可达性状态。
 */
- (void)setReachabilityStatusChangeBlock:(nullable void (^)(WGLNetworkReachabilityStatus status))block;

@end


/**
 返回当前网络可访问性状态的本地化字符串表示形式。
 */
FOUNDATION_EXPORT NSString * WGLStringFromNetworkReachabilityStatus(WGLNetworkReachabilityStatus status);

NS_ASSUME_NONNULL_END

#endif
