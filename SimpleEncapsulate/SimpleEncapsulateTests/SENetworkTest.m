//
//  SENetworkTest.m
//  SimpleEncapsulate
//
//  Created by yhtian on 14-7-4.
//  Copyright 2014年 yhtian. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import <SimpleEncapsulate/SimpleEncapsulate.h>
#import "NSObject+SupersequentImplementation.h"

static SENetwork *mockNetwork = nil;

@interface SENetwork (UnitTest)

+ (instancetype)createMockNetwork;

@end

@implementation SENetwork (UnitTest)

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-protocol-method-implementation"
+ (instancetype)sharedNetwork {
    if (mockNetwork != nil) {
        return mockNetwork;
    }
    return invokeSupersequentNoParameters();
}
#pragma clang diagnostic pop

+ (instancetype)createMockNetwork {
    mockNetwork = [OCMockObject mockForClass:[SENetwork class]];
    return mockNetwork;
}

+ (instancetype)createNiceMockNetwork {
    mockNetwork = [OCMockObject niceMockForClass:[SENetwork class]];
    return mockNetwork;
}

+ (void)releaseInstance {
    mockNetwork = nil;
}

@end

@interface SENetworkTest : XCTestCase

@end

@implementation SENetworkTest

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testFetch
{
    SENetwork *network = [SENetwork sharedNetwork];
    [network setBaseURLPath:@"www.github.com"];
    XCTAssertTrue([network.baseURLPath isEqualToString:@"www.github.com"],
                  @"Base url path should not be nil!");
    XCTAssertTrue(network.networkManager != nil, @"Network manager should not be nil.");
    id mock = [SENetwork createMockNetwork];
    [[mock stub] fetchWithMsgId:0
                         params:OCMOCK_ANY
              completionHandler:[OCMArg checkWithBlock:^BOOL(id obj) {
        void (^successBlock)(id data, NSError *error) = obj;
        successBlock([[NSObject alloc] init], nil);
        return YES;
    }]];
    __block BOOL completionInvoked = NO;
    [mock fetchWithMsgId:0 params:nil completionHandler:^(id data, NSError *error) {
        XCTAssertNil(error, @"Completion block shouldn't have error");
        XCTAssertNotNil(data, @"Completion block should have data, but doesn't.");
        completionInvoked = YES;
    }];
    while (!completionInvoked) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    }
    [mock verify];
    [mock stopMocking];
    [SENetwork releaseInstance];
}

@end
