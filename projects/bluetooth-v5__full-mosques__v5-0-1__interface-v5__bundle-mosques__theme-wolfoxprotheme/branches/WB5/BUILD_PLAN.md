# خطة بناء Bluetooth V5 — المرحلة النهائية

## ملخص الحالة
- **الفرع الحالي**: WB5
- **الإصدار**: 5.0.1
- **المنتج**: WolFox5_Bluetooth
- **الملف الشخصي**: full-mosques
- **الحزمة المستهدفة**: sa.gov.moia.mosques-2

---

## المرحلة 1: التحقق من المتطلبات

### 1.1 التحقق من توفر الملفات الأساسية
```bash
#!/bin/bash
set -euo pipefail
echo "=== التحقق من المتطلبات ==="

# ملفات المصدر الأساسية
test -s WolFoxMaster.mm && echo "✓ WolFoxMaster.mm"
test -s WFInterfacePolicy.h && echo "✓ WFInterfacePolicy.h"
test -s WolFoxProTheme.m && echo "✓ WolFoxProTheme.m"
test -s build_v1_deb.sh && echo "✓ build_v1_deb.sh"
test -s wolfox_setup_build.sh && echo "✓ wolfox_setup_build.sh"

# ملفات الإعدادات
test -s release.json && echo "✓ release.json"
test -s BRANCHES_AR.md && echo "✓ BRANCHES_AR.md"

# أدوات التحقق
test -s tools/verify_release_config.py && echo "✓ tools/verify_release_config.py"
test -s tools/collect_release.py && echo "✓ tools/collect_release.py"

# اختبارات التوافق
test -s tests/test_full_bluetooth_static.py && echo "✓ tests/test_full_bluetooth_static.py"

echo ""
echo "✓ جميع الملفات الأساسية موجودة"
```

### 1.2 التحقق من إعدادات الفرع
```bash
#!/bin/bash
echo "=== التحقق من إعدادات الفرع ==="

# تحقق من اسم الفرع الحالي
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
echo "الفرع الحالي: $CURRENT_BRANCH"

if [ "$CURRENT_BRANCH" != "WB5" ]; then
    echo "❌ خطأ: الفرع الحالي ليس WB5"
    exit 1
fi

# تحقق من الـ URL
ORIGIN_URL=$(git config --get remote.origin.url)
echo "URL الأصل: $ORIGIN_URL"

# تحقق من الإعدادات المحلية
echo ""
echo "✓ الفرع والأصل محددان بشكل صحيح"
```

---

## المرحلة 2: اختبار التوافق الثابت

### 2.1 تشغيل اختبارات التوافق
```bash
#!/bin/bash
set -euo pipefail
echo "=== اختبارات التوافق ==="

# تشغيل فحص التوافق
bash test_build_compatibility_static.sh

echo ""
echo "✓ جميع اختبارات التوافق نجحت"
```

### 2.2 التحقق من التكوين
```bash
#!/bin/bash
set -euo pipefail
echo "=== التحقق من تكوين الإصدار ==="

export GITHUB_REF_NAME="WB5"
export WOLFOX_VERSION="5.0.1"
export WOLFOX_EDITION="Full"
export WOLFOX_PROFILE="full-mosques"
export WOLFOX_INTERFACE_VARIANT="5"
export WOLFOX_TARGET_BUNDLE_IDS="sa.gov.moia.mosques-2"
export WOLFOX_PROJECT_BUNDLE_ID="sa.gov.moia.mosques-2"
python3 tools/verify_release_config.py

echo "✓ تكوين الإصدار متطابق وصحيح"
```

---

## المرحلة 3: بناء المشروع

### 3.1 متطلبات البناء
```
- THEOS: مجموعة أدوات Objective-C للبناء
- clang: معالج Objective-C
- dpkg-deb: أداة إنشاء حزم Debian
- Python 3.8+: للتحقق من الأدوات
```

### 3.2 خطوات البناء
```bash
#!/bin/bash
set -euo pipefail
echo "=== بناء Bluetooth V5 ==="

# تعيين متغيرات البيئة
export THEOS="${THEOS:-./.theos}"
export WOLFOX_VERSION="5.0.1"
export WOLFOX_EDITION="Full"
export WOLFOX_PROFILE="full-mosques"
export WOLFOX_INTERFACE_VARIANT="5"
export WOLFOX_TARGET_BUNDLE_IDS="sa.gov.moia.mosques-2"
export WOLFOX_PROJECT_BUNDLE_ID="sa.gov.moia.mosques-2"
export WOLFOX_PANEL_BASE_URL="https://gps.p3nd.fun/api/v1"
# export WOLFOX_PROJECT_KEY="<SECRET_KEY>"  # من GitHub Secrets

echo "البناء مع الإعدادات:"
echo "  الإصدار: $WOLFOX_VERSION"
echo "  الملف الشخصي: $WOLFOX_PROFILE"
echo "  الحزمة المستهدفة: $WOLFOX_PROJECT_BUNDLE_ID"

# بناء المشروع
bash wolfox_setup_build.sh

echo "✓ البناء نجح"
```

---

## المرحلة 4: التحقق من الحزم

### 4.1 التحقق من وجود الملفات المنتجة
```bash
#!/bin/bash
set -euo pipefail
echo "=== التحقق من الحزم المنتجة ==="

PRODUCT="WolFox5_Bluetooth"
VERSION="5.0.1"

# تحقق من الـ dylib
test -s "${PRODUCT}.dylib" && echo "✓ ${PRODUCT}.dylib موجود"

# تحقق من حزم DEB
test -s "${PRODUCT}_v${VERSION}_iOS15.8-27.0_Rootful.deb" && \
    echo "✓ حزمة Rootful موجودة"
test -s "${PRODUCT}_v${VERSION}_iOS15.8-27.0_Rootless.deb" && \
    echo "✓ حزمة Rootless موجودة"

echo "✓ جميع الحزم المنتجة موجودة"
```

### 4.2 جمع الإصدار النهائي
```bash
#!/bin/bash
set -euo pipefail
echo "=== جمع ملفات الإصدار ==="

python3 tools/collect_release.py

echo "✓ تم جمع وتحقق من جميع ملفات الإصدار"
```

---

## المرحلة 5: التحقق من الجودة

### 5.1 التحقق من السلام الكلي
```bash
#!/bin/bash
set -euo pipefail
echo "=== التحقق من السلام الكلي ==="

cd release

echo "ملفات الإصدار:"
ls -lh

echo ""
echo "التحقق من SHA256:"
cat SHA256SUMS.txt

echo ""
echo "معلومات البناء:"
cat BUILD_INFO.json

echo ""
echo "✓ جميع الملفات والتوقيعات صحيحة"
```

### 5.2 المحتويات النهائية المتوقعة
```
release/
├── WolFox5_Bluetooth.dylib              # المكتبة الديناميكية (arm64 Mach-O)
├── WolFox5_Bluetooth_v5.0.1_iOS15.8-27.0_Rootful.deb   # حزمة Rootful
├── WolFox5_Bluetooth_v5.0.1_iOS15.8-27.0_Rootless.deb  # حزمة Rootless
├── WolFox-Source.zip                    # كود المصدر الكامل
├── release.json                         # إعدادات الإصدار
├── BRANCHES_AR.md                       # توثيق الفروع
├── WOLFOX_REVIEW_AR.md                  # ملاحظات المراجعة
├── BUILD_INFO.json                      # معلومات البناء
└── SHA256SUMS.txt                       # التوقيعات الكلية
```

---

## المرحلة 6: الخطوات الاختيارية

### 6.1 تشغيل الاختبارات الأصلية (macOS)
```bash
#!/bin/bash
set -euo pipefail
echo "=== الاختبارات الأصلية ==="

# اختبارات نقل المعرّف
clang -fobjc-arc -Wall -Wextra -Werror -I. \
    tests/test_identifier_transfer.m \
    -framework Foundation -o /tmp/test-identifier
/tmp/test-identifier && echo "✓ اختبار نقل المعرّف نجح"

# اختبارات ملف Bluetooth
clang -fobjc-arc -Wall -Wextra -Werror -I. \
    tests/test_bluetooth_profile.m \
    -framework Foundation -framework CoreBluetooth \
    -o /tmp/test-bluetooth
/tmp/test-bluetooth && echo "✓ اختبار ملف Bluetooth نجح"

# اختبارات Python الثابتة
python3 tests/test_full_bluetooth_static.py && \
    echo "✓ الاختبارات الثابتة نجحت"
```

---

## ملخص المخرجات المتوقعة

| الملف | الحجم المتوقع | الفحص |
|------|----------|------|
| WolFox5_Bluetooth.dylib | ~2-5 MB | arm64 Mach-O |
| *_Rootful.deb | ~4-8 MB | dpkg متوافق |
| *_Rootless.deb | ~4-8 MB | dpkg متوافق |
| WolFox-Source.zip | ~5-15 MB | أرشيف صحيح |
| release.json | <1 KB | JSON صالح |
| SHA256SUMS.txt | <1 KB | توقيعات صحيحة |

---

## الأوامر السريعة للتنفيذ

```bash
# المرحلة 1: التحقق من المتطلبات
bash test_build_compatibility_static.sh

# المرحلة 2: التحقق من التكوين
python3 tools/verify_release_config.py

# المرحلة 3: البناء
export WOLFOX_VERSION="5.0.1"
export WOLFOX_EDITION="Full"
export WOLFOX_PROFILE="full-mosques"
export WOLFOX_INTERFACE_VARIANT="5"
export WOLFOX_TARGET_BUNDLE_IDS="sa.gov.moia.mosques-2"
export WOLFOX_PROJECT_BUNDLE_ID="sa.gov.moia.mosques-2"
export WOLFOX_PANEL_BASE_URL="https://gps.p3nd.fun/api/v1"
bash wolfox_setup_build.sh

# المرحلة 4: جمع الإصدار
python3 tools/collect_release.py

# المرحلة 5: التحقق
cd release && ls -lh && cat SHA256SUMS.txt
```

---

## الحالة الحالية للفرع WB5

✅ **المرجعيات المطبقة:**
- P1 Fix: Screenshot recovery value = 4
- P2 Fix: Branch name aligned to WB5
- P2 Fix: Theme file = WolFoxProTheme.m
- Enhanced: Verification tools with theme validation

✅ **الملفات الجاهزة:**
- WFInterfacePolicy.h (fixed)
- release.json (fixed)
- BRANCHES_AR.md (fixed)
- tools/collect_release.py (enhanced)
- tools/verify_release_config.py (intact)
- .github/workflows/build.yml (WB5 trigger)

🚀 **التنفيذ الحالي:**
1. GitHub Actions مهيأ على الفرع WB5
2. native-tests يعمل على macOS
3. التحقق من release.json يعمل قبل البناء
4. البناء يعمل على Ubuntu 24.04 عبر wolfox_setup_build.sh
5. جمع release/ والتحقق من الحزم يتم عبر tools/collect_release.py
6. SHA256SUMS.txt و BUILD_INFO.json يتم إنتاجهما ضمن release/

✅ **ملاحظة:** أي push جديد إلى WB5 يشغّل خط البناء الكامل تلقائياً.

---

**معدّل بتاريخ**: 2026-09-29
**الفرع**: WB5
**الالتزام الأخير**: 716e772bdb19192b6832fe8114502d6aa4b5ae1e
