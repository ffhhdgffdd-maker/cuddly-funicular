#import <Foundation/Foundation.h>
#import "WFInterfacePolicy.h"

@interface WFInterfaceSettings : NSObject
+ (void)prepareDefaults:(NSUserDefaults *)defaults;
+ (BOOL)setRecoveryMethod:(WFRecoveryMethod)method enabled:(BOOL)enabled defaults:(NSUserDefaults *)defaults;
+ (BOOL)recoveryMethod:(WFRecoveryMethod)method enabledInDefaults:(NSUserDefaults *)defaults;
+ (NSInteger)volumeCountInDefaults:(NSUserDefaults *)defaults;
+ (NSInteger)iconSizeIndexInDefaults:(NSUserDefaults *)defaults;
+ (double)iconOpacityInDefaults:(NSUserDefaults *)defaults;
@end
