//
//  NSObject+DataHandling.m
//  SimpleEncapsulate
//
//  Created by yhtian on 14-4-2.
//  Copyright (c) 2014年 SimpleEncapsulate. All rights reserved.
//

#import "NSObject+DataHandling.h"
#import "SEMessageDefine.h"
#import "SEDatabase.h"
#import "SEDataCache.h"
#import "SEURIInfo.h"

@implementation NSObject (DataHandling)

- (void)handleData:(id)data withMsgId:(NSInteger)msgId context:(id)context
{
    if ([self respondsToSelector:@selector(handleData:withMsgId:)]) {
        [self handleData:data withMsgId:msgId];
    }
}

- (void)handleError:(NSError *)error withMsgId:(NSInteger)msgId context:(id)context
{
    if ([self respondsToSelector:@selector(handleError:withMsgId:)]) {
        [self handleError:error withMsgId:msgId];
    }
}

- (void)handleCommonError:(NSError *)error withMsgId:(NSInteger)msgId context:(id)context
{
    if ([error code] == kResponseCodeInternal) {
    } else if ([error code] == kResponseCodeTimeout) {
    } else {
        [self handleError:error withMsgId:msgId context:context];
    }
}

- (void)fetchWithMsgId:(NSInteger)msgId params:(id)params
{
    [self fetchWithMsgId:msgId params:params usingCache:NO forceReload:NO];
}

- (void)fetchWithMsgId:(NSInteger)msgId params:(id)params forceReload:(BOOL)forceReload
{
    [self fetchWithMsgId:msgId params:params usingCache:NO forceReload:forceReload];
}

- (void)fetchWithMsgId:(NSInteger)msgId params:(id)params usingCache:(BOOL)usingCache
{
    [self fetchWithMsgId:msgId params:params usingCache:usingCache forceReload:NO];
}

- (void)fetchWithMsgId:(NSInteger)msgId
                params:(id)params
            usingCache:(BOOL)usingCache
           forceReload:(BOOL)reload;
{
    __weak typeof(&*self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (usingCache) {
            [[SENetwork sharedNetwork] fetchCacheDataWithMsgId:msgId
                                           completionHandler:^(id data, NSError *error) {
                                               [weakSelf handleData:data withMsgId:msgId context:params];
                                           }];
        }
        [self fetchingDidStartWithMsgId:msgId];
        [[SENetwork sharedNetwork] fetchWithMsgId:msgId
                                         params:params
                                    forceReload:reload
                              completionHandler:^(id data, NSError *error) {
                                  if (data) {
                                      // Maybe server return error.
                                      [weakSelf handleData:data withMsgId:msgId context:params];
                                  } else if (error) {
                                      [weakSelf handleCommonError:error withMsgId:msgId context:params];
                                  }
                                  [weakSelf fetchingDidEndWithMsgId:msgId];
                              }];
    });
}

- (void)fetchingDidStartWithMsgId:(NSInteger)msgId
{
}

- (void)fetchingDidEndWithMsgId:(NSInteger)msgId
{
}

@end
