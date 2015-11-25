//
//  RCThreadMonitor.m
//  RCThreadMonitor
//
//  Created by Robin.Chao on 11/25/15.
//  Copyright © 2015 Robin.Chao. All rights reserved.
//

#import "RCThreadMonitor.h"
#import <CrashReporter/CrashReporter.h>


@interface RCThreadMonitor() {
    int timeoutCount;
    CFRunLoopObserverRef observer;
    
    @public
    dispatch_semaphore_t semaphore;
    CFRunLoopActivity activity;
}

@end

@implementation RCThreadMonitor

+ (instancetype)monitor{
    static id instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

static void runloopObserverCallBack(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info) {
    RCThreadMonitor *monitor = (__bridge RCThreadMonitor *)info;
    monitor -> activity = activity;
    
    dispatch_semaphore_t semaphore = monitor -> semaphore;
    dispatch_semaphore_signal(semaphore);
}

- (void)stopMonitor{
    if (!observer) {
        return;
    }
    
    CFRunLoopRemoveObserver(CFRunLoopGetMain(), observer, kCFRunLoopCommonModes);
    CFRelease(observer);
    observer = NULL;
}

- (void)startMonitor{
    if (observer) {
        return;
    }
    
    semaphore = dispatch_semaphore_create(0);
    
    CFRunLoopObserverContext context = {0, (__bridge void *)self, NULL, NULL};
    observer = CFRunLoopObserverCreate(kCFAllocatorDefault,
                                       kCFRunLoopAllActivities,
                                       YES,
                                       0,
                                       &runloopObserverCallBack,
                                       &context);
    
    CFRunLoopAddObserver(CFRunLoopGetMain(), observer, kCFRunLoopCommonModes);
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        while (YES) {
            long st = dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, 50 * NSEC_PER_MSEC));
            if (st != 0) {
                if (!observer) {
                    timeoutCount = 0;
                    semaphore = 0;
                    activity = 0;
                    return;
                }
                
                if (activity == kCFRunLoopBeforeSources || activity == kCFRunLoopAfterWaiting) {
                    if (++timeoutCount < 5) {
                        continue;
                    }
                    
                    PLCrashReporterConfig *config = [[PLCrashReporterConfig alloc] initWithSignalHandlerType:PLCrashReporterSignalHandlerTypeBSD symbolicationStrategy:PLCrashReporterSymbolicationStrategyAll];
                    PLCrashReporter *crashReporter = [[PLCrashReporter alloc] initWithConfiguration:config];
                    
                    NSData *data = [crashReporter generateLiveReport];
                    PLCrashReport *report = [[PLCrashReport alloc] initWithData:data error:NULL];
                    NSString *reportString = [PLCrashReportTextFormatter stringValueForCrashReport:report withTextFormat:PLCrashReportTextFormatiOS];
                    NSLog(@"=====================\n%@\n==================",reportString);
                }
            }
            timeoutCount = 0;
        }
    });
}


@end
