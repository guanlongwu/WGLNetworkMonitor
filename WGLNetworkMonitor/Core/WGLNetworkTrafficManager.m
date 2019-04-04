//
//  WGLNetworkTrafficManager.m
//  WGLNetworkMonitor
//
//  Created by wugl on 2019/4/4.
//  Copyright © 2019 WGLKit. All rights reserved.
//

#import "WGLNetworkTrafficManager.h"
#include <net/if.h>
#include <net/if_dl.h>
#include <arpa/inet.h>
#include <ifaddrs.h>

typedef struct {
    uint64_t en_in;
    uint64_t en_out;
    uint64_t pdp_ip_in;
    uint64_t pdp_ip_out;
    uint64_t awdl_in;
    uint64_t awdl_out;
} wgl_net_interface_counter;

static uint64_t wgl_net_counter_add(uint64_t counter, uint64_t bytes) {
    if (bytes < (counter % 0xFFFFFFFF)) {
        counter += 0xFFFFFFFF - (counter % 0xFFFFFFFF);
        counter += bytes;
    } else {
        counter = bytes;
    }
    return counter;
}

static uint64_t wgl_net_counter_get_by_type(wgl_net_interface_counter *counter, WGLNetworkTrafficType type) {
    uint64_t bytes = 0;
    if (type & WGLNetworkTrafficTypeWWANSent) {
        bytes += counter->pdp_ip_out;
    }
    if (type & WGLNetworkTrafficTypeWWANReceived) {
        bytes += counter->pdp_ip_in;
    }
    if (type & WGLNetworkTrafficTypeWIFISent) {
        bytes += counter->en_out;
    }
    if (type & WGLNetworkTrafficTypeWIFIReceived) {
        bytes += counter->en_in;
    }
    if (type & WGLNetworkTrafficTypeAWDLSent) {
        bytes += counter->awdl_out;
    }
    if (type & WGLNetworkTrafficTypeAWDLReceived) {
        bytes += counter->awdl_in;
    }
    return bytes;
}

static wgl_net_interface_counter wgl_get_net_interface_counter() {
    static dispatch_semaphore_t lock;
    static NSMutableDictionary *sharedInCounters;
    static NSMutableDictionary *sharedOutCounters;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInCounters = [NSMutableDictionary new];
        sharedOutCounters = [NSMutableDictionary new];
        lock = dispatch_semaphore_create(1);
    });
    
    wgl_net_interface_counter counter = {0};
    struct ifaddrs *addrs;
    const struct ifaddrs *cursor;
    if (getifaddrs(&addrs) == 0) {
        cursor = addrs;
        dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
        while (cursor) {
            if (cursor->ifa_addr->sa_family == AF_LINK) {
                const struct if_data *data = cursor->ifa_data;
                NSString *name = cursor->ifa_name ? [NSString stringWithUTF8String:cursor->ifa_name] : nil;
                if (name) {
                    uint64_t counter_in = ((NSNumber *)sharedInCounters[name]).unsignedLongLongValue;
                    counter_in = wgl_net_counter_add(counter_in, data->ifi_ibytes);
                    sharedInCounters[name] = @(counter_in);
                    
                    uint64_t counter_out = ((NSNumber *)sharedOutCounters[name]).unsignedLongLongValue;
                    counter_out = wgl_net_counter_add(counter_out, data->ifi_obytes);
                    sharedOutCounters[name] = @(counter_out);
                    
                    if ([name hasPrefix:@"en"]) {
                        counter.en_in += counter_in;
                        counter.en_out += counter_out;
                    } else if ([name hasPrefix:@"awdl"]) {
                        counter.awdl_in += counter_in;
                        counter.awdl_out += counter_out;
                    } else if ([name hasPrefix:@"pdp_ip"]) {
                        counter.pdp_ip_in += counter_in;
                        counter.pdp_ip_out += counter_out;
                    }
                }
            }
            cursor = cursor->ifa_next;
        }
        dispatch_semaphore_signal(lock);
        freeifaddrs(addrs);
    }
    
    return counter;
}


@interface WGLNetworkTrafficManager ()
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, assign) BOOL isMonitoring;
@property (nonatomic, assign) uint64_t wwanTrafficForLastSecond, wifiTrafficForLastSecond, awdlTrafficForLastSecond, allTrafficForLastSecond;    //1秒之前的流量总字节数bytes
@property (nonatomic, assign) uint64_t wwanTrafficForCurrent, wifiTrafficForCurrent, awdlTrafficForCurrent, allTrafficForCurrent;    //此刻的流量总字节数bytes
@property (nonatomic, assign) uint64_t wwanTrafficBytesPerSecond, wifiTrafficBytesPerSecond, awdlTrafficBytesPerSecond, allTrafficBytesPerSecond;    //流量速度bytes per second
@end

@implementation WGLNetworkTrafficManager

+ (instancetype)sharedManager {
    static WGLNetworkTrafficManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[[self class] alloc] init];
    });
    return instance;
}

- (void)startMonitoring {
    self.isMonitoring = YES;
    [self reCaculateTraffic];
    [self addTimer];
}

- (void)stopMonitoring {
    self.isMonitoring = NO;
    [self removeTimer];
}

#pragma mark - 网速

- (uint64_t)wwanNetworkSpeed {
    return self.wwanTrafficBytesPerSecond / 1000;   //单位kb/s
}

- (uint64_t)wifiNetworkSpeed {
    return self.wifiTrafficBytesPerSecond / 1000;   //单位kb/s
}

- (uint64_t)awdlNetworkSpeed {
    return self.awdlTrafficBytesPerSecond / 1000;   //单位kb/s
}

- (uint64_t)allNetworkSpeed {
    return self.allTrafficBytesPerSecond / 1000;    //单位kb/s
}

#pragma mark - 流量数bytes

+ (uint64_t)getNetworkTrafficBytes:(WGLNetworkTrafficType)types {
    wgl_net_interface_counter counter = wgl_get_net_interface_counter();
    return wgl_net_counter_get_by_type(&counter, types);
}

#pragma mark - private

//重新计算流量字节数bytes
- (void)reCaculateTraffic {
    self.wwanTrafficForLastSecond
    = self.wwanTrafficForCurrent
    = [WGLNetworkTrafficManager getNetworkTrafficBytes:WGLNetworkTrafficTypeWWAN];
    
    self.wifiTrafficForLastSecond
    = self.wifiTrafficForCurrent
    = [WGLNetworkTrafficManager getNetworkTrafficBytes:WGLNetworkTrafficTypeWIFI];
    
    self.awdlTrafficForLastSecond
    = self.awdlTrafficForCurrent
    = [WGLNetworkTrafficManager getNetworkTrafficBytes:WGLNetworkTrafficTypeAWDL];
    
    self.allTrafficForLastSecond
    = self.allTrafficForCurrent
    = [WGLNetworkTrafficManager getNetworkTrafficBytes:WGLNetworkTrafficTypeALL];
    
    //流量速度 = 当前流量 - 上一秒流量
    self.wwanTrafficBytesPerSecond = 0;
    self.wifiTrafficBytesPerSecond = 0;
    self.awdlTrafficBytesPerSecond = 0;
    self.allTrafficBytesPerSecond = 0;
    
}

//1秒定时计算一次流量
- (void)caculateTrafficPerSecond {
    //当前流量
    self.wwanTrafficForCurrent
    = [WGLNetworkTrafficManager getNetworkTrafficBytes:WGLNetworkTrafficTypeWWAN];
    
    self.wifiTrafficForCurrent
    = [WGLNetworkTrafficManager getNetworkTrafficBytes:WGLNetworkTrafficTypeWIFI];
    
    self.awdlTrafficForCurrent
    = [WGLNetworkTrafficManager getNetworkTrafficBytes:WGLNetworkTrafficTypeAWDL];
    
    self.allTrafficForCurrent
    = [WGLNetworkTrafficManager getNetworkTrafficBytes:WGLNetworkTrafficTypeALL];
    
    //流量速度 = 当前流量 - 上一秒流量
    self.wwanTrafficBytesPerSecond
    = self.wwanTrafficForCurrent - self.wwanTrafficForLastSecond;
    
    self.wifiTrafficBytesPerSecond
    = self.wifiTrafficForCurrent - self.wifiTrafficForLastSecond;
    
    self.awdlTrafficBytesPerSecond
    = self.awdlTrafficForCurrent - self.awdlTrafficForLastSecond;
    
    self.allTrafficBytesPerSecond =
    self.allTrafficForCurrent - self.allTrafficForLastSecond;
    
}

#pragma mark - 定时器

//开启定时器
- (void)addTimer {
    if ([self.timer isValid]) {
        return;
    }
    [self removeTimer];
    
    self.timer =
    [NSTimer scheduledTimerWithTimeInterval:1
                                     target:self
                                   selector:@selector(caculateTrafficPerSecond)
                                   userInfo:nil
                                    repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
}

//停止定时器
- (void)removeTimer {
    if (self.timer == nil) {
        return;
    }
    if ([self.timer isValid]) {
        [self.timer invalidate];
    }
    self.timer = nil;
}

@end
