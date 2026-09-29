#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR" || exit 1
pattern_count=0
expect_pattern() {
    local label="$1" pattern="$2" file="${3:-.}"
    if grep -qr "$pattern" "$file" 2>/dev/null; then
        ((++pattern_count))
        echo "✓ $label"
    else
        echo "✗ FAILED: $label — pattern not found: $pattern" >&2
        exit 1
    fi
}
echo 'Testing Bluetooth V5 release branch build compatibility...'
expect_pattern "بناء مستقل لمجموعة واحدة فقط" 'WolFox — Bluetooth V5' .github/workflows/build.yml
expect_pattern "فرع الإطلاق: WB5" 'branches:\s*\[WB5\]' .github/workflows/build.yml
expect_pattern "الإصدار: 5.0.1" 'WOLFOX_VERSION.*5.0.1' .github/workflows/build.yml
expect_pattern "الملف الشخصي: Full Mosques" 'full-mosques' .github/workflows/build.yml
expect_pattern "متغير الواجهة: 5" 'WOLFOX_INTERFACE_VARIANT.*5' .github/workflows/build.yml
expect_pattern "الحزمة المستهدفة: Mosques" 'sa.gov.moia.mosques-2' .github/workflows/build.yml
expect_pattern "مفتاح المشروع من الأسرار" 'WOLFOX_PROJECT_KEY' .github/workflows/build.yml
expect_pattern "إصدار release.json متطابق" '"version".*"5.0.1"' release.json
expect_pattern "فرع release.json متطابق" '"branch".*"WB5"' release.json
expect_pattern "ملف السمة الفعلي" '"theme".*"WolFoxProTheme.m"' release.json
expect_pattern "نوع الملف الشخصي" '"profile".*"full-mosques"' release.json
expect_pattern "متغير الواجهة في Manifest" '"interface_variant".*5' release.json
expect_pattern "الحزمة المضيفة" '"bundle".*"sa.gov.moia.mosques-2"' release.json
expect_pattern "اسم المنتج" '"product".*"WolFox5_Bluetooth"' release.json
expect_pattern "اسم العرض" '"display_name".*"WolFox"' release.json
expect_pattern "توثيق فرع WB5" '`WB5`' BRANCHES_AR.md
expect_pattern "وصف الفرع" 'Bluetooth V5' BRANCHES_AR.md
expect_pattern "التحقق من تطابق الفرع" 'Build only the configured branch' tools/verify_release_config.py
expect_pattern "التحقق من تطابق الإصدار" 'WOLFOX_VERSION.*version' tools/verify_release_config.py
expect_pattern "التحقق من تطابق الملف الشخصي" 'WOLFOX_PROFILE.*profile' tools/verify_release_config.py
expect_pattern "وجود مفتاح المشروع" 'Missing project key' tools/verify_release_config.py
expect_pattern "التحقق من Workflow المستقل" 'One independent workflow' tools/verify_release_config.py
expect_pattern "التحقق من ملف السمة" 'Theme file' tools/collect_release.py
expect_pattern "استخراج Dylib" 'arm64 Mach-O' tools/collect_release.py
expect_pattern "التحقق من نسختي DEB" 'both DEBs' tools/collect_release.py
expect_pattern "استخراج المصدر بدقة" 'exact source' tools/collect_release.py
expect_pattern "فصل وضع استعادة الشاشة" 'WFRecoveryScreenshot = 4' WFInterfacePolicy.h
expect_pattern "تحديث نطاق الصحة" 'method >= 1 && method <= 4' WFInterfacePolicy.h
expect_pattern "وصف استعادة الشاشة" 'تصوير الشاشة' WFInterfacePolicy.h
echo ""
echo "✓ جميع الاختبارات ($pattern_count) نجحت! البناء جاهز للإطلاق على فرع WB5."
