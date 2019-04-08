//
//  WGLNetworkMonitor.h
//  WGLNetworkMonitor
//
//  Created by wugl on 2019/3/19.
//  Copyright © 2019年 WGLKit. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WGLNetworkCommon.h"

NS_ASSUME_NONNULL_BEGIN

@interface WGLNetworkMonitor : NSObject

/**
 当前网络可达状态
 */
@property (readonly, nonatomic, assign) WGLNetworkReachabilityStatus networkReachabilityStatus;

/**
 当前网络是否可访问
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

/**
 网络访问技术
 例如，GPRS、WCDMA、LTE等
 */
@property (readonly, nonatomic, assign) WGLNetworkAccessTech networkAccessTech;

@property (readonly) BOOL is2G;
@property (readonly) BOOL is3G;
@property (readonly) BOOL is4G;

/**
 移动网络运营商
 */
@property (readonly, nonatomic, assign) WGLNetworkOperator networkOperator;

/**
 网络状态变化回调block
 */
@property (nonatomic, copy) WGLNetworkReachabilityStatusChangeBlock networkStatusChangeBlock;

//网络状态管理器
+ (instancetype)sharedMonitor;

/**
 开始监视网络可达性状态的变化。
 */
- (void)startMonitoring;

/**
 结束监视网络可达性状态的变化。
 */
- (void)stopMonitoring;


/********************* UIDevice Network Information *********************/

/**
 获取该设备的无线IP地址(can be nil) e.g. @"192.168.1.111"
 */
@property (nullable, nonatomic, readonly) NSString *ipAddressWIFI;

/**
 获取该设备的cell IP地址(can be nil) e.g. @"10.2.2.222"
 */
@property (nullable, nonatomic, readonly) NSString *ipAddressCell;

/**
 获取该设备的ipv4地址(can be nil) e.g. @"172.26.152.158"
 */
@property (nullable, nonatomic, readonly) NSString *ipv4Address;

/**
 获取该设备的ipv6地址(can be nil) e.g. @"fe80::7418:f0cb:f231:71c6"
 */
@property (nullable, nonatomic, readonly) NSString *ipv6Address;


@end

NS_ASSUME_NONNULL_END

