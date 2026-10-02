#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
clang -fobjc-arc -Wall -Wextra -Werror -I. tests/test_identifier_transfer.m -framework Foundation -o "$work/identifier"
"$work/identifier"
clang -fobjc-arc -Wall -Wextra -Werror -I. tests/test_bluetooth_profile.m -framework Foundation -framework CoreBluetooth -o "$work/bluetooth"
"$work/bluetooth"
clang -fobjc-arc -Wall -Wextra -I. tests/test_runtime_lifecycle.m WFBluetoothScanSession.m WFBluetoothDelegateProxy.m WFCameraLifecycle.m WolFoxProStore.m WFRedactedLogger.m -framework Foundation -framework CoreBluetooth -framework CoreLocation -lsqlite3 -o "$work/lifecycle"
"$work/lifecycle"
