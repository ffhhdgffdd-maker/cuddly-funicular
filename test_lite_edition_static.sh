#!/bin/bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
MASTER="$PROJECT_DIR/WolFoxMaster.mm"
BUILD="$PROJECT_DIR/build_v1_deb.sh"
LITE_BUILD="$PROJECT_DIR/build_lite_deb.sh"
LITE_WORKFLOW="$PROJECT_DIR/.github/workflows/build.yml"

check() { grep -Fq "$2" "$1" || { echo "❌ $3"; exit 1; }; echo "✅ $3"; }
reject() { ! grep -Fq "$2" "$1" || { echo "❌ $3"; exit 1; }; echo "✅ $3"; }

check "$MASTER" "#if WOLFOX_LITE" "وجود واجهة Lite المشروطة"
check "$MASTER" '@[@"location.fill", @"person.text.rectangle.fill", @"slider.horizontal.3"]' "أقسام Lite تشمل التحكم بالواجهة"
check "$MASTER" '@[@"الموقع", @"المعرّف", @"الواجهة والتحكم"]' "خيارات الواجهة مستقلة عن إعدادات الوظائف"
check "$MASTER" "setupInterfacePage" "قسم الواجهة والتحكم متاح"
check "$MASTER" "if (candidate.tag == page)" "تنقل Lite الصحيح بين الأقسام"
check "$MASTER" 'https://nominatim.openstreetmap.org/search' "مصدر بحث احتياطي ثالث"
check "$MASTER" 'خريطة فقط: لا تُحمّل أو تُعرض أيقونات المدارس' "صفحة Lite تعرض الخريطة فقط"
check "$MASTER" '_saudiPlacesPageActive = NO' "إيقاف تحميل المعالم في صفحة الخريطة"
check "$MASTER" 'self.searchBar.placeholder = @"ابحث عن عنوان أو موقع"' "بحث الخريطة عام وليس خاصاً بالمعالم"
reject "$MASTER" 'legendTitle.text = @"🏫 مدرسة' "إزالة لوحة شرح رموز المعالم"
check "$MASTER" "BOOL active = store.spoofActive;" "حالة Lite تعتمد على تزييف الموقع فقط"
check "$BUILD" 'COMMON_FLAGS+=(-DWOLFOX_LITE=1)' "علامة Lite تضاف أثناء الترجمة"
check "$BUILD" 'PACKAGE_ID="com.wolfox.gpspro.lite"' "معرّف تثبيت مستقل لنسخة Lite"
check "$BUILD" '#define WF_TWEAK_VERSION @"$(escape_objc_string "$VERSION")"' "حقن رقم الإصدار حسب عملية البناء"
check "$LITE_BUILD" 'WOLFOX_VERSION="2.0.0-Lite"' "رقم Lite المستقل 2.0.0"
check "$LITE_BUILD" 'exec ./build_v1_deb.sh' "Lite تستخدم نفس مسار المصدر والبناء"

echo "✅ اجتازت بنية WolFox Lite اختبارات الفصل الآمن."
