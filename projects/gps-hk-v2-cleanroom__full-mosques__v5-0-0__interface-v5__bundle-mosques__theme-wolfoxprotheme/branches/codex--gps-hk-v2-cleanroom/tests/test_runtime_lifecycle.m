#import "WFBluetoothScanSession.h"
#import "WFBluetoothDelegateProxy.h"
#import "WFCameraLifecycle.h"
#import "WolFoxProStore.h"
#include <assert.h>
@interface Probe : NSObject <CBCentralManagerDelegate>
@property NSUInteger states, discoveries, connections, failures;
@property NSDictionary *last;
@end
@implementation Probe
- (void)centralManagerDidUpdateState:(__unused CBCentralManager *)central { self.states++; }
- (void)centralManager:(__unused CBCentralManager *)c didDiscoverPeripheral:(__unused CBPeripheral *)p advertisementData:(NSDictionary *)a RSSI:(__unused NSNumber *)r { self.discoveries++; self.last = a; }
- (void)centralManager:(__unused CBCentralManager *)c didConnectPeripheral:(__unused CBPeripheral *)p { self.connections++; }
- (void)centralManager:(__unused CBCentralManager *)c didFailToConnectPeripheral:(__unused CBPeripheral *)p error:(__unused NSError *)e { self.failures++; }
@end
int main(void) { @autoreleasepool {
    NSDictionary *record = @{@"uuid":@"11111111-2222-4333-8444-555555555555",@"name":@"test",@"rssi":@(-60),@"service_uuids":@[@"180D"],@"service_data_b64":@{@"180D":@"AAE="}};
    WFBluetoothScanSession *scan = [WFBluetoothScanSession new];
    NSUInteger old = [scan begin];
    assert(![scan finishGeneration:old]); // Waiting is not a successful scan.
    [scan cancel]; assert(scan.phase == WFBLEScanCancelled);
    assert(![scan startGeneration:old]); assert(![scan addRecord:record generation:old]);
    NSUInteger gen = [scan begin]; assert(gen != old); assert([scan startGeneration:gen]);
    assert([scan addRecord:record generation:gen]);
    NSDictionary *partial = @{@"uuid":record[@"uuid"],@"name":@"جهاز غير معروف",@"rssi":@(-70)};
    assert([scan addRecord:partial generation:gen]); assert(scan.records.count == 1);
    assert([scan.records[0][@"service_uuids"] isEqual:record[@"service_uuids"]]);
    assert([scan.records[0][@"service_data_b64"] isEqual:record[@"service_data_b64"]]);
    assert([scan.records[0][@"name"] isEqual:@"test"]);
    assert([scan.records[0][@"rssi"] integerValue] == -70);
    for (int i = 1; i < 128; i++) {
        NSMutableDictionary *next = [record mutableCopy]; next[@"uuid"] = NSUUID.UUID.UUIDString;
        assert([scan addRecord:next generation:gen]);
    }
    NSMutableDictionary *extra = [record mutableCopy]; extra[@"uuid"] = NSUUID.UUID.UUIDString;
    assert(![scan addRecord:extra generation:gen]); assert(scan.records.count == 128);
    assert([scan finishGeneration:gen]); assert(![scan failGeneration:gen message:@"late failure"]);
    gen = [scan begin]; assert(scan.records.count == 0);
    assert([scan failGeneration:gen message:@"permission timeout"]);
    assert(scan.phase == WFBLEScanFailed && !scan.pending);
    assert(!WFBLEHasUsageDescription(@{})); assert(!WFBLEHasUsageDescription(@{@"NSBluetoothAlwaysUsageDescription":@3}));
    assert(WFBLEHasUsageDescription(@{@"NSBluetoothAlwaysUsageDescription":@"Nearby devices"}));

    Probe *probe = [Probe new];
    WolFoxCBProxy *proxy = [[WolFoxCBProxy alloc] initWithDelegate:probe discovery:nil];
    [proxy centralManagerDidUpdateState:nil];
    [proxy centralManager:nil didDiscoverPeripheral:nil advertisementData:@{@"first":@1} RSSI:@(-55)];
    [proxy centralManager:nil didDiscoverPeripheral:nil advertisementData:@{@"second":@1} RSSI:@(-70)];
    [proxy centralManager:nil didConnectPeripheral:nil];
    [proxy centralManager:nil didFailToConnectPeripheral:nil error:nil];
    assert(probe.states == 1 && probe.discoveries == 2 && probe.connections == 1 && probe.failures == 1);
    assert([probe.last[@"second"] boolValue]);
    __weak Probe *weakProbe = probe; probe = nil; assert(weakProbe == nil);
    [proxy centralManagerDidUpdateState:nil]; // Disappearing host delegates must be harmless.
    assert([proxy methodSignatureForSelector:@selector(centralManager:didFailToConnectPeripheral:error:)].numberOfArguments == 5);
    assert(![proxy respondsToSelector:@selector(centralManager:didConnectPeripheral:)]);
    [proxy centralManager:nil didFailToConnectPeripheral:nil error:nil];

    WFCameraLifecycle *camera = [WFCameraLifecycle new];
    camera.enabled = YES; assert(!camera.shouldShowIcon); // Ordinary browsing.
    for (int cycle = 0; cycle < 3; cycle++) {
        camera.cameraVisible = YES; assert(camera.shouldShowIcon);
        [camera beginActivity:@"picker"]; [camera beginActivity:@"picker"];
        assert(camera.activityCount == 1 && !camera.shouldShowIcon);
        [camera beginActivity:@"capture"]; [camera endActivity:@"picker"]; assert(!camera.shouldShowIcon);
        [camera beginActivity:@"upload"]; [camera endActivity:@"capture"]; assert(!camera.shouldShowIcon);
        [camera endActivity:@"upload"]; assert(camera.shouldShowIcon);
        camera.toolVisible = YES; assert(!camera.shouldShowIcon); camera.toolVisible = NO;
        camera.foreground = NO; assert(!camera.shouldShowIcon); camera.foreground = YES;
        camera.cameraVisible = NO; assert(!camera.shouldShowIcon);
        [camera endActivity:@"upload"]; assert(!camera.shouldShowIcon);
    }
    camera.cameraVisible = YES; camera.enabled = NO; assert(!camera.shouldShowIcon);

    WolFoxProStore *store = [WolFoxProStore new];
    WolFoxBleProfile *profile = [WolFoxBleProfile profileFromBluetoothRecord:record];
    assert([store saveBleProfile:profile]); assert([store selectBleProfileID:profile.profileID]);
    store.bluetoothActive = YES; [store saveSettings];
    profile.name = @"mutated outside"; assert([store.activeBleProfile.name isEqual:@"test"]);
    WolFoxBleProfile *snapshot = store.activeBleProfile; snapshot.name = @"mutated snapshot";
    assert([store.activeBleProfile.name isEqual:@"test"]);
    WolFoxProStore *loaded = [WolFoxProStore new];
    assert(loaded.bluetoothActive && [loaded.activeBleProfile.uuid isEqual:record[@"uuid"]]);
    assert(![loaded selectBleProfileID:@"missing"]);
    [loaded deleteBleProfileID:loaded.activeBleProfileID];
    assert(!loaded.bluetoothActive && !loaded.activeBleProfile);
    [store loadSettings]; assert(!store.bluetoothActive && !store.activeBleProfile);
    puts("Actual scan, delegate forwarding, camera lifecycle, and Bluetooth persistence tests passed");
} return 0; }
