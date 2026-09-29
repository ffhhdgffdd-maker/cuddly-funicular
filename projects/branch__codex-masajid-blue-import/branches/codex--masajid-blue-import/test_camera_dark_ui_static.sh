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

check "$MASTER" "١. اختيار صورة وتشغيل البث" "زر اختيار الصورة واضح ومرتب"
check "$MASTER" "٢. تشغيل البث الافتراضي" "زر تشغيل الكاميرا هو الخطوة الثانية"
check "$MASTER" "٣. الاحتفاظ بآخر صورة" "حفظ الصورة هو الخطوة الثالثة"
check "$MASTER" "٤. حذف الصورة وإيقاف البث" "الحذف والإيقاف هو الخطوة الرابعة"
check "$THEME" "+ (BOOL)isDark { return YES; }" "الثيم الداكن ثابت من مصدر الألوان"
check "$MASTER" 't:@"إدخال كود تفعيل WolFox"' "الإعدادات تعرض إدخال كود التفعيل"
check "$MASTER" 't:@"إعدادات الكاميرا"' "مدخل إعدادات الكاميرا ما زال متاحًا في Full"
check "$STORE" "self.themeIndex = 0;" "ترحيل الإعدادات السابقة إلى الوضع الداكن"
check "$MASTER" "accessibilityLabel = @\"الخطوة الأولى" "توضيح أزرار الكاميرا لقارئ الشاشة"
check "$MASTER" "accessibilityLabel = @\"الخطوة الرابعة" "توضيح زر الحذف لقارئ الشاشة"

echo "✅ اجتازت تحسينات واجهة الكاميرا والثيم الداكن اختبارات الحماية."
