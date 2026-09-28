// WolFoxProTheme.m — WolFox Maps independent edition
// Dark map-first visual system: neutral surfaces, a clear blue primary action,
// purple favorites, cyan Bluetooth and a deliberate red hide action.
#import "WolFoxProTheme.h"

static UIColor *WFMapColor(CGFloat r, CGFloat g, CGFloat b) {
    return [UIColor colorWithRed:r green:g blue:b alpha:1.0];
}

@implementation WolFoxProTheme

+ (BOOL)isDark { return YES; }
+
+ (UIColor *)windowBackground { return [self royalBackground]; }
+
+ (UIColor *)surfacePrimary {
+    return WFMapColor(0.110, 0.112, 0.118); // #1C1D1E
+}
+
+ (UIColor *)surfaceSecondary {
+    return WFMapColor(0.180, 0.182, 0.192); // #2E2E31
+}
+
++ (UIColor *)controlSurface {
+    return WFMapColor(0.200, 0.200, 0.212); // #333336
+}
+
++ (UIColor *)outline {
+    return WFMapColor(0.310, 0.310, 0.330); // #4F4F54
+}
+
++ (UIColor *)textPrimary {
+    return WFMapColor(0.965, 0.965, 0.975); // #F6F6F9
+}
+
++ (UIColor *)textSecondary {
+    return WFMapColor(0.700, 0.700, 0.735); // #B3B3BC
+}
+
++ (UIColor *)accent {
+    return WFMapColor(0.000, 0.478, 1.000); // iOS blue #007AFF
+}
+
++ (UIColor *)danger {
+    return WFMapColor(1.000, 0.275, 0.235); // #FF463C
+}
+
++ (UIColor *)success {
+    return WFMapColor(0.190, 0.820, 0.345); // #31D157
+}
+
++ (UIColor *)favorite {
+    return WFMapColor(0.705, 0.310, 0.945); // #B44FF1
+}
+
++ (UIColor *)bluetooth {
+    return WFMapColor(0.260, 0.750, 0.855); // #42BFDA
+}
+
++ (UIColor *)gold {
+    // Kept as a compatibility alias for components that previously requested gold.
+    return [self favorite];
+}
+
++ (UIColor *)royalBackground {
+    return WFMapColor(0.055, 0.055, 0.060); // #0E0E0F
+}
+
++ (UIColor *)royalCard { return [self surfacePrimary]; }
++ (UIColor *)royalField { return [self controlSurface]; }
++ (UIColor *)royalBlue { return [self accent]; }
++ (UIColor *)accentSoft { return [[self accent] colorWithAlphaComponent:0.18]; }
+
++ (BOOL)reduceMotionEnabled { return UIAccessibilityIsReduceMotionEnabled(); }
++ (NSTimeInterval)transitionDuration { return [self reduceMotionEnabled] ? 0.0 : 0.20; }
+
++ (UIFont *)fontOfSize:(double)size weight:(UIFontWeight)weight {
+    return [UIFont systemFontOfSize:size weight:weight];
+}
+
++ (UIBlurEffectStyle)blurStyle {
+    if (@available(iOS 13.0, *)) return UIBlurEffectStyleSystemChromeMaterialDark;
+    return UIBlurEffectStyleDark;
+}
+
+@end
