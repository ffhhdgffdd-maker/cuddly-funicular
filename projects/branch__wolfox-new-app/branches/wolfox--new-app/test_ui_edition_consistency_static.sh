#!/bin/bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
MASTER="$PROJECT_DIR/WolFoxMaster.mm"
ACTIVATION="$PROJECT_DIR/WFActivationViewController.m"
CONFIG="$PROJECT_DIR/WFLicenseConfig.h"

check() { grep -Fq "$2" "$1" || { echo "❌ $3"; exit 1; }; echo "✅ $3"; }
reject() { if grep -Fq "$2" "$1"; then echo "❌ $3"; exit 1; fi; echo "✅ $3"; }

if grep -Fq '_titleLabel.text = @"WolFox";' "$MASTER"; then
    echo "✅ اسم WolFox الأساسي متاح مع اسم الإصدار"
else
    echo "❌ اسم WolFox الأساسي غير موجود"; exit 1
fi
reject "$MASTER" '@"الكاميرا", @"الإعدادات"' "تبويب الكاميرا لم يُخف من الواجهة"
check "$MASTER" 'NSString *onboardingEdition = @"WolFox";' "عداد الجولة يعرض Lite الصحيح"
check "$MASTER" 'displayVersion = [NSString stringWithFormat:@"WolFox v%@"' "عرض الإصدار والنسخة ديناميكي"
check "$MASTER" 'showLiveStatusPopup' "الحالة المباشرة تظهر من زر الرأس"
check "$MASTER" 'UIButton *saveLocationButton = [self mapCircleBtn:@"bookmark.fill"' "حفظ الموقع أصبح إجراء خريطة مضغوطاً"
check "$MASTER" 'mapsActionButtonIn:actionsRow title:@"المفضلة"' "المفضلة ضمن صف الإجراءات الموحد"
check "$MASTER" 'mapsActionButtonIn:actionsRow title:@"ابحث عن موقع"' "البحث ضمن صف الإجراءات الموحد"
reject "$MASTER" 'UIView *kbCard' "بطاقة الإجراءات العمودية القديمة أزيلت"
reject "$MASTER" 'favoritesCard' "بطاقة المفضلة القديمة المكررة أزيلت"
check "$MASTER" 'coordinateFromSharedMapText' "البحث يدعم روابط مشاركة الخرائط"
reject "$MASTER" 'countrycodes=sa' "بحث العناوين يدعم المواقع خارج السعودية"
check "$MASTER" 'moveFakeLocationByMeters' "دعم حركة الموقع 5 و10 أمتار"
reject "$MASTER" 'secLabel(@"تسجيل الخروج"' "زر تسجيل الخروج محذوف من الإعدادات"
reject "$MASTER" 'Fake GPS Wolf' "لا يوجد اسم منتج قديم ظاهر للمستخدم"
check "$ACTIVATION" 'showToolHeightConstraint.constant = 0.0;' "طي أزرار النجاح عند الفشل"
check "$ACTIVATION" 'presentResultAlertForResult' "الإشعار المستقل لنتيجة التفعيل"
reject "$ACTIVATION" 'تعذّر تفعيل الكود' "لا توجد رسالة فشل ثابتة داخل الصفحة"
check "$CONFIG" 'WF_TWEAK_VERSION @"2.0.0-Full"' "الإصدار الأساسي 2.0.0"

echo "✅ اجتاز اتساق واجهة WolFox Maps اختبارات الحماية."
