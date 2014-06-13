//
//  NSNull+InternalNullExtension.m
//  SimpleEncapsulate
//
//  Created by yhtian on 14-4-25.
//  Copyright (c) 2014年 SimpleEncapsulate. All rights reserved.
//

#import "NSNull+InternalNullExtension.h"

#define NSNullObjects   @[@0, @"", @{}, @[]]

@implementation NSNull (InternalNullExtension)

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
    NSMethodSignature *signature = [super methodSignatureForSelector:aSelector];
    if (!signature) {
        for (NSObject *obj in NSNullObjects) {
            signature = [obj methodSignatureForSelector:aSelector];
            if (signature) {
                break;
            }
        }
    }
    return signature;
}

- (void)forwardInvocation:(NSInvocation *)anInvocation
{
    SEL selector = [anInvocation selector];
    for (NSObject *obj in NSNullObjects) {
        if ([obj respondsToSelector:selector]) {
            [anInvocation invokeWithTarget:obj];
            return;
        }
    }
    [self doesNotRecognizeSelector:selector];
}

@end
