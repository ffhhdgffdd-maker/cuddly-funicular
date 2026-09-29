#import <Foundation/Foundation.h>
#ifndef WOLFOX_INTERFACE_VARIANT
#define WOLFOX_INTERFACE_VARIANT 0
#endif
typedef NS_ENUM(NSInteger, WFRecoveryMethod) { WFRecoveryIcon = 1, WFRecoveryVolume = 2, WFRecoveryBoth = 3 };
static inline BOOL WFRecoveryMethodValid(NSInteger method) { return method >= 1 && method <= 3; }
static inline BOOL WFRecoveryUsesIcon(NSInteger method) { return method == WFRecoveryIcon || method == WFRecoveryBoth; }
static inline BOOL WFRecoveryUsesVolume(NSInteger method) { return method == WFRecoveryVolume || method == WFRecoveryBoth; }
static inline NSString *WFRecoveryDescription(NSInteger method) {
    if (method == WFRecoveryVolume) return @"أزرار الصوت: اضغط العدد المحدد لاستعادة WolFox.";
    if (method == WFRecoveryBoth) return @"اضغط أيقونة WolFox أو استخدم ضغطات أزرار الصوت المحددة.";
    return @"اضغط أيقونة WolFox العائمة لفتح واجهة الأداة الكاملة.";
}
static inline BOOL WFInterfaceMenuDefault(NSInteger version) { (void)version; return NO; }
static inline BOOL WFInterfaceVolumeAllowed(NSInteger version, BOOL preference) { (void)version; return preference; }
static inline BOOL WFInterfaceTripleTapAllowed(NSInteger version, BOOL preference) { (void)version; (void)preference; return NO; }
static inline BOOL WFInterfaceNeedsFallback(NSInteger version, BOOL icon, BOOL volume, BOOL taps) {
    (void)version; (void)taps; return !icon && !volume;
}
