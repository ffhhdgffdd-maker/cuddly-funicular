// WolFoxProTheme.m — v1.8.4 Fixed Dark Blue Panel UI
// خلفيات كحلية وأزرق هادئ للتفاعل مع نصوص مخففة السطوع.
// فلسفة التصميم: تباين مرتفع، أسطح كحلية عميقة، وعدم استخدام البنفسجي أو الذهبي في الهوية.
#import "WolFoxProTheme.h"
#import "WolFoxProStore.h"
#import "WFLicenseConfig.h"

// All v3 profiles share a calm blue palette; profile-specific layouts remain.
static NSInteger WFThemeEdition(void) {
    NSString *profile = WOLFOX_BUILD_PROFILE;
    if ([profile isEqualToString:@"control-full"]) return 1;
    if ([profile isEqualToString:@"mosques-full"]) return 2;
    if ([profile hasPrefix:@"lite-"]) return 3;
    if ([profile hasPrefix:@"full-"]) return 4;
    return 0;
}

static UIColor *WFEditionColor(CGFloat r, CGFloat g, CGFloat b) {
    return [UIColor colorWithRed:r green:g blue:b alpha:1.0];
}


@implementation WolFoxProTheme

// الإصدار 1.8.4 يثبت الوضع الليلي لتوحيد التباين ومنع تبدل الألوان بين الصفحات.
+ (BOOL)isDark { return YES; }

+ (UIColor *)windowBackground { return [self royalBackground]; }

// ── خلفيات البطاقات الزرقاء الداكنة ───────────────────────────
+ (UIColor *)surfacePrimary { return [UIColor colorWithWhite:0.14 alpha:1]; }

+ (UIColor *)surfaceSecondary { return [UIColor colorWithWhite:0.19 alpha:1]; }

// ── نصوص ─────────────────────────────────────────────────────
+ (UIColor *)textPrimary {
    return [self isDark]
        // أبيض بارد مريح للعين وواضح على الخلفية الداكنة
        ? [UIColor colorWithRed:0.850 green:0.885 blue:0.930 alpha:1.0]
        // داكن جداً في الفاتح
        : [UIColor colorWithRed:0.080 green:0.100 blue:0.130 alpha:1.0];
}

+ (UIColor *)textSecondary {
    switch (WFThemeEdition()) {
        case 1: return WFEditionColor(0.650, 0.725, 0.820);
        case 2: return WFEditionColor(0.650, 0.725, 0.820);
        case 3: return WFEditionColor(0.650, 0.725, 0.820);
        case 4: return WFEditionColor(0.650, 0.725, 0.820);
    }

    return [self isDark]
        ? [UIColor colorWithRed:0.620 green:0.735 blue:0.875 alpha:1.0]
        : [UIColor colorWithRed:0.380 green:0.430 blue:0.490 alpha:1.0];
}

// ── ألوان Dark Blue الأساسية عالية التباين ───────────────────
// accent: أزرق واضح للأزرار والتبويب النشط
+ (UIColor *)accent { return [UIColor colorWithRed:0 green:0.48 blue:1 alpha:1]; }

// danger: أحمر وردي واضح للحالة الحرجة والتوقف
+ (UIColor *)danger {
    return [UIColor colorWithRed:1.000 green:0.333 blue:0.475 alpha:1.0]; // #F04545
}

// success: أخضر واضح للتفعيل
+ (UIColor *)success {
    return [UIColor colorWithRed:0.220 green:0.827 blue:0.624 alpha:1.0]; // #25BE74
}

// gold: alias أزرق فاتح للمفضلة والتمييز، مع إبقاء اسم API للتوافق
+ (UIColor *)gold {
    if (WFThemeEdition()) return [self accent];

    return [UIColor colorWithRed:0.260 green:0.650 blue:1.000 alpha:1.0]; // أزرق فاتح
}

// ── الخلفية الكحلية الداكنة ─────────────────────────────────
+ (UIColor *)royalBackground { return [UIColor colorWithWhite:0.095 alpha:1]; }

+ (UIColor *)royalCard { return [self surfacePrimary]; }

+ (UIColor *)royalField { return [self surfaceSecondary]; }

+ (UIColor *)royalBlue {
    return [self accent];
}

// لون خلفية زر ثانوي (accent شفاف)
+ (UIColor *)accentSoft {
    return [[self accent] colorWithAlphaComponent:0.22];
}

+ (BOOL)reduceMotionEnabled { return UIAccessibilityIsReduceMotionEnabled(); }
+ (NSTimeInterval)transitionDuration { return [self reduceMotionEnabled] ? 0.0 : 0.22; }

+ (UIFont *)fontOfSize:(double)size weight:(UIFontWeight)weight {
    // One system family for Arabic and Latin, with restrained, consistent weights.
    return [UIFont systemFontOfSize:size weight:MIN(weight, UIFontWeightBold)];
}

+ (UIImage *)symbolNamed:(NSString *)name {
    UIImageSymbolConfiguration *configuration = [UIImageSymbolConfiguration configurationWithPointSize:20 weight:UIImageSymbolWeightSemibold];
    UIImage *image = [UIImage systemImageNamed:name withConfiguration:configuration];
    return image ?: [UIImage systemImageNamed:@"square.dashed" withConfiguration:configuration];
}
+ (UIColor *)borderColor { return [[self accent] colorWithAlphaComponent:0.18]; }

+ (UIBlurEffectStyle)blurStyle {
    if (@available(iOS 13.0, *)) {
        return [self isDark]
            ? UIBlurEffectStyleSystemMaterialDark
            : UIBlurEffectStyleSystemMaterialLight;
    }
    return UIBlurEffectStyleDark;
}

@end
