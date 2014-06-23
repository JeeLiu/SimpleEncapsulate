//
//  ImageCacheDataSource.m
//  SimpleEncapsulate
//
//  Created by yhtian on 14-4-8.
//  Copyright (c) 2014年 SimpleEncapsulate. All rights reserved.
//

#import "SEImageCache.h"
#import "AFNetworking.h"
#import "SEDataCache.h"

@implementation SEImageCache

+ (UIImage *)imageWithURLString:(NSString *)urlString
{
    UIImage *image;
    image = [[SEDataCache sharedCache] objectForKey:urlString];
    if (!image) {
        image = [[SEDataCache sharedCache] objectFromFileWithKey:urlString];
        if (image) {
            [[SEDataCache sharedCache] setObject:image forKey:urlString];
        }
    }
    return image;
}

+ (void)imageWithURLString:(NSString *)urlString
                   success:(void (^)(UIImage *))success
                   failure:(void (^)(NSError *))failure
{
    static NSOperationQueue *_imageOperationQueue;
    static AFImageResponseSerializer *_imageResponseSerializer;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _imageOperationQueue = [[NSOperationQueue alloc] init];
        _imageOperationQueue.maxConcurrentOperationCount = 3;
        _imageResponseSerializer = [AFImageResponseSerializer serializer];
    });
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:url];
    [urlRequest addValue:@"image/*" forHTTPHeaderField:@"Accept"];
    for (AFHTTPRequestOperation *operation in [_imageOperationQueue operations]) {
        if ([operation.request.URL.absoluteString isEqualToString:urlString]) {
            // In downloading.
            return;
        }
    }

    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:urlRequest];
    operation.responseSerializer = _imageResponseSerializer;
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        [[SEDataCache sharedCache] saveObject:responseObject toFileWithKey:urlString];
        if (success) {
            success(responseObject);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
    [_imageOperationQueue addOperation:operation];
    return;
}

+ (void)removeImageWithURLString:(NSString *)urlString
{
    [[SEDataCache sharedCache] removeFromFileWithKey:urlString];
}

+ (void)saveImage:(UIImage *)image withKey:(id<NSCopying>)key
{
    if (image && key) {
        [[SEDataCache sharedCache] setObject:image forKey:key];
        NSString *fileName;
        id k = key;
        if ([k isKindOfClass:[NSString class]]) {
            fileName = k;
        } else if ([k isKindOfClass:[NSNumber class]]) {
            fileName = [k stringValue];
        } else {
            fileName = [k description];
        }
        [[SEDataCache sharedCache] saveObject:image toFileWithKey:fileName];
    }
}

+ (UIImage *)imageWithKey:(id<NSCopying>)key
{
    if (key) {
        UIImage *image = [[SEDataCache sharedCache] objectForKey:key];
        if (!image) {
            NSString *fileName;
            id k = key;
            if ([k isKindOfClass:[NSString class]]) {
                fileName = k;
            } else if ([k isKindOfClass:[NSNumber class]]) {
                fileName = [k stringValue];
            } else {
                fileName = [k description];
            }
            image = [[SEDataCache sharedCache] objectFromFileWithKey:fileName];
            
            return image;
        }
    }
    return nil;
}

@end
