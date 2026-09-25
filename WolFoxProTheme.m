// WolFoxProTheme.m — v1.8.4 Fixed Dark Blue Panel UI
// تصميم آمن: خلفيات زرقاء داكنة، أزرق ساطع للتفاعل، وألوان حالة دلالية واضحة.
// فلسفة التصميم: تباين مرتفع، أسطح كحلية عميقة، وعدم استخدام البنفسجي أو الذهبي في الهوية.
#import "WolFoxProTheme.h"
#import "WolFoxProStore.h"
#import "WFLicenseConfig.h"

// Each v3 build embeds a profile; legacy builds keep the original blue palette.
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
+ (UIColor *)surfacePrimary {
    switch (WFThemeEdition()) {
        case 1: return WFEditionColor(0.065, 0.105, 0.160);
        case 2: return WFEditionColor(0.065, 0.150, 0.155);
        case 3: return WFEditionColor(0.125, 0.135, 0.175);
        case 4: return WFEditionColor(0.150, 0.105, 0.195);
    }

    return [self isDark]
        // داكن: أزرق كحلي يفصل البطاقة عن الخلفية
        ? [UIColor colorWithRed:0.035 green:0.075 blue:0.150 alpha:1.0]
        // فاتح: أبيض نقي للوضوح الكامل
        : [UIColor colorWithRed:1.000 green:1.000 blue:1.000 alpha:1.0];
}

+ (UIColor *)surfaceSecondary {
    switch (WFThemeEdition()) {
        case 1: return WFEditionColor(0.095, 0.165, 0.230);
        case 2: return WFEditionColor(0.100, 0.205, 0.205);
        case 3: return WFEditionColor(0.185, 0.200, 0.240);
        case 4: return WFEditionColor(0.210, 0.150, 0.260);
    }

    return [self isDark]
        ? [UIColor colorWithRed:0.055 green:0.115 blue:0.230 alpha:1.0]
        : [UIColor colorWithRed:0.930 green:0.940 blue:0.950 alpha:1.0];
}

// ── نصوص ─────────────────────────────────────────────────────
+ (UIColor *)textPrimary {
    return [self isDark]
        // أبيض بارد مريح للعين وواضح على الخلفية الداكنة
        ? [UIColor colorWithRed:0.930 green:0.965 blue:1.000 alpha:1.0]
        // داكن جداً في الفاتح
        : [UIColor colorWithRed:0.080 green:0.100 blue:0.130 alpha:1.0];
}

+ (UIColor *)textSecondary {
    switch (WFThemeEdition()) {
        case 1: return WFEditionColor(0.680, 0.805, 0.900);
        case 2: return WFEditionColor(0.700, 0.865, 0.840);
        case 3: return WFEditionColor(0.800, 0.825, 0.865);
        case 4: return WFEditionColor(0.845, 0.770, 0.895);
    }

    return [self isDark]
        ? [UIColor colorWithRed:0.620 green:0.735 blue:0.875 alpha:1.0]
        : [UIColor colorWithRed:0.380 green:0.430 blue:0.490 alpha:1.0];
}

// ── ألوان Dark Blue الأساسية عالية التباين ───────────────────
// accent: أزرق واضح للأزرار والتبويب النشط
+ (UIColor *)accent {
    switch (WFThemeEdition()) {
        case 1: return WFEditionColor(0.270, 0.700, 1.000);
        case 2: return WFEditionColor(0.270, 0.825, 0.695);
        case 3: return WFEditionColor(1.000, 0.725, 0.335);
        case 4: return WFEditionColor(0.760, 0.555, 1.000);
    }

    return [self isDark]
        ? [UIColor colorWithRed:0.120 green:0.475 blue:0.925 alpha:1.0]  // أزرق داكن واضح
        : [UIColor colorWithRed:0.090 green:0.360 blue:0.760 alpha:1.0]; // أزرق للوضع الفاتح
}

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
+ (UIColor *)royalBackground {
    switch (WFThemeEdition()) {
        case 1: return WFEditionColor(0.025, 0.055, 0.090);
        case 2: return WFEditionColor(0.025, 0.085, 0.090);
        case 3: return WFEditionColor(0.075, 0.085, 0.115);
        case 4: return WFEditionColor(0.075, 0.045, 0.105);
    }

    return [self isDark]
        // داكن: كحلي عميق
        ? [UIColor colorWithRed:0.018 green:0.040 blue:0.085 alpha:1.0]
        // فاتح: رمادي ناعم جداً
        : [UIColor colorWithRed:0.950 green:0.955 blue:0.965 alpha:1.0];
}

+ (UIColor *)royalCard {
    if (WFThemeEdition()) return [self surfacePrimary];

    // بطاقة داكنة: تعلو بوضوح فوق الخلفية الكحلية
    return [UIColor colorWithRed:0.035 green:0.075 blue:0.150 alpha:1.0];
}

+ (UIColor *)royalField {
    if (WFThemeEdition()) return [self surfaceSecondary];

    // حقل إدخال: أزرق أعمق قليلاً من البطاقة
    return [UIColor colorWithRed:0.045 green:0.100 blue:0.205 alpha:1.0];
}

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
    return [UIFont systemFontOfSize:size weight:weight];
}

+ (UIBlurEffectStyle)blurStyle {
    if (@available(iOS 13.0, *)) {
        return [self isDark]
            ? UIBlurEffectStyleSystemMaterialDark
            : UIBlurEffectStyleSystemMaterialLight;
    }
    return UIBlurEffectStyleDark;
}

@end
