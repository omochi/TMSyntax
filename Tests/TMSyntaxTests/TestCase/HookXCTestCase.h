#import <XCTest/XCTest.h>

NS_ASSUME_NONNULL_BEGIN

@interface HookXCTestCase : XCTestCase

- (instancetype)initWithInvocation:(nullable NSInvocation *)invocation;
- (void)didInitWithInvocation;
    
@end

NS_ASSUME_NONNULL_END
