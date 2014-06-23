//
//  DataSource.h
//  SimpleEncapsulate
//
//  Created by yhtian on 14-4-2.
//  Copyright (c) 2014年 SimpleEncapsulate. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol SEDataIdentifier <NSObject>

@property(nonatomic, strong) id data;
@property(nonatomic) NSInteger msgId;

@end

@interface SEDataSource : NSObject<SEDataIdentifier>

- (void)fetchData;

- (id)parseData:(id)data;

@property(nonatomic, strong) id data;
@property(nonatomic) NSInteger msgId;
@property(nonatomic, weak) id controller;

@end
