"""Integration wiring guards; executable Objective-C tests cover state and storage."""
from pathlib import Path
import re
root = Path(__file__).resolve().parent.parent
ui = (root / 'WolFoxMaster.mm').read_text()
hooks = (root / 'WolFoxIntegrated.mm').read_text()
proxy = (root / 'WFBluetoothDelegateProxy.m').read_text()
camera = (root / 'WFVirtualCameraManager.mm').read_text()
selectors = set(re.findall(r'@selector\((\w+):?\)', ui))
methods = set(re.findall(r'^[-+]\s*\([^)]*\)\s*(\w+)', ui, re.M))
assert not selectors - methods, f'Unimplemented UI actions: {sorted(selectors - methods)}'
assert not re.search(r'\b(?:exit|_exit|abort|kill)\s*\(', ui)
assert '_deliveredProfile' not in hooks
assert 'WFBLEMatchesPeripheral(record, actualIdentifier.UUIDString)' in hooks
assert 'hook_CBCentralManager_setDelegate' in hooks
assert 'setReturnValue:zero.mutableBytes' in proxy
assert 'central != _btManager' in ui
assert '(bluetooth ? WFBLEMaxFileBytes : WFIdentifierTransferMaxBytes) + 1' in ui
assert 'setupSettingsPage' not in ui and 'openSettingsPage' not in ui
assert 'statusBtn' not in ui
header = ui.split('// Header contains only')[1].split('// 2. Top Tabs Bar')[0]
assert header.count('[UIButton buttonWithType:') == 1
assert '@selector(requestHideTool)' in header
assert 'versionLabel' in header and '_spoofStatusLabel' in header
status = ui.split('- (void)refreshSpoofHeaderStatus {')[1].split('- (void)tabBtnPressed:')[0]
assert 'isRuntimeLicenseValid' in status and 'bluetoothActive' not in status
gps = ui.split('- (void)setupGPSPage {')[1].split('#pragma mark - Unified virtual camera')[0]
assert 'Bluetooth' not in gps and 'tag:8102' not in gps
assert 'اختيار هذا الموقع' not in ui
assert 'handleMapTap:' in gps and 'showLocationHistory' in gps
assert 'updateIntervalChanged:' in gps
assert 'NSArray *tabPages = @[@0, @1, @4];' in ui  # New design has three primary sections.
assert '- (void)openBluetoothTool { [self switchPage:2]; }' in ui  # Bluetooth remains reachable from Tools.
assert '- (void)openCameraTool { [self switchPage:3]; }' in ui  # Camera remains reachable from Tools.
assert 'setupSaudiPlacesMapPage' not in ui
camera_page = ui.split('- (void)setupVirtualCameraCardAtY:')[1].split('- (void)selectVirtualCameraImage')[0]
assert 'pickerIconEnabled' in camera_page
assert 'self.pickerIconEnabled && _iconLifecycle.shouldShowIcon' in camera
assert '_titleLabel.text = @"WolFox";' in ui
assert 'chooseRecoveryMethodAndHide:YES' in ui and 'applyRecoveryMethod:method' in ui
assert 'toggleSpoofQuickPanel:' not in ui
assert 'spoofQuickPanel' not in ui
assert '- (void)handleFloatingStatusTap:' in ui
assert '[self showUI];' in ui
assert 'self.spoofQuickPanel = [[' not in ui
interface = ui.split('- (void)setupInterfacePage {')[1].split('- (void)changeRecoveryMethod')[0]
assert 'تشغيل الموقع' not in interface and 'Bluetooth' not in interface and 'إعدادات الكاميرا' not in interface
assert 'إعدادات WolFox' in interface
assert 'WF_RECOVERY_ICON_ENABLED' in interface
assert 'WF_RECOVERY_VOLUME_ENABLED' in interface
assert 'WF_RECOVERY_SCREENSHOT_ENABLED' in interface
assert 'WF_FLOATING_TAP_COUNT' in interface
bt = ui.split('- (void)setupBluetoothPage {')[1].split('- (void)btProfileDeactivated')[0]
for token in ['tag:8102', 'tag:8120', 'startBTScan', 'importBluetoothFile', 'exportBluetoothFile']:
    assert token in bt, token
assert 'shouldShowPickerIcon' in ui and 'previewIsVisible' in camera
for token in ['WFPhotoDelegateForCapture', 'WFTrackPhotoUploadTask', 'hook_AVCaptureSession_stopRunning']:
    assert token in hooks, token
assert 'NSBluetoothAlwaysUsageDescription' in (root/'WFBluetoothScanSession.h').read_text()
print('Feature ownership, real hooks, full-menu recovery and no host-exit wiring guards passed')

# Hiding commits synchronously, so reopening cannot be undone by a stale animation.
hide = ui.split('- (void)dismissUI {')[1].split('- (void)setFloatingStatusIconVisible:')[0]
assert 'animateWithDuration' not in hide
assert 'self.floatingIcon.hidden && (!self.cameraIcon || self.cameraIcon.hidden)' in hide
camera_icon = ui.split('- (void)toggleCameraIcon:(BOOL)show {')[1].split('- (void)prepareCleanVirtualPhotoCapture')[0]
assert 'HUGE_VALF' not in camera_icon and 'CABasicAnimation' not in camera_icon
assert 'self.cameraIcon.alpha = 0.90' in camera_icon
