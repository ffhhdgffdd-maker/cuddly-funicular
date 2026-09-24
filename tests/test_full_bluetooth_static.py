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
print('Bluetooth and interface integration guards passed')
