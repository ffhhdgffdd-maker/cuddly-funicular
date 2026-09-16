#!/bin/bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
MASTER="$PROJECT_DIR/WolFoxMaster.mm"
BUILD="$PROJECT_DIR/build_v1_deb.sh"
LITE_BUILD="$PROJECT_DIR/build_lite_deb.sh"
LITE_WORKFLOW="$PROJECT_DIR/.github/workflows/build.yml"

check() { grep -Fq "$2" "$1" || { echo "❌ $3"; exit 1; }; echo "✅ $3"; }

check "$MASTER" "#if WOLFOX_LITE" "وجود واجهة Lite المشروطة"
check "$MASTER" '@[@"location.fill", @"gearshape.fill"]' "Lite تعرض الخريطة والإعدادات دون ازدحام"
check "$MASTER" '@[@"الخريطة والبحث", @"الإعدادات"]' "توضيح أقسام Lite المبسطة"
check "$MASTER" "if (candidate.tag == page)" "تنقل Lite الصحيح بين الأقسام"
check "$MASTER" 'showSaudiServicesOnMainMap' "دمج المدارس والمساجد والخدمات الصحية في الخريطة الرئيسية"
check "$MASTER" 'https://overpass-api.de/api/interpreter' "مصدر OpenStreetMap للمعالم"
check "$MASTER" 'https://overpass.kumi.systems/api/interpreter' "مزود احتياطي أول لمعالم الخريطة"
check "$MASTER" 'https://overpass.nchc.org.tw/api/interpreter' "مزود احتياطي ثانٍ لمعالم الخريطة"
check "$MASTER" 'https://nominatim.openstreetmap.org/search' "مصدر بحث احتياطي ثالث"
check "$MASTER" 'school ? @"🏫" : (mosque ? @"🕌"' "رموز واضحة للمدارس والمساجد"
check "$MASTER" 'WFSaudiPlaceKindHealthCenter' "دعم المستوصفات والمراكز الصحية"
check "$MASTER" 'WFSaudiPlaceKindGovernmentHospital' "دعم المستشفيات الحكومية والعامة"
check "$MASTER" 'healthCenter ? @"🏥" : @"H"' "رموز صحية واضحة ومختلفة"
check "$MASTER" 'marker.clusteringIdentifier' "تجميع المعالم للحفاظ على الأداء"
check "$MASTER" "BOOL active = store.spoofActive;" "حالة Lite تعتمد على تزييف الموقع فقط"
check "$BUILD" 'COMMON_FLAGS+=(-DWOLFOX_LITE=1)' "علامة Lite تضاف أثناء الترجمة"
check "$BUILD" 'PACKAGE_ID="com.wolfox.gpspro.lite"' "معرّف تثبيت مستقل لنسخة Lite"
check "$BUILD" '#define WF_TWEAK_VERSION @"$(escape_objc_string "$VERSION")"' "حقن رقم الإصدار حسب عملية البناء"
check "$LITE_BUILD" 'WOLFOX_VERSION="2.0.0-Lite"' "رقم Lite المستقل 2.0.0"
check "$LITE_BUILD" 'exec ./build_v1_deb.sh' "Lite تستخدم نفس مسار المصدر والبناء"
check "$LITE_WORKFLOW" 'WOLFOX_PANEL_BASE_URL: https://gps.p3nd.fun/api/v1' "رابط لوحة المشروع موحد"
check "$LITE_WORKFLOW" 'WolFox-2.0.0-Full-and-Lite-Deploy.zip' "إنشاء حزمة Deploy موحدة"
check "$LITE_WORKFLOW" 'BUILD_INFO.txt' "إنشاء معلومات البناء المرجعية"
check "$LITE_WORKFLOW" 'SHA256SUMS.txt' "إنشاء بصمات الإصدار النهائية"
check "$LITE_WORKFLOW" 'git archive --format=tar.gz' "إرفاق السورس المطابق للبناء"

echo "✅ اجتازت بنية WolFox Lite اختبارات الفصل الآمن."
