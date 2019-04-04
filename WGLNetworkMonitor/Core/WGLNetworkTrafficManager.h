//
//  WGLNetworkTrafficManager.h
//  WGLNetworkMonitor
//
//  Created by wugl on 2019/4/4.
//  Copyright © 2019 WGLKit. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WGLNetworkCommon.h"

NS_ASSUME_NONNULL_BEGIN

@interface WGLNetworkTrafficManager : NSObject

/**
 WWAN上下行网速 (单位：KB/s)
 */
@property (nonatomic, assign, readonly) uint64_t wwanNetworkSpeed;

/**
 WIFI上下行网速 (单位：KB/s)
 */
@property (nonatomic, assign, readonly) uint64_t wifiNetworkSpeed;

/**
 AWDL上下行网速 (单位：KB/s)
 */
@property (nonatomic, assign, readonly) uint64_t awdlNetworkSpeed;

/**
 上下行网速（WWAN + WIFI + AWDL） (单位：KB/s)
 */
@property (nonatomic, assign, readonly) uint64_t allNetworkSpeed;

/**
 是否在监控中状态
 */
@property (nonatomic, assign, readonly) BOOL isMonitoring;

//网络状态管理器
+ (instancetype)sharedManager;

/**
 从此刻开始监控
 */
- (void)startMonitoring;

/**
 从此刻结束监控
 */
- (void)stopMonitoring;



/**
 获取设备的网络流量字节数bytes.
 
 @discussion 获取的是设备上一次开机开始的总网络流量字节数bytes.
 
 Usage:
 
 uint64_t bytes = [WGLNetworkTrafficHelper getNetworkTrafficBytes:WGLNetworkTrafficTypeALL];
 NSTimeInterval time = CACurrentMediaTime();
 
 uint64_t bytesPerSecond = (bytes - _lastBytes) / (time - _lastTime);
 
 _lastBytes = bytes;
 _lastTime = time;
 
 @param types traffic types
 @return bytes counter.
 */
+ (uint64_t)getNetworkTrafficBytes:(WGLNetworkTrafficType)types;


@end

NS_ASSUME_NONNULL_END
