#import <Foundation/Foundation.h>
#ifndef WOLFOX_INTERFACE_VARIANT
#define WOLFOX_INTERFACE_VARIANT 0
#endif
static inline BOOL WFInterfaceMenuDefault(NSInteger version) { return version != 4; }
static inline BOOL WFInterfaceVolumeAllowed(NSInteger version, BOOL preference) { return version != 4 && preference; }
static inline BOOL WFInterfaceTripleTapAllowed(NSInteger version, BOOL preference) { return version == 4 || preference; }
static inline BOOL WFInterfaceNeedsFallback(NSInteger version, BOOL icon, BOOL volume, BOOL taps) {
    return !icon && !WFInterfaceVolumeAllowed(version, volume) && !WFInterfaceTripleTapAllowed(version, taps);
}
