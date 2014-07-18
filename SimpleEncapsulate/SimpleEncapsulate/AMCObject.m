//
//  AMCObject.m
//  AutoMagicCoding
//  This file is copied from https://github.com/psineur/NSObject-AutomagicCoding
//  and modified by yhtian.

//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

#import "AMCObject.h"

#if TARGET_OS_IPHONE
#import <objc/runtime.h>
#import <objc/message.h>
#else
#import <objc/objc-runtime.h>
#endif

#ifdef __IPHONE_OS_VERSION_MAX_ALLOWED

#import "UIKit/UIKit.h"
#import "CoreGraphics/CoreGraphics.h"

#define NSPoint CGPoint
#define NSSize CGSize
#define NSRect CGRect

#define NSPointFromString CGPointFromString
#define NSSizeFromString CGSizeFromString
#define NSRectFromString CGRectFromString

#define pointValue CGPointValue
#define sizeValue CGSizeValue
#define rectValue CGRectValue

#define NSStringFromPoint NSStringFromCGPoint
#define NSStringFromSize NSStringFromCGSize
#define NSStringFromRect NSStringFromCGRect

#define NSVALUE_ENCODE_POINT(__P__) [NSValue valueWithCGPoint:__P__]
#define NSVALUE_ENCODE_SIZE(__S__) [NSValue valueWithCGSize:__S__]
#define NSVALUE_ENCODE_RECT(__R__) [NSValue valueWithCGRect:__R__]

#else

#define NSVALUE_ENCODE_POINT(__P__) [NSValue valueWithPoint:__P__]
#define NSVALUE_ENCODE_SIZE(__S__) [NSValue valueWithSize:__S__]
#define NSVALUE_ENCODE_RECT(__R__) [NSValue valueWithRect:__R__]

#endif

#import <Availability.h>
#undef AMCRetain
#undef AMCDealloc
#undef AMCAutorelease
#undef AMCDealloc

#if __has_feature(objc_arc)
#define AMCRetain(a) (a)
#define AMCRelease(a) (a)
#define AMCAutorelease(a) (a)
#define AMCDealloc self
#else
#define AMCRetain(a) [a retain]
#define AMCRelease(a) [a release]
#define AMCAutorelease(a) [a autorelease]
#define AMCDealloc dealloc
#endif

NSString *const AMCVersion = @"2.0";
NSString *const AMCEncodeException = @"AMCEncodeException";
NSString *const AMCDecodeException = @"AMCDecodeException";
NSString *const AMCKeyValueCodingFailureException = @"AMCKeyValueCodingFailureException";

@implementation AMCObject

+ (BOOL)AMCEnabled
{
    return YES;
}

+ (BOOL)AMCEnabledInDB
{
    return NO;
}

#pragma mark Decode/Create/Init

+ (id) objectWithDictionaryRepresentation: (NSDictionary *) aDict
{
    if (![aDict isKindOfClass:[NSDictionary class]])
        return [[self alloc] init];

    if ( [self instancesRespondToSelector:@selector(initWithDictionaryRepresentation:) ] )
    {
        id instance = AMCAutorelease([[self alloc] initWithDictionaryRepresentation: aDict]);
        return instance;
    }
    return [[self alloc] init];
}

- (id) initWithDictionaryRepresentation: (NSDictionary *) aDict
{
    // NSObject#init simply returns self, so we don't need to call any init here.
    // See NSObject Class Reference if you don't trust me ;)
    self = [super init];
    @try
    {
        
        if (aDict)
        {
            NSArray *keysForValues = [self AMCKeysForDictionaryRepresentation];
            for (NSString *propertyName in keysForValues)
            {
                NSString *key = [self keyWithPropertyName:propertyName];
                id value = [aDict valueForKey: key];
                if ([value isEqual:[NSNull null]] ||
                    ([value isKindOfClass:[NSString class]] && [value isEqualToString:@"<null>"])) {
                    value = nil;
                }
                if (value)
                {
                    AMCFieldType fieldType = [self AMCFieldTypeForValueWithKey: propertyName];
                    if (fieldType == kAMCFieldTypeScalar) {
                        // is id ?
                        fieldType = [self AMCFieldTypeForEncodedObject:value withKey:propertyName];
                    }
                    objc_property_t property = class_getProperty([self class], [propertyName cStringUsingEncoding:NSUTF8StringEncoding]);
                    if ( kAMCFieldTypeStructure == fieldType)
                    {
                        NSValue *structValue = [self AMCDecodeStructFromString: (NSString *)value withName: AMCPropertyStructName(property)];
                        [self setValue: structValue forKey: propertyName];
                    }
                    else
                    {
                        id class = AMCPropertyClass(property);
                        value = [self AMCDecodeObject:value filedType:fieldType collectionClass:class key:propertyName];
                        [self setValue:value forKey: propertyName];
                    }
                }
            }
        }
        
    }
    
    @catch (NSException *exception) {

#ifdef AMC_NO_THROW
        return nil;
#else
        @throw exception;
#endif
    }
    
    return self;
}

#if !__has_feature(objc_arc)
// recursive to release variables.
- (void)dispose:(id)object {
    NSDictionary *dic = AMCPropertyListOfObject(object);
    for (id key in dic) {
        NSString *value = [dic objectForKey:key];
        const char *attributes = [value UTF8String];
        size_t len = strlen(attributes) + 1;
        char attrs[len];
        strcpy(attrs, attributes);
        char *attr = strtok(attrs, ",");
        BOOL needRelease = NO;
        Ivar ivar = NULL;
        while (attr != NULL) {
            if (attr[0] == 'C' || attr[0] == '&') {
                // Property is 'copy' or 'retain', so we need to release it.
                needRelease = YES;
            } else if (attr[0] == 'V') {
                // Variables started with 'V'.
                ivar = class_getInstanceVariable([object class], attr + 1);
            }
            attr = strtok(NULL, ",");
        }
        if (needRelease && ivar) {
            id obj = object_getIvar(object, ivar);
            if (obj) {
                // If retainCount of |obj| is 1, we need to release it's sub-object.
                if ([obj retainCount] == 1 &&
                    [obj isKindOfClass:[AMCObject class]]) {
                    [self dispose:obj];
                }
                objc_msgSend(obj, @selector(release));
                object_setIvar(object, ivar, nil);
            }
        }
    }
}

#endif

- (void)dealloc {
#if !__has_feature(objc_arc)
    [self dispose:self];
    [super dealloc];
#endif
}

- (id)copyWithZone:(NSZone *)zone
{
    id obj = [[self class] allocWithZone:zone];
    NSDictionary *dic = AMCPropertyListOfObject(self);
    for (id key in dic) {
        [obj setValue:[self valueForKey:key] forKey:key];
    }
    return obj;
}

- (NSString *)description
{
#if DEBUG && SHOW_COMPLEMENT_DESCRIPTION
    NSMutableString *string = [super description].mutableCopy;
    NSMutableString *objStr = [NSMutableString string];
    NSDictionary *dic = AMCPropertyListOfObject(self);
    for (id key in dic) {
        id value = [self valueForKey:key];
        if (value) {
            [objStr appendFormat:@"; %@ = %@", key, value];
        }
    }
    [string insertString:objStr atIndex:[string length] - 1];
    return string;
#else
    return [super description];
#endif
}

#pragma mark Encode/Save

- (NSDictionary *) dictionaryRepresentation
{
    NSArray *keysForValues = [self AMCKeysForDictionaryRepresentation];
    NSMutableDictionary *aDict = [NSMutableDictionary dictionaryWithCapacity:[keysForValues count] + 1];
    
    @try
    {
        for (NSString *propertyName in keysForValues)
        {
            // Save our current isa, to restore it after using valueForKey:, cause
            // it can corrupt it sometimes (sic!), when getting ccColor3B struct via
            // property/method. (Issue #19)
            Class oldIsa = object_getClass(self);
            
            // Get value with KVC as usual.
            id value = [self valueForKey: propertyName];
            
            if (oldIsa != object_getClass(self))
            {
#ifdef AMC_NO_THROW
                NSLog(@"ATTENTION: isa was corrupted, valueForKey: %@ returned %@ It can be garbage!", key, value);
                
#else
                NSException *exception = [NSException exceptionWithName: AMCKeyValueCodingFailureException
                                                                 reason: [NSString stringWithFormat:@"ATTENTION: isa was corrupted, valueForKey: %@ returned %@ It can be garbage!", propertyName, value]
                                                               userInfo: nil ];
                @throw exception;
#endif
                
                // Restore isa.
                object_setClass(self, oldIsa);
            }
            
            AMCFieldType fieldType = [self AMCFieldTypeForValueWithKey: propertyName];
            
            if ( kAMCFieldTypeStructure == fieldType)
            {
                objc_property_t property = class_getProperty([self class], [propertyName cStringUsingEncoding:NSUTF8StringEncoding]);
                value = [self AMCEncodeStructWithValue: value withName: AMCPropertyStructName(property)];
            }
            else
            {
                value = [self AMCEncodeObject:value filedType:fieldType];
            }
            
            // Scalar or struct - simply use KVC.
            NSString *key = [self keyWithPropertyName:propertyName];
            [aDict setValue:value forKey: key];
        }
    }
    @catch (NSException *exception) {
#ifdef AMC_NO_THROW
        return nil;
#else
        @throw exception;
#endif
    }
    
    return aDict;
}

#pragma mark - override by subclass

- (NSString *)keyWithPropertyName:(NSString *)propertyName
{
    return propertyName;
}

- (NSString *)propertyNameWithKey:(NSString *)key
{
    return key;
}

#pragma mark Info for Serialization

- (NSArray *) AMCKeysForDictionaryRepresentation
{
    return AMCKeysForDictionaryRepresentationOfClass([self class]);
}

- (id) AMCDecodeObject: (id) value filedType: (AMCFieldType) fieldType collectionClass: (id) collectionClass key: (id) key
{
    switch (fieldType)
    {
            
            // Object as it's representation - create new.
        case kAMCFieldTypeCustomObject:
        {
            if (classInstancesRespondsToAllSelectorsInProtocol(collectionClass, @protocol(AMCArrayProtocol)) ||
                classInstancesRespondsToAllSelectorsInProtocol([collectionClass class], @protocol(AMCHashProtocol))) {
                objc_property_t property = class_getProperty([self class], [key cStringUsingEncoding:NSUTF8StringEncoding]);
                collectionClass = AMCContainerTypeClass(property);
            }
            id object = [[collectionClass alloc] initWithDictionaryRepresentation:(NSDictionary *) value];
            // Here was following code:
            // if (object)
            //    value = object;
            //
            // It was replaced with this one:
            
            value = object;
            
            // To pass -testIntToObjectDecode added in b5522b23a4b484359dca32ddfd38e9dff51bc853
            // In that test dictionaryRepresentation was modified and NSNumber (kAMCFieldTypeScalar)
            // was set to field with type kAMCFieldTypeCustomObject.
            // So there was NSNumber object set instead of Bar in that test.
            // It's possible to modify dictionaryRepresentation so, that one custom object
            // will be set instead of other custom object, but if -objectWithDictionaryRepresentation
            // returns nil - that definetly can't be set as customObject.
            
        }
            break;
            
            
        case kAMCFieldTypeCollectionArray:
        case kAMCFieldTypeCollectionArrayMutable:
        {
            // Create temporary array of all objects in collection.
            id <AMCArrayProtocol> srcCollection = (id <AMCArrayProtocol> ) value;
            NSMutableArray *dstCollection = [NSMutableArray arrayWithCapacity:[srcCollection count]];
            for (unsigned int i = 0; i < [srcCollection count]; ++i)
            {
                id curEncodedObjectInCollection = [srcCollection objectAtIndex: i];
                AMCFieldType type = [self AMCFieldTypeForEncodedObject:curEncodedObjectInCollection
                                                               withKey:key];
                id curDecodedObjectInCollection = [self AMCDecodeObject:curEncodedObjectInCollection
                                                              filedType:type
                                                        collectionClass:collectionClass
                                                                    key:key];
                [dstCollection addObject: curDecodedObjectInCollection];
            }
            
            // Get Collection Array Class from property and create object
            id class = collectionClass;
            if (!collectionClass)
            {
                if (fieldType == kAMCFieldTypeCollectionArray)
                    class = [NSArray class];
                else
                    class = [NSMutableArray class];
            }
            
            id <AMCArrayProtocol> object = (id <AMCArrayProtocol> )[class alloc];
            @try
            {
                object = [object initWithArray: dstCollection];
            }
            @finally {
                AMCAutorelease(object);
            }
            
            if (object)
                value = object;
        }
            break;
            
        case kAMCFieldTypeCollectionHash:
        case kAMCFieldTypeCollectionHashMutable:
        {
            // Create temporary array of all objects in collection.
            NSObject <AMCHashProtocol> *srcCollection = (NSObject <AMCHashProtocol> *) value;
            NSMutableDictionary *dstCollection = [NSMutableDictionary dictionaryWithCapacity:[srcCollection count]];
            for (NSString *curKey in [srcCollection allKeys])
            {
                id curEncodedObjectInCollection = [srcCollection valueForKey: curKey];
                AMCFieldType type = [self AMCFieldTypeForEncodedObject:curEncodedObjectInCollection
                                                               withKey:key];
                id curDecodedObjectInCollection = [self AMCDecodeObject:curEncodedObjectInCollection
                                                              filedType:type
                                                        collectionClass:collectionClass
                                                                    key:key];
                NSString *propertyName = [self propertyNameWithKey:curKey];
                [dstCollection setObject: curDecodedObjectInCollection forKey: propertyName];
            }
            
            // Get Collection Array Class from property and create object
            id class = collectionClass;
            if (!collectionClass ||
                ![collectionClass isSubclassOfClass:[AMCObject class]])
            {
                if (fieldType == kAMCFieldTypeCollectionHash)
                    class = [NSDictionary class];
                else
                    class = [NSMutableDictionary class];
            }
            
            id <AMCHashProtocol> object = (id <AMCHashProtocol> )[class alloc];
            @try
            {
                object = [object initWithDictionary: dstCollection];
            }
            @finally {
                AMCAutorelease(object);
            }
            
            if (object)
                value = object;
        }            break;
            
            // Scalar or struct - simply use KVC.
        case kAMCFieldTypeScalar:
            // Add a NSDate type create.
            if ([collectionClass isSubclassOfClass:[NSDate class]] &&
                [value isKindOfClass:[NSNumber class]]) {
                value = [NSDate dateWithTimeIntervalSince1970:[value longLongValue]];
            }
            break;
        default:
            break;
    }
    
    return value;
}

- (id) AMCEncodeObject: (id) value filedType: (AMCFieldType) fieldType
{
    switch (fieldType)
    {
            
            // Object as it's representation - create new.
        case kAMCFieldTypeCustomObject:
        {
            if ([value respondsToSelector:@selector(dictionaryRepresentation)])
                value = [value dictionaryRepresentation];
        }
            break;
            
        case kAMCFieldTypeCollectionArray:
        case kAMCFieldTypeCollectionArrayMutable:
        {
            
            id <AMCArrayProtocol> collection = (id <AMCArrayProtocol> )value;
            NSMutableArray *tmpArray = [NSMutableArray arrayWithCapacity: [collection count]];
            
            for (unsigned int i = 0; i < [collection count]; ++i)
            {
                NSObject *curObjectInCollection = [collection objectAtIndex: i];
                AMCFieldType type = [self AMCFieldTypeForObjectToEncode:curObjectInCollection
                                                                withKey:nil];
                NSObject *curObjectInCollectionEncoded = [self AMCEncodeObject:curObjectInCollection
                                                                     filedType:type];
                [tmpArray addObject: curObjectInCollectionEncoded];
            }
            
            value = tmpArray;
        }
            break;
            
        case kAMCFieldTypeCollectionHash:
        case kAMCFieldTypeCollectionHashMutable:
        {
            NSObject <AMCHashProtocol> *collection = (NSObject <AMCHashProtocol> *)value;
            NSMutableDictionary *tmpDict = [NSMutableDictionary dictionaryWithCapacity: [collection count]];
            
            for (NSString *curKey in [collection allKeys])
            {
                NSObject *curObjectInCollection = [collection valueForKey: curKey];
                NSString *key = [self keyWithPropertyName:curKey];
                AMCFieldType type = [self AMCFieldTypeForObjectToEncode:curObjectInCollection
                                                                withKey:curKey];
                NSObject *curObjectInCollectionEncoded = [self AMCEncodeObject:curObjectInCollection
                                                                     filedType:type];
                [tmpDict setObject:curObjectInCollectionEncoded forKey:key];
            }
            
            value = tmpDict;
        }
            break;
            
            
            // Scalar or struct - simply use KVC.
        case kAMCFieldTypeScalar:
            break;
        default:
            break;
    }
    
    return value;
}

- (AMCFieldType) AMCFieldTypeForValueWithKey: (NSString *) aKey
{
    // isAutoMagicCodingEnabled == YES? Then it's custom object.
    objc_property_t property = class_getProperty([self class], [aKey cStringUsingEncoding:NSUTF8StringEncoding]);
    id class = AMCPropertyClass(property);
    
    if ([class isSubclassOfClass:[AMCObject class]] && [class AMCEnabled])
        return kAMCFieldTypeCustomObject;
    
    // Is it ordered collection?
    if ( classInstancesRespondsToAllSelectorsInProtocol(class, @protocol(AMCArrayProtocol) ) )
    {
        // Mutable?
        if ( classInstancesRespondsToAllSelectorsInProtocol(class, @protocol(AMCArrayMutableProtocol) ) )
            return kAMCFieldTypeCollectionArrayMutable;
        
        // Not Mutable.
        return kAMCFieldTypeCollectionArray;
    }
    
    // Is it hash collection?
    if ( classInstancesRespondsToAllSelectorsInProtocol(class, @protocol(AMCHashProtocol) ) )
    {
        // Mutable?
        if ( classInstancesRespondsToAllSelectorsInProtocol(class, @protocol(AMCHashMutableProtocol) ) )
            return kAMCFieldTypeCollectionHashMutable;
        
        // Not Mutable.
        return kAMCFieldTypeCollectionHash;
    }
    
    // Is it a structure?
    NSString *structName = AMCPropertyStructName(property);
    if (structName)
        return kAMCFieldTypeStructure;
    
    // Otherwise - it's a scalar or PLIST-Compatible object (i.e. NSString)
    return kAMCFieldTypeScalar;
}

- (AMCFieldType)AMCFieldTypeForEncodedObject:(id)object withKey:(NSString *)aKey
{
    id class = [object class];
    
    // Is it ordered collection?
    if ( classInstancesRespondsToAllSelectorsInProtocol(class, @protocol(AMCArrayProtocol) ) )
    {
        // Mutable?
        if ( classInstancesRespondsToAllSelectorsInProtocol(class, @protocol(AMCArrayMutableProtocol) ) )
            return kAMCFieldTypeCollectionArrayMutable;
        
        // Not Mutable.
        return kAMCFieldTypeCollectionArray;
    }
    
    // Is it hash collection?
    if ( classInstancesRespondsToAllSelectorsInProtocol(class, @protocol(AMCHashProtocol) ) )
    {
        // Maybe it's custom object encoded in NSDictionary?
        if (aKey && [object respondsToSelector:@selector(objectForKey:)])
        {
            objc_property_t property = class_getProperty([self class], [aKey cStringUsingEncoding:NSUTF8StringEncoding]);
            id encodedObjectClass = AMCContainerTypeClass(property);
            if ([encodedObjectClass AMCEnabled]) {
                return kAMCFieldTypeCustomObject;
            }
        }
        
        // Mutable?
        if ( classInstancesRespondsToAllSelectorsInProtocol(class, @protocol(AMCHashMutableProtocol) ) )
            return kAMCFieldTypeCollectionHashMutable;
        
        // Not Mutable.
        return kAMCFieldTypeCollectionHash;
    }
    
    
    return kAMCFieldTypeScalar;
}

- (AMCFieldType) AMCFieldTypeForObjectToEncode:(id) object withKey:(NSString *)key
{
    id class = [object class];
    
    // Is it custom object with dictionaryRepresentation support?
    if ([class isSubclassOfClass:[AMCObject class]] && [class AMCEnabled] &&
        ([object respondsToSelector:@selector(dictionaryRepresentation)]))
    {
        return kAMCFieldTypeCustomObject;
    }
    
    // Is it ordered collection?
    if ( classInstancesRespondsToAllSelectorsInProtocol(class, @protocol(AMCArrayProtocol) ) )
    {
        // Mutable?
        if ( classInstancesRespondsToAllSelectorsInProtocol(class, @protocol(AMCArrayMutableProtocol) ) )
            return kAMCFieldTypeCollectionArrayMutable;
        
        // Not Mutable.
        return kAMCFieldTypeCollectionArray;
    }
    
    // Is it hash collection?
    if ( classInstancesRespondsToAllSelectorsInProtocol(class, @protocol(AMCHashProtocol) ) )
    {
        // Mutable?
        if ( classInstancesRespondsToAllSelectorsInProtocol(class, @protocol(AMCHashMutableProtocol) ) )
            return kAMCFieldTypeCollectionHashMutable;
        
        // Not Mutable.
        return kAMCFieldTypeCollectionHash;
    }
    
    return kAMCFieldTypeScalar;
}

#ifdef __IPHONE_OS_VERSION_MAX_ALLOWED

- (NSString *) className
{
    const char* name = class_getName([self class]);
    
    return [NSString stringWithCString:name encoding:NSUTF8StringEncoding];
}

+ (NSString *) className
{
    const char* name = class_getName([self class]);
    
    return [NSString stringWithCString:name encoding:NSUTF8StringEncoding];
}

#endif

#pragma mark Structure Support

- (NSValue *) AMCDecodeStructFromString: (NSString *)value withName: (NSString *) structName
{
    // valueForKey: never returns CGPoint, CGRect, etc - it returns NSPoint, NSRect stored in NSValue instead.
    // This is why here was made no difference between struct names such CGP
    
    if ([structName isEqualToString:@"CGPoint"] || [structName isEqualToString:@"NSPoint"])
    {
        NSPoint p = NSPointFromString(value);
        
        return NSVALUE_ENCODE_POINT(p);
    }
    else if ([structName isEqualToString:@"CGSize"] || [structName isEqualToString:@"NSSize"])
    {
        NSSize s = NSSizeFromString(value);
        
        return NSVALUE_ENCODE_SIZE(s);
    }
    else if ([structName isEqualToString:@"CGRect"] || [structName isEqualToString:@"NSRect"])
    {
        NSRect r = NSRectFromString(value);
        
        return NSVALUE_ENCODE_RECT(r);
    }
    
    if (!structName)
        structName = @"(null)";
    NSException *exception = [NSException exceptionWithName: AMCDecodeException
                                                     reason: [NSString stringWithFormat:@"AMCDecodeException: %@ is unsupported struct.", structName]
                                                   userInfo: nil ];
    
    @throw exception;
    
    return nil;
}

- (NSString *) AMCEncodeStructWithValue: (NSValue *) structValue withName: (NSString *) structName
{
    // valueForKey: never returns CGPoint, CGRect, etc - it returns NSPoint, NSRect stored in NSValue instead.
    // This is why here was made no difference between struct names such CGPoint & NSPoint.
    
    if ( [structName isEqualToString:@"CGPoint"] || [structName isEqualToString:@"NSPoint"])
    {
        NSPoint point = [structValue pointValue];
        
        return NSStringFromPoint(point);
    }
    else if ( [structName isEqualToString:@"CGSize"] || [structName isEqualToString:@"NSSize"])
    {
        NSSize size = [structValue sizeValue];
        
        return NSStringFromSize(size);
    }
    else if ( [structName isEqualToString:@"CGRect"] || [structName isEqualToString:@"NSRect"])
    {
        NSRect rect = [structValue rectValue];
        
        return NSStringFromRect(rect);
    }
    
    if (!structName)
        structName = @"(null)";
    NSException *exception = [NSException exceptionWithName: AMCEncodeException
                                                     reason: [NSString stringWithFormat:@"AMCEncodeException: %@ is unsupported struct.", structName]
                                                   userInfo: nil ];
    
    @throw exception;
    
    return nil;
}

#pragma mark Helper Functions

NSArray *AMCKeysForDictionaryRepresentationOfClass(Class cls)
{
    // Array that will hold properties names.
    NSMutableArray *array = [NSMutableArray array/*WithCapacity: 0*/];
    
    // Go through superClasses from self class to NSObject to get all inherited properties.
    id curClass = cls;
    while (1)
    {
        // Stop on NSObject.
        if (curClass && curClass == [NSObject class])
            break;
        
        // Use objc runtime to get all properties and return their names.
        unsigned int outCount;
        objc_property_t *properties = class_copyPropertyList(curClass, &outCount);
        
        // Reverse order of curClass properties, cause we will return reversed array.
        for (int i = outCount - 1; i >= 0; --i)
        {
            objc_property_t curProperty = properties[i];
            const char *name = property_getName(curProperty);
            
            NSString *propertyKey = [NSString stringWithCString:name encoding:NSUTF8StringEncoding];
            [array addObject: propertyKey];
        }
        
        if (properties)
            free(properties);
        
        // Next.
        curClass = [curClass superclass];
    }
    
    id result = [[array reverseObjectEnumerator] allObjects];
    
    return result;
}

id AMCPropertyClass (objc_property_t property)
{
    if (!property)
        return nil;
    
    const char *attributes = property_getAttributes(property);
    char *classNameCString = strstr(attributes, "@\"");
    if ( classNameCString )
    {
        classNameCString += 2; //< skip @" substring
        NSString *classNameString = [NSString stringWithCString:classNameCString encoding:NSUTF8StringEncoding];
        NSRange range = [classNameString rangeOfString:@"\""];
        
        classNameString = [classNameString substringToIndex: range.location];

        NSArray *classComponents = [classNameString componentsSeparatedByString:@"<"];
        id class = NSClassFromString(classComponents[0]);
        return class;
    }
    
    return nil;
}

Class AMCContainerTypeClass(objc_property_t property)
{
    if (!property)
        return Nil;

    const char *attributes = property_getAttributes(property);
    char *classNameCString = strstr(attributes, "@\"");
    if ( classNameCString )
    {
        classNameCString += 2; //< skip @" substring
        NSString *classNameString = [NSString stringWithCString:classNameCString encoding:NSUTF8StringEncoding];
        NSRange range = [classNameString rangeOfString:@"\""];

        classNameString = [classNameString substringToIndex: range.location];
        NSArray *classComponents = [classNameString componentsSeparatedByString:@"<"];
        if ([classComponents count] == 2) { // has <protocol?>
            Class prefixClass = NSClassFromString(classComponents[0]);
            if (classInstancesRespondsToAllSelectorsInProtocol(prefixClass, @protocol(AMCArrayProtocol)) ||
                classInstancesRespondsToAllSelectorsInProtocol(prefixClass, @protocol(AMCHashProtocol))) {
                NSString *sufixString = [classComponents[1] substringToIndex:[classComponents[1] length] - 1];
                Class class = NSClassFromString(sufixString); // amc ?
                if (class_getSuperclass(class) == AMCObject.class &&
                    classInstancesRespondsToAllSelectorsInProtocol(class, NSProtocolFromString(sufixString))) {
                    return class;
                }
            }
        }
    }
    return Nil;
}

NSString *AMCPropertyStructName(objc_property_t property)
{
    if (!property)
        return nil;
    
    const char *attributes = property_getAttributes(property);
    char *structNameCString = strstr(attributes, "T{");
    if ( structNameCString )
    {
        structNameCString += 2; //< skip T{ substring
        NSString *structNameString = [NSString stringWithCString:structNameCString encoding:NSUTF8StringEncoding];
        NSRange range = [structNameString rangeOfString:@"="];
        
        structNameString = [structNameString substringToIndex: range.location];
        
        return structNameString;
    }
    
    return nil;
}

static NSDictionary *AMCPropertyListOfObject(id object)
{
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    unsigned int numProps = 0;
    objc_property_t *properties = class_copyPropertyList([object class], &numProps);
    for (int i = 0; i < numProps; i++) {
        objc_property_t property = properties[i];
        const char *name = property_getName(property);
        NSString *key = [NSString stringWithUTF8String:name];
        const char *attribute = property_getAttributes(property);
        NSString *value = [NSString stringWithUTF8String:attribute];
        [dic setObject:value forKey:key];
    }
    free(properties);
    return dic;
}

BOOL classInstancesRespondsToAllSelectorsInProtocol(id class, Protocol *p )
{
    unsigned int outCount = 0;
    struct objc_method_description *methods = NULL;
    if (!class || !p) {
        return NO;
    }
    methods = protocol_copyMethodDescriptionList( p, YES, YES, &outCount);
    
    for (unsigned int i = 0; i < outCount; ++i)
    {
        SEL selector = methods[i].name;
        if (![class instancesRespondToSelector: selector])
        {
            if (methods)
                free(methods);
            methods = NULL;
            
            return NO;
        }
    }
    
    if (methods)
        free(methods);
    methods = NULL;
    
    return YES;
}

@end

@implementation NSObject (AMCRepresentation)

+ (id) objectWithRepresentation: (id)representation
{
    return [self objectWithRepresentation:representation className:nil];
}

+ (id) objectWithRepresentation: (id)representation className: (NSString *)className
{
    id container = nil;
    if ([representation isKindOfClass:[NSArray class]]) {
        container = [[NSMutableArray alloc] init];
    }
    Class cls = NSClassFromString(className);
    if (cls == nil && [self isSubclassOfClass:[AMCObject class]]) {
        cls = self;
    }
    if (container) {
        for (NSDictionary *dic in representation) {
            id obj = [cls objectWithDictionaryRepresentation:dic];
            if (obj) {
                [container addObject:obj];
            }
        }
        return container;
    } else if ([representation isKindOfClass:[NSDictionary class]]) {
        return [cls objectWithDictionaryRepresentation:representation];
    } else {
        return [[[self class] alloc] init];
    }
}

- (id) representation
{
    id representation = self;
    id container = [[[[self class] alloc] init] mutableCopy];
    if ([self isKindOfClass:[NSArray class]]) {
        for (id obj in representation) {
            if ([obj isKindOfClass:[AMCObject class]]) {
                id object = [obj dictionaryRepresentation];
                if (object) {
                    [container addObject:object];
                }
            } else {
                [container addObject:obj];
            }
        }
        return container;
    } else if ([self isKindOfClass:[NSDictionary class]]) {
        for (id key in representation) {
            id obj = [representation objectForKey:key];
            if ([obj isKindOfClass:[AMCObject class]]) {
                id object = [obj dictionaryRepresentation];
                if (object) {
                    [container setObject:object forKey:key];
                }
            } else {
                [container setObject:obj forKey:key];
            }
        }
        return container;
    } else if ([self isKindOfClass:[AMCObject class]]) {
        return [representation dictionaryRepresentation];
    }
    return self;
}

@end
