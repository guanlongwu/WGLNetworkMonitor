//
//  WGLNetworkInfoHelper.h
//  WGLNetworkMonitor
//
//  Created by wugl on 2019/4/4.
//  Copyright © 2019 WGLKit. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface WGLNetworkInfoHelper : NSObject

+ (NSString *)ipAddressWIFI;

+ (NSString *)ipAddressCell;

+ (NSString *)ipv4Address;

+ (NSString *)ipv6Address;

@end

NS_ASSUME_NONNULL_END
