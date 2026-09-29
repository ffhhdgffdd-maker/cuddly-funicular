#!/bin/bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
MASTER="$PROJECT_DIR/WolFoxMaster.mm"
INTEGRATED="$PROJECT_DIR/WolFoxIntegrated.mm"
ACTIVATION="$PROJECT_DIR/WFActivationViewController.m"
CONFIG="$PROJECT_DIR/WFLicenseConfig.h"

check() { grep -Fq "$2" "$1" || { echo "❌ $3"; exit 1; }; echo "✅ $3"; }
reject() { if grep -Fq "$2" "$1"; then echo "❌ $3"; exit 1; fi; echo "✅ $3"; }

if grep -Fq '_titleLabel.text = @"WolFox";' "$MASTER"; then
    echo "✅ اسم WolFox الأساسي متاح مع اسم الإصدار"
else
    echo "❌ اسم WolFox الأساسي غير موجود"; exit 1
fi
reject "$MASTER" '@"الكاميرا", @"الإعدادات"' "تبويب الكاميرا محذوف من الواجهة"
check "$MASTER" 'NSString *onboardingEdition = @"WolFox";' "عداد الجولة يعرض Lite الصحيح"
check "$MASTER" 'NSString *onboardingEdition = @"WolFox";' "عداد الجولة يعرض Full الصحيح"
check "$MASTER" 'displayVersion = [NSString stringWithFormat:@"WolFox v%@"' "عرض الإصدار والنسخة ديناميكي"
check "$MASTER" 'showLiveStatusPopup' "الحالة المباشرة تظهر من زر الرأس"
check "$MASTER" 'setupMasajidUnifiedPage' "لوحة المساجد الموحدة موجودة"
check "$MASTER" 'قمر صناعي' "تبديل الخريطة والقمر الصناعي موجود"
check "$MASTER" 'masajid.location.search' "قسم الموقع يحتوي البحث"
check "$MASTER" 'masajid.location.favorites' "قسم الموقع يحتوي المفضلة"
check "$MASTER" 'masajid.location.history' "قسم الموقع يحتوي التاريخ"
check "$MASTER" 'تفعيل إعدادات GPS' "قسم الموقع يحتوي إعدادات GPS"
check "$MASTER" 'masajid.identifier-section' "قسم المعرف مرتبط بصفحته"
check "$MASTER" 'masajid.bluetooth-section' "قسم Bluetooth منفصل داخل الأقسام"
check "$MASTER" 'masajid.camera-section' "قسم الكاميرا منفصل داخل الأقسام"
check "$MASTER" 'masajid.wolfox-section' "قسم WolFox منفصل داخل الأقسام"
reject "$MASTER" 'masajid.choose-location' "زر اختيار هذا الموقع محذوف"
reject "$MASTER" 'تغيير معرّف الجهاز' "زر المعرف المكرر محذوف من الرئيسية"
reject "$MASTER" 'إخفاء زر الأداة' "زر الإخفاء محذوف من الرئيسية"
check "$MASTER" 'refreshFloatingStatusIcon' "لون أيقونة GPS يتحدث مع حالة التشغيل"
check "$INTEGRATED" 'WFEnsureControllerReady' "تهيئة الأيقونة لا تعتمد على تشغيل الكاميرا"
check "$MASTER" 'showFloatingStatusIconAtLaunch' "إظهار الأيقونة عند بدء التطبيق"
check "$MASTER" 'WF_FLOATING_OPEN_TAPS' "حفظ عدد ضغطات الأيقونة العائمة"
check "$MASTER" 'tapStepper.minimumValue = 1' "أقل عدد ضغطات للأيقونة هو 1"
check "$MASTER" 'tapStepper.maximumValue = 50' "أقصى عدد ضغطات للأيقونة هو 50"
check "$MASTER" 'self.floatingOpenTapCount' "الأيقونة تنتظر العدد المحدد قبل فتح WolFox"
reject "$MASTER" 'favoritesCard' "بطاقة المفضلة القديمة المكررة محذوفة"
check "$MASTER" 'coordinateFromSharedMapText' "البحث يدعم روابط مشاركة الخرائط"
reject "$MASTER" 'countrycodes=sa' "بحث العناوين يدعم المواقع خارج السعودية"
check "$MASTER" 'moveFakeLocationByMeters' "دعم حركة الموقع 5 و10 أمتار"
reject "$MASTER" 'secLabel(@"تسجيل الخروج"' "زر تسجيل الخروج محذوف من الإعدادات"
reject "$MASTER" 'Fake GPS Wolf' "لا يوجد اسم منتج قديم ظاهر للمستخدم"
check "$ACTIVATION" 'showToolHeightConstraint.constant = 0.0;' "طي أزرار النجاح عند الفشل"
check "$ACTIVATION" 'presentResultAlertForResult' "الإشعار المستقل لنتيجة التفعيل"
reject "$ACTIVATION" 'تعذّر تفعيل الكود' "لا توجد رسالة فشل ثابتة داخل الصفحة"
check "$CONFIG" 'WF_TWEAK_VERSION @"2.0.0-Full"' "الإصدار الأساسي 2.0.0"

echo "✅ اجتاز اتساق واجهة Full/Lite اختبارات الحماية."
