//
//  BookInfo.m
//  SimpleEncapsulateDemo
//
//  Created by yhtian on 14-6-12.
//  Copyright (c) 2014年 yhtian. All rights reserved.
//

#import "BookInfo.h"

@implementation Rating

@end

@implementation Tags

@end

@implementation Images

@end

@implementation BookInfo

- (NSString *)classNameWithPropertyName:(NSString *)propertyName
{
    if ([propertyName isEqualToString:@"tags"]) {
        return [Tags className];
    }
    return nil;
}

@end
