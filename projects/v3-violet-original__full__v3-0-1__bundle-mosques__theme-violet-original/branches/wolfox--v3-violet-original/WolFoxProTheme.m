// WolFox 3.0.0 — violet night identity shared by all editions.
// Keeps semantic success/danger colors and high contrast text.
#import "WolFoxProTheme.h"
#import "WolFoxProStore.h"

@implementation WolFoxProTheme

// الإصدار 3.0.0 يثبت الوضع الليلي لتوحيد التباين ومنع تبدل الألوان بين الصفحات.
+ (BOOL)isDark { return YES; }

+ (UIColor *)windowBackground { return [self royalBackground]; }

// ── خلفيات البطاقات الزرقاء الداكنة ───────────────────────────
+ (UIColor *)surfacePrimary {
    return [self isDark]
        // داكن: بنفسجي داكن يفصل البطاقة عن الخلفية
        ? [UIColor colorWithRed:0.091 green:0.067 blue:0.161 alpha:1.0]
        // فاتح: أبيض نقي للوضوح الكامل
        : [UIColor colorWithRed:1.000 green:1.000 blue:1.000 alpha:1.0];
}

+ (UIColor *)surfaceSecondary {
    return [self isDark]
        ? [UIColor colorWithRed:0.137 green:0.103 blue:0.224 alpha:1.0]
        : [UIColor colorWithRed:0.930 green:0.940 blue:0.950 alpha:1.0];
}

// ── نصوص ─────────────────────────────────────────────────────
+ (UIColor *)textPrimary {
    return [self isDark]
        // أبيض بارد مريح للعين وواضح على الخلفية الداكنة
        ? [UIColor colorWithRed:0.957 green:0.939 blue:1.000 alpha:1.0]
        // داكن جداً في الفاتح
        : [UIColor colorWithRed:0.080 green:0.100 blue:0.130 alpha:1.0];
}

+ (UIColor *)textSecondary {
    return [self isDark]
        ? [UIColor colorWithRed:0.730 green:0.680 blue:0.831 alpha:1.0]
        : [UIColor colorWithRed:0.380 green:0.430 blue:0.490 alpha:1.0];
}

// ── ألوان Violet Night الأساسية عالية التباين ───────────────────
// accent: بنفسجي واضح للأزرار والتبويب النشط
+ (UIColor *)accent {
    return [self isDark]
        ? [UIColor colorWithRed:0.655 green:0.410 blue:0.980 alpha:1.0]  // بنفسجي داكن واضح
        : [UIColor colorWithRed:0.490 green:0.255 blue:0.790 alpha:1.0]; // بنفسجي للوضع الفاتح
}

// danger: أحمر وردي واضح للحالة الحرجة والتوقف
+ (UIColor *)danger {
    return [UIColor colorWithRed:1.000 green:0.333 blue:0.475 alpha:1.0]; // #F04545
}

// success: أخضر واضح للتفعيل
+ (UIColor *)success {
    return [UIColor colorWithRed:0.220 green:0.827 blue:0.624 alpha:1.0]; // #25BE74
}

// gold: alias لافندر للمفضلة والتمييز، مع إبقاء اسم API للتوافق
+ (UIColor *)gold {
    return [UIColor colorWithRed:0.805 green:0.620 blue:1.000 alpha:1.0]; // لافندر
}

// ── الخلفية البنفسجية الداكنة ─────────────────────────────────
+ (UIColor *)royalBackground {
    return [self isDark]
        // داكن: بنفسجي عميق
        ? [UIColor colorWithRed:0.040 green:0.027 blue:0.081 alpha:1.0]
        // فاتح: رمادي ناعم جداً
        : [UIColor colorWithRed:0.950 green:0.955 blue:0.965 alpha:1.0];
}

+ (UIColor *)royalCard {
    // بطاقة داكنة: تعلو بوضوح فوق الخلفية البنفسجية
    return [UIColor colorWithRed:0.091 green:0.067 blue:0.161 alpha:1.0];
}

+ (UIColor *)royalField {
    // حقل إدخال: بنفسجي أعمق قليلاً من البطاقة
    return [UIColor colorWithRed:0.116 green:0.081 blue:0.191 alpha:1.0];
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
