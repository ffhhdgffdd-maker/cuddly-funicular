#!/bin/bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
MASTER="$PROJECT_DIR/WolFoxMaster.mm"
THEME="$PROJECT_DIR/WolFoxProTheme.m"
STORE="$PROJECT_DIR/WolFoxProStore.m"

check() {
    grep -Fq "$2" "$1" || { echo "❌ $3"; exit 1; }
    echo "✅ $3"
}
reject() {
    if grep -Fq "$2" "$1"; then echo "❌ $3"; exit 1; fi
    echo "✅ $3"
}

check "$MASTER" 'setupVirtualCameraCardAtY:12.0' "قسم الكاميرا يبدأ مباشرة بلا زر عودة مكرر"
check "$MASTER" 'CGFloat actionWidth = (card.bounds.size.width - 48) / 2.0;' "إجراءات الكاميرا تستخدم صفاً مضغوطاً"
check "$MASTER" 'setTitle:@"اختيار صورة"' "زر اختيار الصورة واضح"
check "$MASTER" 'setTitle:@"تشغيل البث"' "زر تشغيل البث واضح"
check "$MASTER" 'الاحتفاظ بآخر صورة للاستخدام القادم' "خيار حفظ الصورة موجود"
check "$MASTER" 'حذف الصورة وإيقاف البث' "الحذف والإيقاف متاحان"
reject "$MASTER" '١. اختيار صورة وتشغيل البث' "تسلسل أزرار الكاميرا القديم أزيل"
reject "$MASTER" '٤. حذف الصورة وإيقاف البث' "النص المكرر للخطوات أزيل"
check "$THEME" '+ (BOOL)isDark { return YES; }' "الثيم الداكن ثابت من مصدر الألوان"
check "$MASTER" 't:@"إدخال كود تفعيل WolFox"' "الإعدادات تعرض إدخال كود التفعيل"
check "$MASTER" 'setupCameraPage' "مدخل إعدادات الكاميرا ما زال متاحاً في Full"
check "$STORE" 'self.themeIndex = 0;' "ترحيل الإعدادات السابقة إلى الوضع الداكن"
check "$MASTER" 'accessibilityLabel = @"اختيار صورة للكاميرا الافتراضية"' "اختيار الصورة موضح لقارئ الشاشة"
check "$MASTER" 'accessibilityLabel = @"حذف الصورة المختارة وإيقاف البث"' "الحذف موضح لقارئ الشاشة"

echo "✅ اجتازت واجهة الكاميرا المضغوطة اختبارات الحماية."
