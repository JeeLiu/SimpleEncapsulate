//
//  ImageCacheDataSource.h
//  SimpleEncapsulate
//
//  Created by yhtian on 14-4-8.
//  Copyright (c) 2014年 SimpleEncapsulate. All rights reserved.
//

#import <Foundation/Foundation.h>

@import UIKit;

@interface SEImageCache : NSObject

/**
 *  @abstract 根据URL获取对应的图片，如果图片没在缓存中，则返回空。
 */
+ (UIImage *)imageWithURLString:(NSString *)urlString;

/**
 *  @abstract 根据URL获取服务器上的图片。
 */
+ (void)imageWithURLString:(NSString *)urlString
                   success:(void (^)(UIImage *image))success
                   failure:(void (^)(NSError *error))failure;

/**
 *  @abstract 删除缓存图片
 */
+ (void)removeImageWithURLString:(NSString *)urlString;

+ (void)saveImage:(UIImage *)image withKey:(id<NSCopying>)key;

+ (UIImage *)imageWithKey:(id<NSCopying>)key;

@end
