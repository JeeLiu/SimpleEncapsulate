//
//  SearchResult.h
//  SimpleEncapsulateDemo
//
//  Created by yhtian on 14-6-13.
//  Copyright (c) 2014年 yhtian. All rights reserved.
//

#import <SimpleEncapsulate/SimpleEncapsulate.h>

@interface Book : AMCObject

@property(nonatomic, strong) NSString *id;
@property(nonatomic, strong) NSString *title;

@end

@interface SearchResult : AMCObject

@property(nonatomic) NSInteger count;
@property(nonatomic) NSInteger start;
@property(nonatomic) NSInteger total;
@property(nonatomic, strong) NSArray *books;

@end
