//
//  URIInfo.h
//  SimpleEncapsulate
//
//  Created by yhtian on 14-4-4.
//  Copyright (c) 2014年 SimpleEncapsulate. All rights reserved.
//

#import "AMCObject.h"
#import "SEMessageDefine.h"

/**
 *  请求的信息
 *  @see SENetwork
 */
@interface SEURIInfo : AMCObject<NSCoding, NSSecureCoding>

@property(nonatomic) SEMessageID msgId; //请求的消息ID
@property(nonatomic, strong) NSString *relativePath; //请求的相对路径
@property(nonatomic) NetworkFetchType methodType; //请求的类型
@property(nonatomic) NetworkEncodingType encodeType; //编码的类型
@property(nonatomic, strong) NSString *responseModelClass; //返回数据的类名
@property(nonatomic) NetworkResponseType responseType; //返回的类型
@property(nonatomic) BOOL responseZipped; //返回的数据是否压缩过
@property(nonatomic) BOOL ignoreCommonParams; //请求是否忽略统一的参数，默认为NO
@property(nonatomic, strong) NSString *comment; //说明

+ (void)loadInfoFromFile:(NSString *)filePath;

+ (instancetype)infoWithMessageId:(NSInteger)msgId;

@end
