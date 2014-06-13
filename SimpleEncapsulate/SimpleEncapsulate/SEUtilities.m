//
//  Utilities.m
//  SimpleEncapsulate
//
//  Created by yhtian on 13-5-4.
//  Copyright (c) 2013年 SimpleEncapsulate. All rights reserved.
//

#import "SEUtilities.h"
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <objc/message.h>

static NSString *const kUserDefaultUUIDKey = @"uuid";

@implementation SEUtilities

+ (NSString *)deviceIdentifier
{
    NSString *v = [[UIDevice currentDevice] systemVersion];
    if ([v compare:@"6.0" options:NSNumericSearch] != NSOrderedAscending) {
        return [[UIDevice currentDevice].identifierForVendor UUIDString];
    }
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *uuid = [defaults objectForKey:kUserDefaultUUIDKey];
    if (!uuid) {
        CFUUIDRef uniqueIdRef = CFUUIDCreate(kCFAllocatorDefault);
        CFStringRef uniqueIdStringRef = CFUUIDCreateString(kCFAllocatorDefault, uniqueIdRef);
        CFRelease(uniqueIdRef);
        uuid = (__bridge NSString *)(uniqueIdStringRef);
        [defaults setObject:uuid forKey:kUserDefaultUUIDKey];
        [defaults synchronize];
        CFRelease(uniqueIdStringRef);
    }
    return uuid;
}

+ (NSString *)filePathWithName:(NSString *)name inDirectory:(NSSearchPathDirectory)directory
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(directory, NSUserDomainMask, YES);
    if (paths.count > 0) {
        if ([name length]) {
            NSString *filePath = [NSString stringWithFormat:@"%@/%@", [paths lastObject], name];
            return filePath;
        } else {
            return [paths lastObject];
        }
    }
    NSLog(@"Can't find directory!");
    return nil;
}

+ (NSString *)duplicateBundleFileWithName:(NSString *)fileName
{
    return [self duplicateBundleFileWithName:fileName toDirectory:NSDocumentDirectory];
}

+ (NSString *)duplicateBundleFileWithName:(NSString *)fileName
                              toDirectory:(NSSearchPathDirectory)directory
{
    return [self duplicateBundleFileWithName:fileName toDirectory:directory overwrite:NO];
}

+ (NSString *)duplicateBundleFileWithName:(NSString *)fileName
                              toDirectory:(NSSearchPathDirectory)directory
                                overwrite:(BOOL)overwrite
{
    NSString *filePath = [self filePathWithName:fileName inDirectory:directory];
    BOOL copy = overwrite || ![[NSFileManager defaultManager] fileExistsAtPath:filePath];
    if (copy) {
        NSError *error;
        if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
            [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
            if (error) {
                NSLog(@"Remove file failed with error: %@", error);
            }
        }
        NSString *name = [fileName stringByDeletingPathExtension];
        NSString *originPath = [[NSBundle mainBundle] pathForResource:name ofType:[fileName pathExtension]];
        BOOL success;
        if (originPath == nil) {
            success = [[NSFileManager defaultManager] createFileAtPath:filePath
                                                              contents:[NSData data]
                                                            attributes:nil];
        } else {
            success = [[NSFileManager defaultManager] copyItemAtPath:originPath
                                                              toPath:filePath
                                                               error:&error];
        }
        if (!success) {
            NSLog(@"Create or Copy file failed with error: %@", error);
            return nil;
        }
    }
    return filePath;
}

+ (BOOL)systemVersionUpper50
{
    NSString *v = [[UIDevice currentDevice] systemVersion];
    return ([v compare:@"5.0" options:NSNumericSearch] != NSOrderedAscending);
}

+ (id)configureWithSourceName:(NSString *)sourceName
{
    NSString *filePath = [self duplicateBundleFileWithName:sourceName];
    if (filePath) {
        NSData *data = [NSData dataWithContentsOfFile:filePath];
        if ([NSPropertyListSerialization propertyList:data isValidForFormat:NSPropertyListXMLFormat_v1_0]) {
            NSPropertyListFormat format;
            id result = [NSPropertyListSerialization propertyListWithData:data
                                                                  options:NSPropertyListMutableContainers
                                                                   format:&format
                                                                    error:nil];
            return result;
        }
        return data;
    }
    return nil;
}

#define kArchiveObjectRootName  @"root"

+ (void)archiveObject:(id)object toFile:(NSString *)filePath
{
    NSMutableData *data = [[NSMutableData alloc] init];
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
    [archiver encodeObject:object forKey:kArchiveObjectRootName];
    [archiver finishEncoding];
    [data writeToFile:filePath atomically:YES];
}

+ (id)unarchiveObjectFromFile:(NSString *)filePath
{
    NSData *data = [[NSMutableData alloc] initWithContentsOfFile:filePath];
    NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
    id obj = [unarchiver decodeObjectForKey:kArchiveObjectRootName];
    [unarchiver finishDecoding];
    return obj;
}

+ (NSArray *)propertiesNameOfObject:(id)object
{
    NSMutableArray *array = [NSMutableArray array];
    unsigned int numProps = 0;
    objc_property_t *properties = class_copyPropertyList([object class], &numProps);
    for (int i = 0; i < numProps; i++) {
        objc_property_t property = properties[i];
        const char *propertyName = property_getName(property);
        NSString *objName = [NSString stringWithUTF8String:propertyName];
        [array addObject:objName];
    }
    free(properties);
    properties = NULL;
    return array;
}

@end
