//
//  SEMessageDefine.h
//  SimpleEncapsulate
//
//  Created by yhtian on 12-9-18.
//  Copyright (c) 2012年 SimpleEncapsulate. All rights reserved.
//

#ifndef SimpleEncapsulate_SEMessageDefine_h
#define SimpleEncapsulate_SEMessageDefine_h

#define kSEDomainName   @"SimpleEncapsulate"

typedef NS_ENUM(NSInteger, SEMessageID) {
    kMessageIDUnknown = 0,
    //Define msg here.
};

#define COMBINE(a, b)                       ((a)|((b) << 16))
#define MAINMSG(a)                          (((NSUInteger)a) & 0xFFFF)
#define SUBMSG(a)                           (((NSUInteger)a) >> 16)

typedef NS_ENUM(NSInteger, SEResponseCode) {
    kResponseCodeNoInternet = -1002,
    kResponseCodeTimeout = -1001,
    kResponseCodeInternal = -999,
    kResponseCodeError = 0,
    kResponseCodeSuccess = 1,
};

typedef NS_ENUM(NSInteger, NetworkFetchType) {
    kFetchTypeGet,
    kFetchTypePost,
    kFetchTypePostForm,
    kFetchTypePut,
    kFetchTypeDelete,
    kFetchTypePatch,
};

typedef NS_ENUM(NSInteger, NetworkEncodingType) {
    kEncodingTypeFormURL,
    kEncodingTypeJSON,
    kEncodingTypePropertyList,
};

typedef NS_ENUM(NSInteger, NetworkResponseType) {
    kResponseTypeJSON,
    kResponseTypePropertyList, // Can be xml
    kResponseTypeProtoBuffer,
    kResponseTypeUnknown
};

typedef NS_ENUM(NSInteger, NetworkReachableStatus) {
    kReachableUnknown = -1,
    kReachableNotReachable,
    kReachableViaWWAN,
    kReachableViaWIFI,
};

#endif
