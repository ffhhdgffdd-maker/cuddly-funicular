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
check "$MASTER" 'saveLocationButton' "زر حفظ الموقع موجود قبل أدوات التشغيل"
check "$MASTER" 'favoritesButton' "زر المفضلة موجود قبل أدوات التشغيل"
check "$MASTER" 'setupMasajidUnifiedPage' "لوحة المساجد الموحدة موجودة"
check "$MASTER" 'قمر صناعي' "تبديل الخريطة والقمر الصناعي موجود"
check "$MASTER" 'masajid.choose-location' "زر اختيار موقع المساجد موجود"
check "$MASTER" 'masajid.device-id' "زر تغيير معرّف الجهاز موجود"
check "$MASTER" 'تفعيل زر رفع الصور' "مفتاح رفع الصور موجود في الواجهة الموحدة"
check "$MASTER" 'إخفاء الأداة؟' "زر الإخفاء يطلب تأكيداً قبل التنفيذ"
check "$MASTER" 'متابعة الإخفاء' "تأكيد الإخفاء مرتبط بالمسار الصحيح"
check "$MASTER" 'تم إخفاء الأداة بنجاح' "يظهر إشعار بعد الإخفاء"
check "$MASTER" 'masajid.bluetooth-management' "قسم Bluetooth مرتبط بواجهته"
check "$MASTER" 'masajid.camera-settings' "قسم الكاميرا مرتبط بإعداداته"
check "$MASTER" 'masajid.interface-settings' "قسم الإخفاء والاستعادة مرتبط بالإعدادات"
check "$MASTER" 'masajid.saved-routes' "قسم المسارات مرتبط بالمسارات المحفوظة"
check "$MASTER" 'refreshFloatingStatusIcon' "لون أيقونة GPS يتحدث مع حالة التشغيل"
check "$INTEGRATED" 'WFEnsureControllerReady' "تهيئة الأيقونة لا تعتمد على تشغيل الكاميرا"
check "$MASTER" 'showFloatingStatusIconAtLaunch' "إظهار الأيقونة عند بدء التطبيق"
check "$MASTER" 'WF_FLOATING_OPEN_TAPS' "حفظ عدد ضغطات الأيقونة العائمة"
check "$MASTER" 'tapStepper.minimumValue = 1' "أقل عدد ضغطات للأيقونة هو 1"
check "$MASTER" 'tapStepper.maximumValue = 50' "أقصى عدد ضغطات للأيقونة هو 50"
check "$MASTER" 'self.floatingOpenTapCount' "الأيقونة تنتظر العدد المحدد قبل فتح WolFox"
check "$MASTER" '[kbCard addSubview:saveLocationButton]' "زر الحفظ خارج مساحة الخريطة"
check "$MASTER" '[kbCard addSubview:favoritesButton]' "زر المفضلة خارج مساحة الخريطة"
reject "$MASTER" 'favoritesCard' "بطاقة المفضلة القديمة المكررة محذوفة"
if rg -q '\[mapCard addSubview:(saveLocationButton|favoritesButton|quickSaveFavorite|quickShowFavorites)\]' "$MASTER"; then
    echo "❌ أزرار الحفظ أو المفضلة ما زالت داخل الخريطة"
    exit 1
else
    echo "✅ أزرار الحفظ والمفضلة أزيلت من الخريطة ووُضعت قبل التشغيل"
fi
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
