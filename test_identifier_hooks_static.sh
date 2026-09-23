#!/bin/bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$PROJECT_DIR"

PASS=0
FAIL=0

expect_pattern() {
    local label="$1"
    local pattern="$2"
    shift 2
    if rg -q -- "$pattern" "$@"; then
        echo "✅ $label"
        PASS=$((PASS + 1))
    else
        echo "❌ $label"
        FAIL=$((FAIL + 1))
    fi
}

expect_pattern "تثبيت هوك IDFA" '@selector\(advertisingIdentifier\)' WolFoxIntegrated.mm
expect_pattern "تثبيت هوك IDFV" '@selector\(identifierForVendor\)' WolFoxIntegrated.mm
expect_pattern "مصدر UUID موحد للهوكات" 'WFActivePublicIdentifier' WolFoxIntegrated.mm
expect_pattern "WebView يستخدم نفس UUID" 'window\.wolfoxIdentifier' WolFoxIntegrated.mm
expect_pattern "WebView مستقل عن مفتاح GPS" 'activeIdentifier = WFActivePublicIdentifier' WolFoxIntegrated.mm
expect_pattern "التحقق المركزي من UUID" 'validatedActiveIdentifier' WolFoxProStore.h WolFoxProStore.m
expect_pattern "رفض UUID غير صالح" 'if \(!uuid\) return NO' WolFoxProStore.m
expect_pattern "حفظ UUID النشط" 'WF_PRO_ACTIVE_ID' WolFoxProStore.m
expect_pattern "حفظ ربط UUID بالتطبيق" 'WF_PRO_ACTIVE_ID_BUNDLE' WolFoxProStore.m
expect_pattern "ربط الهوية بتطبيق المساجد" 'sa[.]gov[.]moia[.]mosques-2' WolFoxProStore.m WolFoxMaster.mm
expect_pattern "تطبيق UUID حسب Bundle ID" 'currentBundleID.*boundBundleID|isEqualToString:boundBundleID' WolFoxProStore.m
expect_pattern "شاشة منسوبي المساجد تربط المعرّف بالتطبيق المحدد" 'activateIdentifierString:uuid[.]UUIDString forBundleID:@"sa[.]gov[.]moia[.]mosques-2"' WolFoxMaster.mm
expect_pattern "واجهة التفعيل تستخدم الربط الصريح" 'activateIdentifierString:normalizedUUID[.]UUIDString forBundleID:' WolFoxMaster.mm
expect_pattern "إيقاف الهوية الموحدة" 'deactivateIdentifier' WolFoxProStore.h WolFoxProStore.m WolFoxMaster.mm
expect_pattern "واجهة توضح الأنواع المدمجة" 'IDFA • IDFV • Web' WolFoxMaster.mm
expect_pattern "إظهار قسم المعرّف في Full وLite" 'person[.]text[.]rectangle[.]fill' WolFoxMaster.mm
expect_pattern "إظهار ونسخ UDID الجهاز" 'copyDeviceUDID|UDID الجهاز' WolFoxMaster.mm

echo "النتيجة: $PASS ناجح، $FAIL فاشل"
if [ "$FAIL" -ne 0 ]; then
    exit 1
fi
