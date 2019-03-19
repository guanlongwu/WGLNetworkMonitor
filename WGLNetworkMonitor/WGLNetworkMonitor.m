//
//  WGLNetworkMonitor.m
//  WGLNetworkMonitor
//
//  Created by wugl on 2019/3/19.
//  Copyright © 2019年 WGLKit. All rights reserved.
//

#import "WGLNetworkMonitor.h"
#import "WGLNetworkReachabilityManager.h"
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>

@interface WGLNetworkMonitor ()
@property (nonatomic, strong) WGLNetworkReachabilityManager *reachablilityManager;
@property (nonatomic, strong) CTTelephonyNetworkInfo *networkInfo;
@end

@implementation WGLNetworkMonitor

+ (instancetype)sharedMonitor {
    static WGLNetworkMonitor *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[[self class] alloc] init];
    });
    return instance;
}

- (WGLNetworkReachabilityManager *)reachablilityManager {
    if (!_reachablilityManager) {
        _reachablilityManager = [WGLNetworkReachabilityManager sharedManager];
        __weak typeof(self) weakSelf = self;
        [_reachablilityManager setReachabilityStatusChangeBlock:^(WGLNetworkReachabilityStatus status) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (strongSelf.networkStatusChangeBlock) {
                strongSelf.networkStatusChangeBlock(status);
            }
        }];
    }
    return _reachablilityManager;
}

- (CTTelephonyNetworkInfo *)networkInfo {
    if (!_networkInfo) {
        _networkInfo = [[CTTelephonyNetworkInfo alloc] init];
    }
    return _networkInfo;
}

#pragma mark - 开始监测/结束监测

- (void)startMonitoring {
    [self.reachablilityManager startMonitoring];
}

- (void)stopMonitoring {
    [self.reachablilityManager stopMonitoring];
}

#pragma mark - 网络状态

- (WGLNetworkReachabilityStatus)networkReachabilityStatus {
    return self.reachablilityManager.networkReachabilityStatus;
}

- (BOOL)isReachable {
    return self.reachablilityManager.isReachable;
}

- (BOOL)isReachableViaWWAN {
    return self.reachablilityManager.isReachableViaWWAN;
}

- (BOOL)isReachableViaWiFi {
    return self.reachablilityManager.isReachableViaWiFi;
}

#pragma mark - 移动网络运营商

- (WGLNetworkOperator)networkOperator {
    if (NO == self.isReachableViaWWAN) {
        return WGLNetworkOperatorUnknown;
    }
    
    CTCarrier *carrier = [self.networkInfo subscriberCellularProvider];
    if (carrier == nil) {
        return WGLNetworkOperatorUnknown;
    }
    
    NSString *code = [carrier mobileNetworkCode];
    if ([code isEqualToString:@"00"]
        || [code isEqualToString:@"02"]
        || [code isEqualToString:@"07"]) {
        return WGLNetworkOperatorChinaMobile;
    }
    else if ([code isEqualToString:@"01"]
             || [code isEqualToString:@"06"]) {
        return WGLNetworkOperatorChinaUnicom;
    }
    else if ([code isEqualToString:@"03"]
             || [code isEqualToString:@"05"]) {
        return WGLNetworkOperatorChinaTelecon;
    }
    else if ([code isEqualToString:@"20"]) {
        return WGLNetworkOperatorChinaTietong;
    }
    else {
        return WGLNetworkOperatorUnknown;
    }
}

#pragma mark - 网络访问技术

- (BOOL)is2G {
    WGLNetworkAccessTech value = self.networkAccessTech;
    return value == WGLNetworkAccessTechEdge || value == WGLNetworkAccessTechGPRS;
}

- (BOOL)is3G {
    WGLNetworkAccessTech value = self.networkAccessTech;
    return (value != WGLNetworkAccessTechUnknown)
    && (value != WGLNetworkAccessTechLTE)
    && (value != WGLNetworkAccessTechGPRS)
    && (value != WGLNetworkAccessTechEdge);
}

- (BOOL)is4G {
    WGLNetworkAccessTech value = self.networkAccessTech;
    return value == WGLNetworkAccessTechLTE;
}

- (WGLNetworkAccessTech)networkAccessTech {
    if (NO == self.isReachableViaWWAN){
        return WGLNetworkAccessTechUnknown;
    }
    
    NSString *accessTechValue = [self.networkInfo currentRadioAccessTechnology];
    
    if (!accessTechValue){
        return WGLNetworkAccessTechUnknown;
    }
    
    //按照占有率从高到低
    if ([accessTechValue isEqualToString:CTRadioAccessTechnologyLTE]){
        return WGLNetworkAccessTechLTE;
    }
    else if ([accessTechValue isEqualToString:CTRadioAccessTechnologyWCDMA]){
        return WGLNetworkAccessTechWCDMA;
    }
    else if ([accessTechValue isEqualToString:CTRadioAccessTechnologyEdge]){
        return WGLNetworkAccessTechEdge;
    }
    else if ([accessTechValue isEqualToString:CTRadioAccessTechnologyGPRS]){
        return WGLNetworkAccessTechGPRS;
    }
    else if ([accessTechValue isEqualToString:CTRadioAccessTechnologyHSDPA]){
        return WGLNetworkAccessTechHSDPA;
    }
    else if ([accessTechValue isEqualToString:CTRadioAccessTechnologyHSUPA]){
        return WGLNetworkAccessTechHSUPA;
    }
    else if ([accessTechValue isEqualToString:CTRadioAccessTechnologyCDMA1x]){
        return WGLNetworkAccessTechCDMA1x;
    }
    else if ([accessTechValue isEqualToString:CTRadioAccessTechnologyCDMAEVDORev0]){
        return WGLNetworkAccessTechCDMAEVDORev0;
    }
    else if ([accessTechValue isEqualToString:CTRadioAccessTechnologyCDMAEVDORevA]){
        return WGLNetworkAccessTechCDMAEVDORevA;
    }
    else if ([accessTechValue isEqualToString:CTRadioAccessTechnologyCDMAEVDORevB]){
        return WGLNetworkAccessTechCDMAEVDORevB;
    }
    else if ([accessTechValue isEqualToString:CTRadioAccessTechnologyeHRPD]){
        return WGLNetworkAccessTechHRPD;
    }
    else{
        return WGLNetworkAccessTechUnknown;
    }
}

@end
