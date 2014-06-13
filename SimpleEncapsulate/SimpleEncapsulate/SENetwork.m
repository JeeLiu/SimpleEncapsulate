//
//  Network.m
//  SimpleEncapsulate
//
//  Created by yhtian on 13-7-23.
//  Copyright (c) 2013年 SimpleEncapsulate. All rights reserved.
//

#import "SENetwork.h"
#import <objc/runtime.h>
#import <AFNetworking/AFNetworking.h>
#import <AFNetworking/UIKit+AFNetworking.h>
#import "AMCObject.h"
#import "NSData+Compress.h"
#import "SEMessageDefine.h"
#import "SEURIInfo.h"
#import "SEUtilities.h"
#import "SEDataCache.h"

@interface NSObject (ProtocolBuffer)

- (id)parseFromData:(NSData *)data;

@end

static dispatch_queue_t _networkOperationQueue;

typedef void (^SuccessBlock)(AFHTTPRequestOperation *operation, id responseObject);
typedef void (^FailureBlock)(AFHTTPRequestOperation *operation, NSError *error);
typedef void (^FormDataBlock)(id <AFMultipartFormData>);

static NSString *const kSENetworkOperationMsgIdKey = @"msgId";

@interface SENetworkOperationManager : AFHTTPRequestOperationManager

+ (AFURLConnectionOperation *)operationWithMsgId:(NSInteger)msgId;

@end

@implementation SENetworkOperationManager

+ (AFURLConnectionOperation *)operationWithMsgId:(NSInteger)msgId
{
    NSArray *operations = [[SENetwork sharedNetwork].networkManager.operationQueue operations];
    if ([operations count]) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.userInfo.msgId == %@", @(msgId)];
        NSArray *array = [operations filteredArrayUsingPredicate:predicate];
        return [array lastObject];
    }
    return nil;
}

@end

@implementation SENetwork {
    @private
    NSDictionary *_commonHeader;
    id _commonBody;
    SENetworkOperationManager *_networkManager;
    NSMutableDictionary *_URIInfos;
    NSArray *_requestSerializer;
}

+ (instancetype)sharedNetwork
{
    static SENetwork *z_network;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        z_network = [[self alloc] init];
    });
    return z_network;
}

+ (void)initialize
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _networkOperationQueue = dispatch_queue_create("SimpleEncapsulate.network", NULL);
        dispatch_async(_networkOperationQueue, ^{
            NSURLCache *urlCache = [[NSURLCache alloc] initWithMemoryCapacity:4 * 1024 * 1024
                                                                 diskCapacity:20 * 1024 * 1024
                                                                     diskPath:nil];
            [NSURLCache setSharedURLCache:urlCache];
            [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];
        });
    });
}

- (id)dictionaryRepresentationWithParams:(id)params
{
    id representParam;
    if ([params isKindOfClass:[NSDictionary class]]) {
        representParam = params;
    } else if ([params isKindOfClass:[NSArray class]]) {
        representParam = [NSMutableArray array];
        for (id obj in params) {
            [representParam addObject:[obj dictionaryRepresentation]];
        }
    } else if ([params isKindOfClass:[AMCObject class]]) {
        representParam = [params dictionaryRepresentation];
    } else {
        representParam = params;
    }
    return representParam;
}

+ (SEL)methodWithType:(NetworkFetchType)type
{
    static NSString *methods[] = {
        @"GET:parameters:success:failure:",
        @"POST:parameters:success:failure:",
        @"POST:parameters:constructingBodyWithBlock:success:failure:",
        @"PUT:parameters:success:failure:",
        @"DELETE:parameters:success:failure:",
        @"PATCH:parameters:success:failure:"
    };
    NSString *method = methods[type];
    return NSSelectorFromString(method);
}

- (id)init
{
    self = [super init];
    if (self) {
        _URIInfos = [[NSMutableDictionary alloc] init];
        _requestSerializer = @[[AFHTTPRequestSerializer serializer],
                               [AFJSONRequestSerializer serializer],
                               [AFPropertyListRequestSerializer serializer]];
    }
    return self;
}

- (void)dealloc
{
    [self.networkManager.reachabilityManager stopMonitoring];
}

- (void)prepareCommonHeader:(NSDictionary *)header
{
    _commonHeader = header;
    for (NSString *key in _commonHeader) {
        [self.networkManager.requestSerializer setValue:_commonHeader[key]
                                     forHTTPHeaderField:key];
    }
}

- (void)prepareCommonBody:(id)body
{
    _commonBody = body;
}

- (void)registerURIInfo:(SEURIInfo *)info forMsgId:(NSInteger)msgId
{
    if (info) {
        [_URIInfos setObject:info forKey:@(msgId)];
    }
}

- (void)unregisterURIInfoForMsgId:(NSInteger)msgId
{
    [_URIInfos removeObjectForKey:@(msgId)];
}

- (SEURIInfo *)URIInfoWithMsgId:(NSInteger)msgId
{
    SEURIInfo *uriInfo = [_URIInfos objectForKey:@(msgId)];
    if (!uriInfo) {
        uriInfo = [SEURIInfo infoWithMessageId:MAINMSG(msgId)];
    }
    if (!uriInfo) {
        NSLog(@"Unknown url path with msgId:%@", @(msgId));
    }
    return uriInfo;
}

- (id)paramsByAddParam:(id)param
{
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    if ([_commonBody isKindOfClass:[NSDictionary class]]) {
        [dic addEntriesFromDictionary:_commonBody];
    } else if ([_commonBody isKindOfClass:[AMCObject class]]) {
        [dic addEntriesFromDictionary:[_commonBody dictionaryRepresentation]];
    } else {
        //TODO:Support other kinds.
    }
    id obj = [self dictionaryRepresentationWithParams:param];
    if ([obj isKindOfClass:[NSDictionary class]]) {
        [dic addEntriesFromDictionary:obj];
    } else if (param) {
        dic = param;
    }
    return dic;
}

- (id)dataDidReturn:(id)data
              msgId:(NSInteger)msgId
       regClassName:(NSString *)className
            handler:(void (^)(id, NSError *))handler
{
    @autoreleasepool {
        id obj = nil;
        if (handler) {
            NSError *error = nil;
            if ([data isKindOfClass:[NSError class]]) {
                error = data;
                handler(nil, error);
            } else {
                Class cls = NSClassFromString(className);
                @try {
                    SEURIInfo *info = [self URIInfoWithMsgId:msgId];
                    switch (info.responseType) {
                        case kResponseTypeJSON:
                            data = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
                            if (cls) {
                                obj = [cls objectWithRepresentation:data];
                            }
                            break;
                        case kResponseTypePropertyList:
                            data = [NSPropertyListSerialization propertyListWithData:data options:0 format:NULL error:&error];
                            if (cls) {
                                obj = [cls objectWithRepresentation:data];
                            }
                            break;
                        case kResponseTypeProtoBuffer:
                            if (cls) {
                                obj = [cls parseFromData:data];
                            }
                            break;
                        case kResponseTypeUnknown:
                        default:
                            break;
                    }
                    [[SEDataCache sharedCache] saveObject:data toFileWithKey:[@(msgId) stringValue]];
                }
                @catch (NSException *exception) {
                    LOG(@"%@", [exception reason]);
                    error = [NSError errorWithDomain:kSEDomainName
                                                code:-1
                                            userInfo:@{NSLocalizedDescriptionKey:@"Parse data failed."}];
                }
                @finally {
                    if (error) {
                        obj = nil;
                    }
                    handler(obj, error);
                }
            }
        }
        return obj;
    }
}

- (void)fetchCacheDataWithMsgId:(NSInteger)msgId
              completionHandler:(void (^)(id data, NSError *error))handler
{
    SEURIInfo *uriInfo = [self URIInfoWithMsgId:msgId];
    if (!uriInfo) {
        return;
    }
    id cacheData = [[SEDataCache sharedCache] objectFromFileWithKey:[@(msgId) stringValue]];
    cacheData = [self dataDidReturn:cacheData msgId:msgId regClassName:uriInfo.responseModelClass handler:nil];
    if (handler && cacheData) {
        handler(cacheData, nil);
    }
}

- (void)fetchWithMsgId:(NSInteger)msgId
              params:(id)params
   completionHandler:(void (^)(id data, NSError *error))handler
{
    [self fetchWithMsgId:msgId params:params forceReload:NO completionHandler:handler];
}

- (void)fetchWithMsgId:(NSInteger)msgId
              params:(id)params
         forceReload:(BOOL)reload
   completionHandler:(void (^)(id data, NSError *error))handler
{
    SEURIInfo *uriInfo = [self URIInfoWithMsgId:msgId];
    if (!uriInfo) {
        return;
    }
    dispatch_async(_networkOperationQueue, ^{
        @autoreleasepool {
            if (![self.networkManager.reachabilityManager isReachable] &&
                self.networkManager.reachabilityManager.networkReachabilityStatus != AFNetworkReachabilityStatusUnknown) {
                NSError *error = [NSError errorWithDomain:kSEDomainName
                                                     code:kResponseCodeNoInternet
                                                 userInfo:@{NSLocalizedDescriptionKey: @"No network"}];
                [self dataDidReturn:error msgId:msgId regClassName:nil handler:handler];
                return;
            }
            AFURLConnectionOperation *op = [SENetworkOperationManager operationWithMsgId:msgId];
            if (op) {
                if (reload) {
                    [op cancel];
                } else {
                    return;
                }
            }
            
            NetworkEncodingType type = uriInfo.encodeType;
            self.networkManager.requestSerializer = _requestSerializer[type];
            SEL selector = [[self class] methodWithType:uriInfo.methodType];
            NSMethodSignature *signature = [[self.networkManager class] instanceMethodSignatureForSelector:selector];
            NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
            [invocation setSelector:selector];
            NSString *relativePath = uriInfo.relativePath;
            int index = 2;
            [invocation setArgument:&relativePath atIndex:index];
            ++index;
            NSDictionary *param;
            if (uriInfo.ignoreCommonParams) {
                param = [self dictionaryRepresentationWithParams:params];
            } else {
                param = [self paramsByAddParam:params];
            }
            [invocation setArgument:&param atIndex:index];
            ++index;
            if (uriInfo.methodType == kFetchTypePostForm) {
                FormDataBlock block = nil;
                [invocation setArgument:&block atIndex:index];
                ++index;
            }
            SuccessBlock successBlock = ^(AFHTTPRequestOperation *operation, id responseObject) {
                LOG(@"Succeed with msgId:(%d, %d), %@",
                    (int)(MAINMSG(msgId)), (int)(SUBMSG(msgId)), uriInfo.comment ? uriInfo.comment : @"");
                LOG(@"url = %@", operation.response.URL);
                id data = operation.responseData;
                if (uriInfo.responseZipped) {
                    data = [data uncompressZippedData];
                }
                [self dataDidReturn:data msgId:msgId regClassName:uriInfo.responseModelClass handler:handler];
            };
            [invocation setArgument:&successBlock atIndex:index];
            ++index;
            FailureBlock failureBlock = ^(AFHTTPRequestOperation *operation, NSError *error) {
                LOG(@"url = %@", operation.response.URL);
                if ([operation isCancelled]) {
                    LOG(@"Cancelled with msgId:(%d, %d), %@",
                        (int)(MAINMSG(msgId)), (int)(SUBMSG(msgId)), uriInfo.comment ? uriInfo.comment : @"");
                    return;
                }
                LOG(@"Failed with msgId:(%d, %d), %@",
                    (int)(MAINMSG(msgId)), (int)(SUBMSG(msgId)), uriInfo.comment ? uriInfo.comment : @"");
                if (handler) {
                    handler(nil, error);
                }
            };
            LOG(@"Started with msgId:(%d, %d, %@), %@",
                (int)(MAINMSG(msgId)), (int)(SUBMSG(msgId)), param, uriInfo.comment ? uriInfo.comment : @"");
            [invocation setArgument:&failureBlock atIndex:index];
            [invocation invokeWithTarget:self.networkManager];
            __unsafe_unretained AFHTTPRequestOperation *operation;
            [invocation getReturnValue:&operation];
            operation.userInfo = @{kSENetworkOperationMsgIdKey: @(msgId)};
        }
    });
}

- (void)cancelFetchWithMsgId:(NSInteger)msgId
{
    dispatch_async(_networkOperationQueue, ^{
        NSArray *operations = [self.networkManager.operationQueue operations];
        for (AFHTTPRequestOperation *operation in operations) {
            if ([operation.userInfo[kSENetworkOperationMsgIdKey] integerValue] == msgId) {
                [operation cancel];
            }
        }
    });
}

- (void)setReachableStatusChangeBlock:(void (^)(NetworkReachableStatus))block
{
    if (block) {
        [self.networkManager.reachabilityManager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
            block((NetworkReachableStatus)status);
        }];
    }
}

- (void)setBaseURLPath:(NSString *)baseURLPath
{
    if (!baseURLPath || [self.baseURLPath isEqualToString:baseURLPath]) {
        return;
    }
    _baseURLPath = baseURLPath;
    _networkManager = nil;
}

- (AFHTTPRequestOperationManager *)networkManager
{
    if (!_networkManager) {
        @synchronized(self) {
            _networkManager = [[SENetworkOperationManager alloc] initWithBaseURL:
                               [NSURL URLWithString:self.baseURLPath]];
            [_networkManager.reachabilityManager startMonitoring];
            _networkManager.responseSerializer = [AFHTTPResponseSerializer serializer];
//            NSSet *set = [_networkManager.responseSerializer.acceptableContentTypes setByAddingObject:@"application/x-gzip"];
//            _networkManager.responseSerializer.acceptableContentTypes = set;
        }
    }
    return _networkManager;
}

- (void)saveCookies
{
    NSData *cookiesData = [NSKeyedArchiver archivedDataWithRootObject:
                           [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies]];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:cookiesData forKey:@"sessionCookies"];
    [defaults synchronize];
}

- (void)loadCookies
{
    NSArray *cookies = [NSKeyedUnarchiver unarchiveObjectWithData:
                        [[NSUserDefaults standardUserDefaults]
                         objectForKey: @"sessionCookies"]];
    NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    for (NSHTTPCookie *cookie in cookies){
        [cookieStorage setCookie:cookie];
    }
}

@end

@implementation UIActivityIndicatorView (Networking)

- (void)setAnimatingWithStateOfMsgId:(NSInteger)msgId
{
    dispatch_async(_networkOperationQueue, ^{
        AFURLConnectionOperation *operation = [SENetworkOperationManager operationWithMsgId:msgId];
        [self setAnimatingWithStateOfOperation:operation];
    });
}

@end
