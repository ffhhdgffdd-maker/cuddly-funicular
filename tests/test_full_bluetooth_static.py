"""Regression guards for integration behavior that needs an iOS host at runtime."""
from pathlib import Path
import re
root = Path(__file__).resolve().parent.parent
ui = (root / 'WolFoxMaster.mm').read_text()
hooks = (root / 'WolFoxIntegrated.mm').read_text()
assert not re.search(r'\b(?:exit|_exit|abort|kill)\s*\(', ui)
assert '_deliveredProfile' not in hooks, 'Do not suppress later scan callbacks'
assert 'WFBLEMatchesPeripheral(record, actualIdentifier.UUIDString)' in hooks
assert 'hook_CBCentralManager_setDelegate' in hooks
assert 'setReturnValue:zero.mutableBytes' in hooks
assert '_btScanGeneration == generation' in ui
assert 'central != _btManager' in ui
assert '(bluetooth ? WFBLEMaxFileBytes : WFIdentifierTransferMaxBytes) + 1' in ui
assert 'WFInterfaceNeedsFallback' in ui
assert 'UIAccessibilityAnnouncementNotification, hint.text' in ui

# Interface/settings requirements for the two independent Full variants.
assert '#if WOLFOX_INTERFACE_VARIANT == 4' in ui
assert '#if WOLFOX_INTERFACE_VARIANT == 5' in ui
assert 'componentNames = @[@"تشغيل الموقع", @"تشغيل المعرّف", @"تشغيل البلوتوث", @"تشغيل الكاميرا", @"تشغيل الجدولة"]' in ui
assert 't:@"الأيقونة العائمة والمنيو"' not in ui  # title is a label, not a duplicated action
assert 'interfaceTitle.text = @"الأيقونة العائمة والمنيو";' in ui
assert 'pressCount.hidden = YES;' in ui
assert 't:@"الاستعادة بثلاث نقرات"' in ui
assert 'WF_MENU_TRIPLE_TAP_ENABLED' in ui
assert 'WF_FLOATING_STATUS_VISIBLE' in ui
assert 'WF_VOLUME_PRESS_COUNT' in ui
assert 'requestApplicationExit {\n    [[WolFoxController shared] dismissUI];\n}' in ui
assert 'سيُطبّق التغيير داخل الأداة بعد التأكيد.' in ui
assert 'تم حفظ التغيير وتطبيقه داخل الأداة.' in ui

print('Bluetooth and interface/settings integration guards passed')
