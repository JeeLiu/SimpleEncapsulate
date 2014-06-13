//
//  URIInfo.m
//  SimpleEncapsulate
//
//  Created by yhtian on 14-4-4.
//  Copyright (c) 2014年 SimpleEncapsulate. All rights reserved.
//

#import "SEURIInfo.h"

@implementation SEURIInfo

static NSMutableDictionary *z_URIInfoMap = nil;

+ (void)loadInfoFromFile:(NSString *)filePath
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        z_URIInfoMap = [NSMutableDictionary dictionary];
        NSDictionary *dic = [NSDictionary dictionaryWithContentsOfFile:filePath];
        for (id key in dic) {
            NSDictionary *obj = [dic objectForKey:key];
            SEURIInfo *info = [SEURIInfo objectWithDictionaryRepresentation:obj];
            info.msgId = [key intValue];
            [z_URIInfoMap setObject:info forKey:key];
        }
    });
}

+ (instancetype)infoWithMessageId:(NSInteger)msgId
{
    return z_URIInfoMap[[@(msgId) stringValue]];
}

+ (BOOL)supportsSecureCoding
{
    return YES;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeInteger:self.msgId forKey:@"msgId"];
    [aCoder encodeObject:self.relativePath forKey:@"relativePath"];
    [aCoder encodeInteger:self.methodType forKey:@"methodType"];
    [aCoder encodeInteger:self.encodeType forKey:@"encodeType"];
    [aCoder encodeObject:self.responseModelClass forKey:@"responseModelClass"];
    [aCoder encodeInteger:self.responseType forKey:@"responseType"];
    [aCoder encodeBool:self.responseZipped forKey:@"responseZipped"];
    [aCoder encodeBool:self.ignoreCommonParams forKey:@"ignoreCommonParams"];
    [aCoder encodeObject:self.comment forKey:@"comment"];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self) {
        self.msgId = [aDecoder decodeIntegerForKey:@"msgId"];
        self.relativePath = [aDecoder decodeObjectForKey:@"relativePath"];
        self.methodType = [aDecoder decodeIntegerForKey:@"methodType"];
        self.encodeType = [aDecoder decodeIntegerForKey:@"encodeType"];
        self.responseModelClass = [aDecoder decodeObjectForKey:@"responseModelClass"];
        self.responseType = [aDecoder decodeIntegerForKey:@"responseType"];
        self.responseZipped = [aDecoder decodeBoolForKey:@"responseZipped"];
        self.ignoreCommonParams = [aDecoder decodeBoolForKey:@"ignoreCommonParams"];
        self.comment = [aDecoder decodeObjectForKey:@"comment"];
    }
    return self;
}

@end
