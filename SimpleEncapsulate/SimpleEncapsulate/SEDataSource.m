//
//  DataSource.m
//  SimpleEncapsulate
//
//  Created by yhtian on 14-4-2.
//  Copyright (c) 2014年 SimpleEncapsulate. All rights reserved.
//

#import "SEDataSource.h"

//#include <objc/runtime.h>
//#include <objc/message.h>

#import "SEMessageDefine.h"
#import "SEUtilities.h"
#import "NSNull+InternalNullExtension.h"
#import "NSObject+DataHandling.h"

@implementation SEDataSource
@synthesize data = _data, msgId = _msgId, state = _state;

- (id)init
{
    self = [super init];
    if (self) {
        [self addObserver:self
               forKeyPath:@"data"
                  options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
                  context:NULL];
        self.state = kSEDataStateUnInitial;
    }
    return self;
}

- (void)dealloc
{
    [self removeObserver:self forKeyPath:@"data"];
    if (self.msgId != kMessageIDUnknown) {
        [[SENetwork sharedNetwork] cancelFetchWithMsgId:self.msgId];
        LOG(@"deallocing with msgId(%d, %d).", (int)MAINMSG(self.msgId), (int)SUBMSG(self.msgId));
    }
}

- (void)fetchData
{
    self.state = kSEDataStateFetching;
}

- (void)handleData:(id)data withMsgId:(NSInteger)msgId
{
    self.state = kSEDataStateReceiveSucceed;
    self.data = [self parseData:data];
}

- (void)handleError:(NSError *)error withMsgId:(NSInteger)msgId
{
    self.state = kSEDataStateReceiveFailed;
    if ([self.controller respondsToSelector:@selector(handleError:withMsgId:)]) {
        [self.controller handleError:error withMsgId:msgId];
    }
}

- (id)parseData:(id)data
{
    return data;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == self && [keyPath isEqualToString:@"data"]) {
        @autoreleasepool {
            id data = [change objectForKey:NSKeyValueChangeNewKey];
            id rawData = [change objectForKey:NSKeyValueChangeOldKey];
            if ([data isEqual:[NSNull null]]) {
                data = nil;
            }
            if ([rawData isEqual:[NSNull null]]) {
                rawData = nil;
            }
            if (data == nil && rawData == nil) {
                return;
            }
            if (![data isEqual:rawData]) {
#if DEBUG
                id dData;
//                if ([data isKindOfClass:[PBGeneratedMessage class]]) {
//                    dData = [self serializeWithProtocolBuffer:data];
//                } else {
                    dData = data;
//                }
                LOG(@"data = %@", dData);
#endif
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self removeObserver:self forKeyPath:@"data"];
                    if (self.controller) {
                        [self.controller handleData:data withMsgId:self.msgId];
                    }
                    [self addObserver:self
                           forKeyPath:@"data"
                              options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
                              context:NULL];
                });
            }
        }
    }
}

// Protocol buffers

//static NSString *propertyNameWithKey(NSString *key)
//{
//    NSMutableString *properName;
//    if ([key hasPrefix:@"mutable"]) {
//        properName = [key substringFromIndex:[@"mutable" length]].mutableCopy;
//    } else {
//        properName = key.mutableCopy;
//    }
//    char c = [properName characterAtIndex:0];
//    c = c - 'A' + 'a'; // lowercase
//    [properName replaceCharactersInRange:NSMakeRange(0, 1) withString:[NSString stringWithFormat:@"%c", c]];
//    return properName;
//}
//
//- (NSDictionary *)serializeWithProtocolBuffer:(PBGeneratedMessage *)pb
//{
//    if (!pb) {
//        return nil;
//    }
//    NSParameterAssert([pb isKindOfClass:[PBGeneratedMessage class]]);
//    NSMutableDictionary *dic = @{}.mutableCopy;
//    unsigned int numProps = 0;
//    objc_property_t *properties = class_copyPropertyList([pb class], &numProps);
//    for (int i = 0; i < numProps; i++) {
//        objc_property_t property = properties[i];
//        const char *name = property_getName(property);
//        NSString *key = [NSString stringWithUTF8String:name];
//        id value = [pb valueForKey:key];
//        if ([value isKindOfClass:[NSArray class]]) {
//            NSMutableArray *mutableArray = [NSMutableArray array];
//            for (PBGeneratedMessage *msg in value) {
//                NSDictionary *d = [self serializeWithProtocolBuffer:msg];
//                [mutableArray addObject:d];
//            }
//            [dic setObject:mutableArray forKey:propertyNameWithKey(key)];
//        } else if ([value isKindOfClass:[NSDictionary class]]) {
//            NSMutableDictionary *mutableDic = [NSMutableDictionary dictionary];
//            for (id key in value) {
//                NSDictionary *d = [self serializeWithProtocolBuffer:value[key]];
//                [mutableDic setObject:d forKey:key];
//            }
//            [dic setObject:mutableDic forKey:propertyNameWithKey(key)];
//        } else if ([value isKindOfClass:[PBGeneratedMessage class]]) {
//            NSDictionary *d = [self serializeWithProtocolBuffer:value];
//            [dic setObject:d forKey:key];
//        } else {
//            if (value) {
//                [dic setObject:value forKey:key];
//            }
//        }
//    }
//    free(properties);
//    return dic;
//}

@end
