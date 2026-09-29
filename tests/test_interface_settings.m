#import <Foundation/Foundation.h>
#import "WFInterfaceSettings.h"
#include <assert.h>
int main(void) { @autoreleasepool {
 NSString *freshSuite = [@"WF.Settings.FirstLaunch." stringByAppendingString:NSUUID.UUID.UUIDString];
 NSUserDefaults *fresh = [[NSUserDefaults alloc] initWithSuiteName:freshSuite];
 [WFInterfaceSettings prepareDefaults:fresh];
 assert([WFInterfaceSettings recoveryMethod:WFRecoveryIcon enabledInDefaults:fresh]);
 assert([fresh boolForKey:@"WF_FLOATING_STATUS_VISIBLE"]);
 [fresh removePersistentDomainForName:freshSuite];
 NSString *suite = [@"WF.Settings.Tests." stringByAppendingString:NSUUID.UUID.UUIDString];
 NSUserDefaults *d = [[NSUserDefaults alloc] initWithSuiteName:suite];
 [d setInteger:WFRecoveryScreenshot forKey:@"WF_RECOVERY_METHOD"];
 [WFInterfaceSettings prepareDefaults:d];
 assert([WFInterfaceSettings recoveryMethod:WFRecoveryScreenshot enabledInDefaults:d]);
 assert(![WFInterfaceSettings setRecoveryMethod:WFRecoveryScreenshot enabled:NO defaults:d]);
 assert([WFInterfaceSettings setRecoveryMethod:WFRecoveryVolume enabled:YES defaults:d]);
 [WFInterfaceSettings prepareDefaults:d];
 assert([WFInterfaceSettings recoveryMethod:WFRecoveryScreenshot enabledInDefaults:d]);
 assert([d boolForKey:@"WF_PRO_VOLUME_GESTURE"]);
 assert([WFInterfaceSettings setRecoveryMethod:WFRecoveryScreenshot enabled:NO defaults:d]);
 assert(![WFInterfaceSettings setRecoveryMethod:WFRecoveryVolume enabled:NO defaults:d]);
 [d setInteger:99 forKey:@"WF_FLOATING_TAP_COUNT"];
 [d setInteger:99 forKey:@"WF_VOLUME_PRESS_COUNT"];
 [d setInteger:99 forKey:@"WF_FLOATING_STATUS_SIZE_INDEX"];
 [d setDouble:0.1 forKey:@"WF_FLOATING_STATUS_OPACITY"];
 assert([WFInterfaceSettings tapCountInDefaults:d] == 50);
 assert([WFInterfaceSettings volumeCountInDefaults:d] == 3);
 assert([WFInterfaceSettings iconSizeIndexInDefaults:d] == 2);
 assert([WFInterfaceSettings iconOpacityInDefaults:d] == 0.45);
 [d setBool:NO forKey:@"WF_RECOVERY_VOLUME_ENABLED"];
 [WFInterfaceSettings prepareDefaults:d];
 assert([WFInterfaceSettings recoveryMethod:WFRecoveryIcon enabledInDefaults:d]);
 [d removePersistentDomainForName:suite];
 NSLog(@"Interface settings tests passed");
} return 0; }
