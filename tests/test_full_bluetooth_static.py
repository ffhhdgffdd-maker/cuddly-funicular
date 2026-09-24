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
assert 'chooseRecoveryMethodAndHide:YES' in ui and 'applyRecoveryMethod:method' in ui
assert '- (void)toggleSpoofQuickPanel:(__unused UIButton *)sender { [self showUI]; }' in ui
assert 'self.spoofQuickPanel = [[' not in ui
interface = ui.split('- (void)setupInterfacePage {')[1].split('- (void)changeRecoveryMethod')[0]
assert 'تشغيل الموقع' not in interface and 'Bluetooth' not in interface and 'إعدادات الكاميرا' not in interface
assert 'اختيار طريقة الإخفاء والاستعادة' in interface
bt = ui.split('- (void)setupBluetoothPage {')[1].split('- (void)btProfileDeactivated')[0]
for token in ['tag:8102', 'tag:8120', 'startBTScan', 'importBluetoothFile', 'exportBluetoothFile']:
    assert token in bt, token
assert 'shouldShowPickerIcon' in ui and 'previewIsVisible' in camera
for token in ['WFPhotoDelegateForCapture', 'WFTrackPhotoUploadTask', 'hook_AVCaptureSession_stopRunning']:
    assert token in hooks, token
assert 'NSBluetoothAlwaysUsageDescription' in (root/'WFBluetoothScanSession.h').read_text()
print('Feature ownership, real hooks, full-menu recovery and no host-exit wiring guards passed')
