//
//  BookInfo.h
//  SimpleEncapsulateDemo
//
//  Created by yhtian on 14-6-12.
//  Copyright (c) 2014年 yhtian. All rights reserved.
//

#import <SimpleEncapsulate/SimpleEncapsulate.h>

@interface Rating : AMCObject

@property(nonatomic) NSInteger max;
@property(nonatomic) NSInteger numRaters;
@property(nonatomic, strong) NSString *average;
@property(nonatomic) NSInteger min;

@end

AMC_CONTAINER_TYPE(Tags)

@interface Tags : AMCObject<Tags>

@property(nonatomic) NSInteger count;
@property(nonatomic, strong) NSString *name;
@property(nonatomic, strong) NSString *title;

@end

@interface Images : AMCObject

@property(nonatomic, strong) NSString *small;
@property(nonatomic, strong) NSString *large;
@property(nonatomic, strong) NSString *medium;

@end

@interface BookInfo : AMCObject

@property(nonatomic, strong) Rating *rating;
@property(nonatomic, strong) NSString *subtitle;
@property(nonatomic, strong) NSArray *author;
@property(nonatomic, strong) NSString *pubdate;
@property(nonatomic, strong) NSArray<Tags> *tags;
@property(nonatomic, strong) NSString *origin_title;
@property(nonatomic, strong) NSString *image;
@property(nonatomic, strong) NSString *binding;
@property(nonatomic, strong) NSArray *translator;
@property(nonatomic, strong) NSString *catalog;
@property(nonatomic, strong) NSString *pages;
@property(nonatomic, strong) Images *images;
@property(nonatomic, strong) NSString *alt;
@property(nonatomic, strong) NSString *id;
@property(nonatomic, strong) NSString *publisher;
@property(nonatomic, strong) NSString *isbn10;
@property(nonatomic, strong) NSString *isbn13;
@property(nonatomic, strong) NSString *title;
@property(nonatomic, strong) NSString *url;
@property(nonatomic, strong) NSString *alt_title;
@property(nonatomic, strong) NSString *author_intro;
@property(nonatomic, strong) NSString *summary;
@property(nonatomic, strong) NSString *price;

@end
