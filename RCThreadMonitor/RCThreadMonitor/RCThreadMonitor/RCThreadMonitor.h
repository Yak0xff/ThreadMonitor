//
//  RCThreadMonitor.h
//  RCThreadMonitor
//
//  Created by Robin.Chao on 11/25/15.
//  Copyright © 2015 Robin.Chao. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RCThreadMonitor : NSObject

+ (instancetype)monitor;

- (void)startMonitor;
- (void)stopMonitor;

@end
