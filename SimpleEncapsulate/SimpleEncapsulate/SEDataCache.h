//
//  DataCache.h
//  SimpleEncapsulate
//
//  Created by yhtian on 13-5-30.
//  Copyright (c) 2013年 SimpleEncapsulate. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SEDataCache : NSCache<NSCacheDelegate>

+ (id)sharedCache;

- (void)saveObject:(id)object toFileWithKey:(NSString *)key;
- (id)objectFromFileWithKey:(NSString *)key;

- (void)removeFromFileWithKey:(NSString *)key;
- (void)removeAllFiles;

- (void)removeFilesBeforeDate:(NSDate *)date;

- (void)invalidate;

@end
