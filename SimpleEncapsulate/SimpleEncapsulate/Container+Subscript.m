//
//  Container+Subscript.m
//  SimpleEncapsulate
//
//  Created by yhtian on 14-5-27.
//  Copyright (c) 2014年 SimpleEncapsulate. All rights reserved.
//

#import "Container+Subscript.h"

@implementation NSArray (Subscript)

- (id)objectAtIndexedSubscript:(NSUInteger)idx
{
    if (idx >= [self count]) {
        return nil;
    }
    return [self objectAtIndex:idx];
}

@end

@implementation NSMutableArray (Subscript)

- (void)setObject:(id)obj atIndexedSubscript:(NSUInteger)idx
{
    const NSUInteger length = [self count];
    if (idx > length) {
        return;
    }
    if (idx == length) {
        [self addObject:obj];
    } else {
        [self replaceObjectAtIndex:idx withObject:obj];
    }
}

@end

@implementation NSDictionary (Subscript)

- (id)objectForKeyedSubscript:(id<NSCopying>)key
{
    return [self objectForKey:key];
}

@end

@implementation NSMutableDictionary (Subscript)

- (void)setObject:(id)object forKeyedSubscript:(id<NSCopying>)aKey
{
    [self setObject:object forKey:aKey];
}

@end
