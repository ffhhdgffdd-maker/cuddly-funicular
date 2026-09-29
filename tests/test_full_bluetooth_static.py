"""Integration wiring guards; executable Objective-C tests cover state and storage."""
from pathlib import Path
import re
root = Path(__file__).resolve().parent.parent
ui = (root / 'WolFoxMaster.mm').read_text()
hooks = (root / 'WolFoxIntegrated.mm').read_text()
proxy = (root / 'WFBluetoothDelegateProxy.m').read_text()
camera = (root / 'WFVirtualCameraManager.mm').read_text()
assert not re.search(r'\b(?:exit|_exit|abort|kill)\s*\(', ui)
assert '_deliveredProfile' not in hooks
assert 'WFBLEMatchesPeripheral(record, actualIdentifier.UUIDString)' in hooks
assert 'hook_CBCentralManager_setDelegate' in hooks
assert 'setReturnValue:zero.mutableBytes' in proxy
assert 'central != _btManager' in ui
assert '(bluetooth ? WFBLEMaxFileBytes : WFIdentifierTransferMaxBytes) + 1' in ui
assert 'setupSettingsPage' not in ui and 'openSettingsPage' not in ui
assert 'statusBtn' not in ui and '@"crown.fill"' in ui
assert '_titleLabel.text = @"WolFox";' in ui
assert 'chooseRecoveryMethodAndHide:' not in ui and 'applyRecoveryMethod:' not in ui
assert 'UIApplicationUserDidTakeScreenshotNotification' not in ui
assert 'handleFloatingStatusTap:' not in ui and 'handleThreeSequentialTaps:' not in ui
assert '- (void)showUI {' in ui
assert 'self.spoofQuickPanel = [[' not in ui
interface = ui.split('- (void)setupInterfacePage {')[1].split('- (NSArray<UIColor *> *)markerPalette')[0]
assert 'تشغيل الموقع' not in interface and 'Bluetooth' not in interface and 'إعدادات الكاميرا' not in interface
for token in ['WF_RECOVERY_ICON_ENABLED', 'WF_RECOVERY_VOLUME_ENABLED', 'WF_RECOVERY_SCREENSHOT_ENABLED']:
    assert token not in interface, token
assert '@"إخفاء الأداة"' in interface
assert 'WFRecoveryDescription(WFRecoveryVolume)' in interface
bt = ui.split('- (void)setupBluetoothPage {')[1].split('- (void)btProfileDeactivated')[0]
for token in ['tag:8102', 'tag:8120', 'startBTScan', 'importBluetoothFile', 'exportBluetoothFile']:
    assert token in bt, token
assert 'WOLFOX_FEATURE_CAMERA=0' in (root/'build_v1_deb.sh').read_text()
assert 'WFCameraLifecycle.m' not in (root/'build_v1_deb.sh').read_text().split('if [ "${WOLFOX_FEATURE_CAMERA:-0}" = "1" ]')[0]
for token in ['WOLFOX_FEATURE_CAMERA', '#if WOLFOX_FEATURE_CAMERA']:
    assert token in hooks, token
assert 'NSBluetoothAlwaysUsageDescription' in (root/'WFBluetoothScanSession.h').read_text()
print('Feature ownership, real hooks, full-menu recovery and no host-exit wiring guards passed')
