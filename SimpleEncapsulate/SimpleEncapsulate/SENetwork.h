//
//  Network.h
//  SimpleEncapsulate
//
//  Created by yhtian on 13-7-23.
//  Copyright (c) 2013年 SimpleEncapsulate. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SEMessageDefine.h"

@class SEURIInfo;
@class AFHTTPRequestOperationManager;

@import UIKit;

@interface SENetwork : NSObject

@property(nonatomic, copy) NSString *baseURLPath;
@property(nonatomic, readonly, strong) AFHTTPRequestOperationManager *networkManager;

+ (instancetype)sharedNetwork;

/**
 *  @abstract 为每个请求都配置一样的请求头参数
 *
 *  @param header 共同的请求头
 */
- (void)prepareCommonHeader:(NSDictionary *)header;

/**
 *  @abstract 为每个请求都配置一样的Body参数
 *
 *  @param body body参数
 */
- (void)prepareCommonBody:(id)body;

/**
 *  不使用配置文件时可以为请求设置对应的信息
 *
 *  @param info  URL信息
 *  @param msgId 请求消息ID
 */
- (void)registerURIInfo:(SEURIInfo *)info forMsgId:(NSInteger)msgId;

/**
 *  取消设置对应的请求信息
 *
 *  @param msgId 请求的消息ID
 */
- (void)unregisterURIInfoForMsgId:(NSInteger)msgId;

/**
 *  加载缓存数据
 *
 *  @param msgId   请求的消息ID
 *  @param handler 返回请求的处理
 */
- (void)fetchCacheDataWithMsgId:(NSInteger)msgId
              completionHandler:(void (^)(id data, NSError *error))handler;

/**
 * @abstract      请求网络数据。
 * @param handler 数据返回时处理的回调函数，若出错则|error|不为nil，否则|data|为返回的数据。
 * @return data   若存在缓存数据，则返回缓存的数据，否则返回nil。
 * @discussion    当网络连接出现问题时，若存在缓存数据，则返回缓存的数据。
 */
- (void)fetchWithMsgId:(NSInteger)msgId
                params:(id)params
     completionHandler:(void (^)(id data, NSError *error))handler;

- (void)fetchWithMsgId:(NSInteger)msgId
                params:(id)params
           forceReload:(BOOL)reload //若请求已存在，是否强制重新请求，默认为NO
     completionHandler:(void (^)(id data, NSError *error))handler;

/**
 * @abstract    检测网络状态
 */
- (void)setReachableStatusChangeBlock:(void (^)(NetworkReachableStatus))block;

/**
 * @abstract    取消网络请求
 */
- (void)cancelFetchWithMsgId:(NSInteger)msgId;

@end

@interface UIActivityIndicatorView (Networking)

- (void)setAnimatingWithStateOfMsgId:(NSInteger)msgId;

@end
