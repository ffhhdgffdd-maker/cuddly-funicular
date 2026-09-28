#!/bin/bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
MASTER="$PROJECT_DIR/WolFoxMaster.mm"
LICENSE_HEADER="$PROJECT_DIR/WFLicenseClient.h"
LICENSE_IMPL="$PROJECT_DIR/WFLicenseClient.m"
ACTIVATION="$PROJECT_DIR/WFActivationViewController.m"

check() { grep -Fq -- "$2" "$1" || { echo "❌ $3"; exit 1; }; echo "✅ $3"; }
reject() { if grep -Fq "$2" "$1"; then echo "❌ $3"; exit 1; fi; echo "✅ $3"; }

check "$MASTER" '- (void)refreshGPSStatusBadge' "مُحدّث حالة GPS موجود"
check "$MASTER" 'BOOL enabled = [WolFoxProStore shared].spoofActive;' "لون GPS مرتبط بتشغيل تغيير الموقع"
check "$MASTER" 'enabled ? [WolFoxProTheme success] : [WolFoxProTheme danger]' "GPS أخضر عند التشغيل وأحمر عند الإيقاف"
check "$MASTER" '[self refreshGPSStatusBadge];' "تحديث GPS يحدث مع تحديث حالة الأداة"
check "$MASTER" 'UIButton *saveLocationButton = [self mapCircleBtn:@"bookmark.fill"' "حفظ الموقع إجراء خريطة مضغوط"
check "$MASTER" 'UIView *fileActions' "استيراد وتصدير Bluetooth في صف واحد"
reject "$MASTER" 'royalBtnInside:_scrollDashboard t:@"استيراد ملف بلوتوث"' "تكديس استيراد Bluetooth أزيل"
reject "$MASTER" 'royalBtnInside:_scrollDashboard t:@"تصدير الجهاز المختار"' "تكديس تصدير Bluetooth أزيل"
check "$MASTER" 'CGFloat gridY = 208;' "إجراءات المعرّف في شبكة مضغوطة"
reject "$MASTER" 'royalBtnInside:idCard' "تكديس أزرار المعرّف أزيل"
reject "$MASTER" 'UIButton *delete =' "لا يُستخدم اسم C++ المحجوز لأزرار المعرّف"
reject "$MASTER" 'UIButton *export =' "لا يُستخدم اسم C++ المحجوز لتصدير المعرّف"
check "$MASTER" 'if (hide && WFRecoveryMethodValid(savedMethod))' "الإخفاء يستخدم طريقة الاستعادة المحفوظة مباشرة"
reject "$MASTER" 'UIAlertController *saved' "رسالة حفظ الإخفاء المكررة أزيلت"
check "$MASTER" '[self showToast:@"تم حفظ التغيير وتطبيقه"];' "تأكيد التغيير يعرض رسالة واحدة"
check "$LICENSE_HEADER" '+ (void)storeActivationDraftCode:(NSString *)code;' "واجهة حفظ مسودة التفعيل موجودة"
check "$LICENSE_IMPL" 'kPendingActivationCodeKey' "مسودة التفعيل محفوظة في Keychain"
check "$LICENSE_IMPL" '[self deleteKeychainKey:kPendingActivationCodeKey];' "المسودة تُحذف فقط بعد تفعيل ناجح"
check "$ACTIVATION" '[WFLicenseClient storedActivationDraftCode]' "حقل التفعيل يعيد آخر مسودة محفوظة"
check "$ACTIVATION" '[WFLicenseClient storeActivationDraftCode:normalized];' "كل إدخال غير فارغ يُحفظ قبل التحقق"

python3 - "$MASTER" <<'PY'
from pathlib import Path
import sys
source = Path(sys.argv[1]).read_text()
assert source.count('- (void)setupVirtualCameraCardAtY:') == 1, 'duplicate virtual camera card implementation'
assert source.count('- (void)setupGPSPage {') == 1, 'duplicate GPS page implementation'
assert source.count('- (void)setupIDPage {') == 1, 'duplicate identifier page implementation'
print('✅ لا توجد تعريفات أقسام مكررة')
PY

echo "✅ اجتازت واجهة WolFox Maps الموحدة اختبارات الحماية."
