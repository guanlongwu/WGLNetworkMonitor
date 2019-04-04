//
//  WGLNetworkCommon.h
//  WGLNetworker
//
//  Created by wugl on 2019/3/18.
//  Copyright © 2019年 WGLKit. All rights reserved.
//

#import <Foundation/Foundation.h>

//网络可达状态
typedef NS_ENUM(NSInteger, WGLNetworkReachabilityStatus) {
    // The `baseURL` host reachability is not known.
    WGLNetworkReachabilityStatusUnknown          = -1,
    // The `baseURL` host cannot be reached.
    WGLNetworkReachabilityStatusNotReachable     = 0,
    // The `baseURL` host can be reached via a cellular connection, such as EDGE or GPRS.
    WGLNetworkReachabilityStatusReachableViaWWAN = 1,
    // The `baseURL` host can be reached via a Wi-Fi connection.
    WGLNetworkReachabilityStatusReachableViaWiFi = 2,
};

//网络移动运营商
typedef NS_ENUM(NSUInteger, WGLNetworkOperator) {
    WGLNetworkOperatorUnknown = 0,  //未知
    WGLNetworkOperatorChinaMobile,  //中国移动
    WGLNetworkOperatorChinaUnicom,  //中国联通
    WGLNetworkOperatorChinaTelecon, //中国电信
    WGLNetworkOperatorChinaTietong  //中国铁通
};

//网络访问技术
typedef NS_ENUM(NSUInteger, WGLNetworkAccessTech) {
    WGLNetworkAccessTechUnknown = 0,
    WGLNetworkAccessTechGPRS,
    WGLNetworkAccessTechEdge,
    WGLNetworkAccessTechWCDMA,
    WGLNetworkAccessTechHSDPA,
    WGLNetworkAccessTechHSUPA,
    WGLNetworkAccessTechCDMA1x,
    WGLNetworkAccessTechCDMAEVDORev0,
    WGLNetworkAccessTechCDMAEVDORevA,
    WGLNetworkAccessTechCDMAEVDORevB,
    WGLNetworkAccessTechHRPD,
    WGLNetworkAccessTechLTE
};

/**
  `WGLNetworkingReachabilityNotificationStatusItem`
   “WGLNetworkingReachabilityDidChangeNotification”通知中userInfo字典中的一个键。
   对应的值是一个`NSNumber`对象，表示当前可达性状态的`WGLNetworkReachabilityStatus`值。
 */
FOUNDATION_EXPORT NSString * const WGLNetworkingReachabilityDidChangeNotification;
FOUNDATION_EXPORT NSString * const WGLNetworkingReachabilityNotificationStatusItem;

/**
 网络流量类型:
 
 WWAN: Wireless Wide Area Network.
 For example: 3G/4G.
 
 WIFI: Wi-Fi.
 
 AWDL: Apple Wireless Direct Link (peer-to-peer connection).
 For exmaple: AirDrop, AirPlay, GameKit.
 */
typedef NS_OPTIONS(NSUInteger, WGLNetworkTrafficType) {
    WGLNetworkTrafficTypeWWANSent     = 1 << 0,
    WGLNetworkTrafficTypeWWANReceived = 1 << 1,
    WGLNetworkTrafficTypeWIFISent     = 1 << 2,
    WGLNetworkTrafficTypeWIFIReceived = 1 << 3,
    WGLNetworkTrafficTypeAWDLSent     = 1 << 4,
    WGLNetworkTrafficTypeAWDLReceived = 1 << 5,
    
    WGLNetworkTrafficTypeWWAN = WGLNetworkTrafficTypeWWANSent | WGLNetworkTrafficTypeWWANReceived,
    WGLNetworkTrafficTypeWIFI = WGLNetworkTrafficTypeWIFISent | WGLNetworkTrafficTypeWIFIReceived,
    WGLNetworkTrafficTypeAWDL = WGLNetworkTrafficTypeAWDLSent | WGLNetworkTrafficTypeAWDLReceived,
    
    WGLNetworkTrafficTypeALL = WGLNetworkTrafficTypeWWAN |
    WGLNetworkTrafficTypeWIFI |
    WGLNetworkTrafficTypeAWDL,
};

/**
 网络状态变化回调block
 */
typedef void (^WGLNetworkReachabilityStatusChangeBlock)(WGLNetworkReachabilityStatus status);

@interface WGLNetworkCommon : NSObject

@end
