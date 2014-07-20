//
//  DataCache.m
//  SimpleEncapsulate
//
//  Created by yhtian on 13-5-30.
//  Copyright (c) 2013年 SimpleEncapsulate. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <CommonCrypto/CommonDigest.h>
#import "SEDataCache.h"
#import "AMCObject.h"
#import "SEUtilities.h"

static const NSInteger kDataCacheTotalCostLimit = 200;
static const NSInteger kDataCacheCountLimit = 150;

@interface NSString (SHA1)

- (NSString *)sha1;

@end

@implementation NSString (SHA1)

static inline char HexChar(unsigned char c) {
    return c < 10 ? '0' + c : 'a' + c - 10;
}

static void HexString(unsigned char *from, char *to, NSUInteger length) {
    for (NSUInteger i = 0; i < length; ++i) {
        unsigned char c = from[i];
        unsigned char cHigh = c >> 4;
        unsigned char cLow = c & 0xf;
        to[2 * i] = HexChar(cHigh);
        to[2 * i + 1] = HexChar(cLow);
    }
    to[2 * length] = '\0';
}

- (NSString *)sha1
{
    static const NSUInteger LENGTH = 20;
    unsigned char result[LENGTH];
    const char *string = [self UTF8String];
    CC_SHA1(string, (CC_LONG)strlen(string), result);
    char hexResult[2 * LENGTH + 1];
    HexString(result, hexResult, LENGTH);
    return [NSString stringWithUTF8String:hexResult];
}

@end

static NSString *SEDataCacheInfoFile(void)
{
    static NSString *filePath;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        filePath = [SEUtilities filePathWithName:@"DataCache.plist"
                                     inDirectory:NSCachesDirectory];
    });
    return filePath;
}

@implementation SEDataCache {
    dispatch_queue_t _defaultQueue;
}

+ (instancetype)sharedCache
{
    static SEDataCache *z_dataCache;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        z_dataCache = [[self alloc] init];
    });
    return z_dataCache;
}


- (id)init {
    self = [super init];
    if (self) {
        [self setName:@"SEDataCache"];
        [self setTotalCostLimit:kDataCacheTotalCostLimit];
        [self setCountLimit:kDataCacheCountLimit];
        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidReceiveMemoryWarningNotification
                                                          object:nil
                                                           queue:[NSOperationQueue mainQueue]
                                                      usingBlock:^(NSNotification * __unused notification) {
                                                          [self removeAllObjects];
                                                          [self.cacheDataMap removeAllObjects];
                                                      }];
        _defaultQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    }
    return self;
}

- (NSMutableDictionary *)cacheDataMap
{
    static NSMutableDictionary *dataCacheMap = nil;
    if ([dataCacheMap count] == 0) {
        dispatch_sync(_defaultQueue, ^{
            dataCacheMap = [NSMutableDictionary dictionaryWithContentsOfFile:SEDataCacheInfoFile()];
            if (!dataCacheMap) {
                dataCacheMap = [NSMutableDictionary dictionary];
            }
        });
    }
    return dataCacheMap;
}

- (void)saveName:(NSString *)name type:(NSString *)type forKey:(NSString *)key
{
    dispatch_sync(_defaultQueue, ^{
        NSDictionary *dic = @{@"name": name, @"type": type, @"date": [NSDate date]};
        [[self cacheDataMap] setObject:dic forKey:key];
        [[self cacheDataMap] writeToFile:SEDataCacheInfoFile()
                              atomically:YES];
    });
}

- (void)saveObject:(id)object toFileWithKey:(NSString *)key
{
    if (object && key) {
        dispatch_sync(_defaultQueue, ^{
            NSString *fileName = [key sha1];
            NSString *filePath = [SEUtilities filePathWithName:fileName
                                                   inDirectory:NSCachesDirectory];
            NSString *type = NSStringFromClass([object class]);
            id data;
            if ([object isKindOfClass:[UIImage class]]) {
                NSString *ext = [[key pathExtension] lowercaseString];
                if ([ext isEqualToString:@"jpg"] || [ext isEqualToString:@"jpeg"]) {
                    data = UIImageJPEGRepresentation(object, 1);
                } else {
                    // Assume png.
                    data = UIImagePNGRepresentation(object);
                }
            } else if ([object isKindOfClass:[NSData class]]) {
                data = object;
            } else if ([object isKindOfClass:[AMCObject class]]) {
                data = [object dictionaryRepresentation];
            } else if ([object isKindOfClass:[NSArray class]]) {
                id obj = [object firstObject];
                if ([obj isKindOfClass:[AMCObject class]]) {
                    // We assume all data are same type...
                    type = [type stringByAppendingFormat:@"<%@>", [obj className]];
                    data = [object representation];
                } else {
                    data = object;
                }
            } else if ([object isKindOfClass:[NSDictionary class]]) {
                id obj = [[object allValues] firstObject];
                if ([obj isKindOfClass:[AMCObject class]]) {
                    // We assume all data are same type...
                    type = [type stringByAppendingFormat:@"<%@>", [obj className]];
                    data = [object representation];
                } else {
                    data = object;
                }
            } else if ([object conformsToProtocol:@protocol(NSCoding)]) {
                data = [NSKeyedArchiver archivedDataWithRootObject:object];
            } else {
                NSLog(@"Unknown data %@ formmat to save!", object);
                return;
            }
            [data writeToFile:filePath atomically:YES];
            [self saveName:fileName
                      type:type
                    forKey:key];
        });
    }
}

- (id)objectFromFileWithKey:(id)key
{
    if (key) {
        __block id data = nil;
        dispatch_sync(_defaultQueue, ^{
            NSDictionary *dic = [[self cacheDataMap] objectForKey:key];
            if (!dic) {
                return;
            }
            NSString *filePath = [SEUtilities filePathWithName:dic[@"name"]
                                                   inDirectory:NSCachesDirectory];
            if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
                dispatch_sync(_defaultQueue, ^{
                    [[self cacheDataMap] removeObjectForKey:key];
                });
                return;
            }
            NSString *type = dic[@"type"];
            NSArray *array = [type componentsSeparatedByString:@"<"];
            Class regClass = NSClassFromString(array[0]);
            if ([regClass isSubclassOfClass:[AMCObject class]]) {
                data = [NSDictionary dictionaryWithContentsOfFile:filePath];
                data = [regClass objectWithRepresentation:data];
            } else if ([regClass isSubclassOfClass:[UIImage class]]) {
                data = [UIImage imageWithContentsOfFile:filePath];
            } else if ([regClass isSubclassOfClass:[NSData class]] ||
                       regClass == nil) {
                // Assume data;
                data = [NSData dataWithContentsOfFile:filePath];
            } else if ([regClass isSubclassOfClass:[NSArray class]]) {
                data = [NSArray arrayWithContentsOfFile:filePath];
                if ([array count] == 2) {
                    NSString *className = [array[1] substringToIndex:[array[1] length] - 1];
                    data = [regClass objectWithRepresentation:data className:className];
                }
            } else if ([regClass isSubclassOfClass:[NSDictionary class]]) {
                data = [NSDictionary dictionaryWithContentsOfFile:filePath];
                if ([array count] == 2) {
                    NSString *className = [array[1] substringToIndex:[array[1] length] - 1];
                    data = [regClass objectWithRepresentation:data className:className];
                }
            } else if ([regClass conformsToProtocol:@protocol(NSCoding)]) {
                data = [NSKeyedUnarchiver unarchiveObjectWithFile:filePath];
            } else {
                NSLog(@"Unknown data %@ format to get!", dic[@"type"]);
            }
        });
        return data;
    }
    return nil;
}

- (void)removeFromFileWithKey:(id)key
{
    if (key) {
        dispatch_sync(_defaultQueue, ^{
            NSDictionary *dic = [[self cacheDataMap] objectForKey:key];
            NSString *filePath = [SEUtilities filePathWithName:dic[@"name"]
                                                   inDirectory:NSCachesDirectory];
            if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
                [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
            }
            [[self cacheDataMap] removeObjectForKey:key];
            [[self cacheDataMap] writeToFile:SEDataCacheInfoFile()
                                  atomically:YES];
        });
    }
}

- (void)removeAllFiles
{
    dispatch_sync(_defaultQueue, ^{
        for (id key in [self cacheDataMap]) {
            NSDictionary *dic = [[self cacheDataMap] objectForKey:key];
            NSString *filePath = [SEUtilities filePathWithName:dic[@"name"]
                                                   inDirectory:NSCachesDirectory];
            [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
        }
        [[self cacheDataMap] removeAllObjects];
        [[NSFileManager defaultManager] removeItemAtPath:SEDataCacheInfoFile()
                                                   error:nil];
    });
}

- (void)removeFilesBeforeDate:(NSDate *)date
{
    dispatch_sync(_defaultQueue, ^{
        NSArray *array = [[self cacheDataMap] allValues];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.date < %@", date];
        array = [array filteredArrayUsingPredicate:predicate];
        for (NSDictionary *dic in array) {
            NSString *filePath = [SEUtilities filePathWithName:dic[@"name"]
                                                   inDirectory:NSCachesDirectory];
            [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
            NSArray *keys = [[self cacheDataMap] allKeysForObject:dic];
            [[self cacheDataMap] removeObjectsForKeys:keys];
        }
        [[self cacheDataMap] writeToFile:SEDataCacheInfoFile()
                              atomically:YES];
    });
}

- (void)invalidate
{
    [self removeAllObjects];
    [self removeAllFiles];
}

@end
