#import "WFInterfaceSettings.h"
#include <math.h>

static NSString *WFRecoveryKey(WFRecoveryMethod method) {
    switch (method) {
        case WFRecoveryIcon: return @"WF_RECOVERY_ICON_ENABLED";
        case WFRecoveryVolume: return @"WF_RECOVERY_VOLUME_ENABLED";
        case WFRecoveryScreenshot: return @"WF_RECOVERY_SCREENSHOT_ENABLED";
    }
    return nil;
}

@implementation WFInterfaceSettings
+ (void)prepareDefaults:(NSUserDefaults *)defaults {
    @synchronized(defaults) {
        BOOL hasModern = NO;
        for (NSInteger method = 1; method <= 3; method++)
            hasModern |= [defaults objectForKey:WFRecoveryKey((WFRecoveryMethod)method)] != nil;
        NSInteger legacy = [defaults integerForKey:@"WF_RECOVERY_METHOD"];
        if (!hasModern) {
            if (!WFRecoveryMethodValid(legacy)) {
                BOOL icon = ![defaults objectForKey:@"WF_FLOATING_STATUS_VISIBLE"] || [defaults boolForKey:@"WF_FLOATING_STATUS_VISIBLE"];
                legacy = icon ? WFRecoveryIcon : ([defaults boolForKey:@"WF_PRO_VOLUME_GESTURE"] ? WFRecoveryVolume : WFRecoveryIcon);
            }
            for (NSInteger method = 1; method <= 3; method++)
                [defaults setBool:method == legacy forKey:WFRecoveryKey((WFRecoveryMethod)method)];
        }
        BOOL icon = [defaults boolForKey:WFRecoveryKey(WFRecoveryIcon)];
        BOOL volume = [defaults boolForKey:WFRecoveryKey(WFRecoveryVolume)];
        BOOL screenshot = [defaults boolForKey:WFRecoveryKey(WFRecoveryScreenshot)];
        if (!icon && !volume && !screenshot) {
            icon = YES; // Repair an older all-disabled state without locking the UI away.
            [defaults setBool:YES forKey:WFRecoveryKey(WFRecoveryIcon)];
        }
        if (!WFRecoveryMethodValid(legacy) || ![defaults boolForKey:WFRecoveryKey((WFRecoveryMethod)legacy)])
            legacy = icon ? WFRecoveryIcon : (volume ? WFRecoveryVolume : WFRecoveryScreenshot);
        [defaults setInteger:legacy forKey:@"WF_RECOVERY_METHOD"];
        // Compatibility mirrors are outputs, never a source after migration.
        [defaults setBool:icon forKey:@"WF_FLOATING_STATUS_VISIBLE"];
        [defaults setBool:volume forKey:@"WF_PRO_VOLUME_GESTURE"];
        [defaults setBool:NO forKey:@"WF_MENU_TRIPLE_TAP_ENABLED"];
    }
}
+ (BOOL)setRecoveryMethod:(WFRecoveryMethod)method enabled:(BOOL)enabled defaults:(NSUserDefaults *)defaults {
    if (!WFRecoveryMethodValid(method)) return NO;
    @synchronized(defaults) {
        [self prepareDefaults:defaults];
        if (!enabled) {
            BOOL otherEnabled = NO;
            for (NSInteger other = 1; other <= 3; other++)
                if (other != method) otherEnabled |= [defaults boolForKey:WFRecoveryKey((WFRecoveryMethod)other)];
            if (!otherEnabled) return NO;
        }
        [defaults setBool:enabled forKey:WFRecoveryKey(method)];
        [self prepareDefaults:defaults];
        return YES;
    }
}
+ (BOOL)recoveryMethod:(WFRecoveryMethod)method enabledInDefaults:(NSUserDefaults *)defaults {
    return WFRecoveryMethodValid(method) && [defaults boolForKey:WFRecoveryKey(method)];
}
+ (NSInteger)tapCountInDefaults:(NSUserDefaults *)defaults {
    NSInteger count = [defaults integerForKey:@"WF_FLOATING_TAP_COUNT"];
    return MAX(1, MIN(50, count ?: 1));
}
+ (NSInteger)volumeCountInDefaults:(NSUserDefaults *)defaults {
    NSInteger count = [defaults integerForKey:@"WF_VOLUME_PRESS_COUNT"];
    return count == 2 || count == 5 ? count : 3;
}
+ (NSInteger)iconSizeIndexInDefaults:(NSUserDefaults *)defaults {
    if (![defaults objectForKey:@"WF_FLOATING_STATUS_SIZE_INDEX"]) return 1;
    return MAX(0, MIN(2, [defaults integerForKey:@"WF_FLOATING_STATUS_SIZE_INDEX"]));
}
+ (double)iconOpacityInDefaults:(NSUserDefaults *)defaults {
    double opacity = [defaults objectForKey:@"WF_FLOATING_STATUS_OPACITY"] ? [defaults doubleForKey:@"WF_FLOATING_STATUS_OPACITY"] : 0.92;
    return isfinite(opacity) ? MAX(0.45, MIN(1.0, opacity)) : 0.92;
}
@end
