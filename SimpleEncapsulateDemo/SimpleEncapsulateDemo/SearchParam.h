//
//  SearchParam.h
//  SimpleEncapsulateDemo
//
//  Created by yhtian on 14-6-13.
//  Copyright (c) 2014年 yhtian. All rights reserved.
//

#import <SimpleEncapsulate/SimpleEncapsulate.h>

//q     查询关键字	q和tag必传其一
//tag	查询的tag	q和tag必传其一
//start	取结果的offset	默认为0
//count	取结果的条数	默认为20，最大为100

@interface SearchParam : AMCObject

@property(nonatomic, strong) NSString *q;
@property(nonatomic, strong) NSString *tag;
@property(nonatomic) NSInteger start;
@property(nonatomic) NSInteger count;

@end
