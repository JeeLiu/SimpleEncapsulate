//
//  Utilities.h
//  SimpleEncapsulate
//
//  Created by yhtian on 13-5-4.
//  Copyright (c) 2013年 SimpleEncapsulate. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifdef DEBUG
#define LOG(format, ...)        NSLog(format, ##__VA_ARGS__)
#define TIP(format, ...)        NSLog(format", file:%s, line:%d, function:%s.", ##__VA_ARGS__, __FILE__, __LINE__, __PRETTY_FUNCTION__)
#define TRACE(format, ...)      NSLog(@"--- %s "format"---", __PRETTY_FUNCTION__, ##__VA_ARGS__)
#else
#define LOG(format, ...)
#define TIP(format, ...)
#define TRACE(format, ...)
#endif

@interface SEUtilities : NSObject

/**
 @method    +deviceIdentifier
 @abstract  Return an uniform UUID identifier each time.
 @return    UUID.
 @discussion If system is lower than 6.0, it returns an UUID and store to NSUserDefaults,
            else it returns |identifierForVendor.UUIDString|.
 */
+ (NSString *)deviceIdentifier;

+ (NSString *)filePathWithName:(NSString *)name inDirectory:(NSSearchPathDirectory)directory;

+ (NSString *)duplicateBundleFileWithName:(NSString *)fileName;

+ (NSString *)duplicateBundleFileWithName:(NSString *)fileName
                              toDirectory:(NSSearchPathDirectory)directory;
/**
 @method +duplicateBundleFileWithName:toDirectory:overwrite:
 @param |fileName|, name with suffix, such as "xxxx.xxx".
        |directory|, default directory is NSDocumentDirectory.
        |overwrite|, default is NO, not overwrite if exists.
 @return return |filePath| in directory, if copy succeed or
         file already exists, otherwise return nil.
 @discussion Copy file from mainbundle to current directory.
 */
+ (NSString *)duplicateBundleFileWithName:(NSString *)fileName
                              toDirectory:(NSSearchPathDirectory)directory
                                overwrite:(BOOL)overwrite;

/**
 @method    +systemVersionUpper50
 @abstract  Check if iOS is upper than 5.0.
 @return    YES if system is upper than 5.0.
 */
+ (BOOL)systemVersionUpper50;

/**
 @method    +configureWithSourceName:
 @abstract  Read a configure file and return an array or dictionary.
 @param     |sourceName|, name of configure file, plist.
 @return    NSArray or NSDictionary.
 @discussion Return value NSArray or NSDictionary, determined by the plist file.
            If file is an array, return NSArray, if file is an dictionary, return
            NSDictionary, otherwise return directly without format.
 */
+ (id)configureWithSourceName:(NSString *)sourceName;

/**
 @method    +archiveObject:toFile:
 @abstract  Archive an object to file.
 @param     |object|, the object we need to archive.
 @param     |filePath|, the file we archive to.
 @discussion When archiving an object to file, we set the root key "root".
 */
+ (void)archiveObject:(id)object toFile:(NSString *)filePath;

/**
 @method    +unarchiveObjectFromFile:
 @abstract  Unarchive an object from file.
 @param     |filePath|, the file we archive from.
 @return    The object we unarchived.
 @discussion When unarchiving an object to file, the first key is "root".
 */
+ (id)unarchiveObjectFromFile:(NSString *)filePath;

/**
 @method    +propertiesNameOfObject:
 @abstract  Get properties name of object.
 @param     |object|, the object we get from.
 @return    The array of properties name.
 */
+ (NSArray *)propertiesNameOfObject:(id)object;

@end
