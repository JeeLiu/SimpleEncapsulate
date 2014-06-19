//
//  DataSource.h
//  SimpleEncapsulate
//
//  Created by yhtian on 14-4-2.
//  Copyright (c) 2014年 SimpleEncapsulate. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, SEDataState) {
    kSEDataStateUnInitial,
    kSEDataStateFetching,
    kSEDataStateReceiveSucceed,
    kSEDataStateReceiveFailed,
};

@protocol SEDataIdentifier <NSObject>

@property(nonatomic, strong) id data;
@property(nonatomic) NSInteger msgId;
@property(nonatomic) SEDataState state;

@end

/**
 *  A simple way to fetch data.
 */
@interface SEDataSource : NSObject<SEDataIdentifier>

- (void)fetchData;

- (id)parseData:(id)data;

@property(nonatomic, weak) id controller;

@end
