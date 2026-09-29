#import <Foundation/Foundation.h>
#ifndef WOLFOX_INTERFACE_VARIANT
#define WOLFOX_INTERFACE_VARIANT 0
#endif
typedef NS_ENUM(NSInteger, WFRecoveryMethod) { WFRecoveryVolume = 2 };
static inline BOOL WFRecoveryMethodValid(NSInteger method) { return method == WFRecoveryVolume; }
static inline BOOL WFRecoveryUsesIcon(NSInteger method) { (void)method; return NO; }
static inline BOOL WFRecoveryUsesVolume(NSInteger method) { return method == WFRecoveryVolume; }
static inline NSString *WFRecoveryDescription(NSInteger method) {
    (void)method;
    return @"لإظهار WolFox مجددًا، اضغط زر رفع الصوت أو خفضه ٣ ضغطات سريعة متتالية خلال ١٫٥ ثانية والتطبيق مفتوح.";
}
static inline BOOL WFInterfaceMenuDefault(NSInteger version) { (void)version; return NO; }
static inline BOOL WFInterfaceVolumeAllowed(NSInteger version, BOOL preference) { (void)version; (void)preference; return YES; }
static inline BOOL WFInterfaceTripleTapAllowed(NSInteger version, BOOL preference) { (void)version; (void)preference; return NO; }
static inline BOOL WFInterfaceNeedsFallback(NSInteger version, BOOL icon, BOOL volume, BOOL taps) {
    (void)version; (void)icon; (void)volume; (void)taps; return NO;
}
