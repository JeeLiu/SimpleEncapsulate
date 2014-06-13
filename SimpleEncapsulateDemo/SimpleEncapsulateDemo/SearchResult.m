//
//  SearchResult.m
//  SimpleEncapsulateDemo
//
//  Created by yhtian on 14-6-13.
//  Copyright (c) 2014年 yhtian. All rights reserved.
//

#import "SearchResult.h"

@implementation Book

@end

@implementation SearchResult

- (NSString *)classNameWithPropertyName:(NSString *)propertyName
{
    if ([propertyName isEqualToString:@"books"]) {
        return [Book className];
    }
    return nil;
}

@end
