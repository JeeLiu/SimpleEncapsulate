//
//  NSObject+DataHandling.h
//  SimpleEncapsulate
//
//  Created by yhtian on 14-4-2.
//  Copyright (c) 2014年 SimpleEncapsulate. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SENetwork.h"

@protocol SEDataCallBack <NSObject>

@optional

- (void)handleData:(id)data withMsgId:(NSInteger)msgId;
- (void)handleError:(NSError *)error withMsgId:(NSInteger)msgId;

/**
 *  请求返回时的回调函数
 *
 *  @param data    返回的数据
 *  @param msgId   请求时的消息ID
 *  @param context 请求时所带的参数
 */
- (void)handleData:(id)data withMsgId:(NSInteger)msgId context:(id)context;
- (void)handleError:(NSError *)error withMsgId:(NSInteger)msgId context:(id)context;

@end

@interface NSObject (DataHandling)<SEDataCallBack>

#pragma mark - network request
// Start network fetch
/**
 *  请求网络数据
 *
 *  @param msgId      消息ID
 *  @param params     参数
 *  @param usingCache 存在该ID的缓存时是否返回缓存的数据
 *  @param forceReload如果该请求对应的ID已经存在时是否取消并重新发起该请求
 */
- (void)fetchWithMsgId:(NSInteger)msgId params:(id)params;
- (void)fetchWithMsgId:(NSInteger)msgId params:(id)params usingCache:(BOOL)usingCache;
- (void)fetchWithMsgId:(NSInteger)msgId params:(id)params forceReload:(BOOL)forceReload;
- (void)fetchWithMsgId:(NSInteger)msgId
                params:(id)params
            usingCache:(BOOL)usingCache
           forceReload:(BOOL)reload;
// networking
- (void)fetchingDidStartWithMsgId:(NSInteger)msgId;
- (void)fetchingDidEndWithMsgId:(NSInteger)msgId;

@end
