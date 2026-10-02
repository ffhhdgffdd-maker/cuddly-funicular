#import "WFBluetoothProfileCodec.h"
#import "WFInterfacePolicy.h"
#include <assert.h>

int main(void) {
    @autoreleasepool {
        NSString *uuid = @"11111111-2222-4333-8444-555555555555";
        NSString *other = @"AAAAAAAA-BBBB-4CCC-8DDD-EEEEEEEEEEEE";
        CBUUID *service = [CBUUID UUIDWithString:@"180D"];
        NSData *payload = [NSData dataWithBytes:"\x00\xff\x01" length:3];
        NSDictionary *advertisement = @{
            CBAdvertisementDataServiceUUIDsKey:@[service],
            CBAdvertisementDataServiceDataKey:@{service:payload},
            CBAdvertisementDataManufacturerDataKey:payload,
            CBAdvertisementDataIsConnectable:@YES,
            @"future-key":@"preserved"
        };
        NSMutableDictionary *record = [WFBLECaptureAdvertisement(advertisement) mutableCopy];
        record[@"uuid"] = uuid; record[@"source_uuid"] = uuid;
        record[@"name"] = @"جهاز اختبار"; record[@"local_name"] = @""; record[@"rssi"] = @(-67);
        NSDictionary *valid = WFBLEValidatedRecord(record);
        assert(valid != nil);
        NSData *exported = WFBLEExport(record);
        assert(exported.length > 0 && exported.length <= WFBLEMaxFileBytes);
        assert([WFBLEImport(exported) isEqual:valid]);
        assert(WFBLEMatchesPeripheral(valid, uuid.lowercaseString));
        assert(!WFBLEMatchesPeripheral(valid, other));
        assert(!WFBLEMatchesPeripheral(valid, nil));
        NSMutableDictionary *mapped = [valid mutableCopy]; mapped[@"uuid"] = other;
        assert(WFBLEMatchesPeripheral(mapped, uuid));
        assert(!WFBLEMatchesPeripheral(mapped, other));
        NSMutableDictionary *live = [advertisement mutableCopy]; live[CBAdvertisementDataIsConnectable] = @NO;
        NSDictionary *replay = WFBLEReplayAdvertisement(live, valid);
        assert([replay[@"future-key"] isEqual:@"preserved"]);
        assert(![replay[CBAdvertisementDataIsConnectable] boolValue]);
        assert([replay[CBAdvertisementDataLocalNameKey] isEqual:record[@"name"]]);
        assert([replay[CBAdvertisementDataServiceDataKey][service] isEqual:payload]);
        assert([replay[CBAdvertisementDataManufacturerDataKey] isEqual:payload]);
        assert([WFBLEValidatedRecord(@{@"uuid":uuid,@"name":@"Legacy",@"rssi":@0}) count] == 5);
        assert(WFBLEValidatedRecord(@{@"uuid":uuid,@"name":@"Unknown RSSI",@"rssi":@127}));
        for (id invalid in @[@{}, @[], NSNull.null, @"text"]) assert(!WFBLEValidatedRecord(invalid));
        NSDictionary *badValues = @{
            @"uuid":@"invalid", @"name":@"", @"rssi":@(-128),
            @"source_uuid":@"bad", @"local_name":@3,
            @"service_uuids":@[@"ZZZZ"], @"service_data_b64":@{@"180D":@"!?"},
            @"manufacturer_b64":@"?!", @"connectable":@"true"
        };
        for (NSString *key in badValues) {
            NSMutableDictionary *bad = [valid mutableCopy]; bad[key] = badValues[key];
            assert(!WFBLEValidatedRecord(bad));
        }
        for (NSNumber *rssi in @[@(-60.5), @128, @21]) {
            NSMutableDictionary *bad = [valid mutableCopy]; bad[@"rssi"] = rssi;
            assert(!WFBLEValidatedRecord(bad));
        }
        NSMutableDictionary *oversized = [valid mutableCopy];
        oversized[@"manufacturer_b64"] = [[NSMutableData dataWithLength:4097] base64EncodedStringWithOptions:0];
        assert(!WFBLEValidatedRecord(oversized));
        assert(!WFBLEImport([NSMutableData dataWithLength:WFBLEMaxFileBytes + 1]));
        assert(!WFBLEImport([@"{}" dataUsingEncoding:NSUTF8StringEncoding]));
        NSData *wrong = [NSJSONSerialization dataWithJSONObject:@{@"format":@"wolfox.bluetooth",@"version":@2,@"device":valid} options:0 error:NULL];
        assert(!WFBLEImport(wrong));
        assert([WFBLEServiceUUID(@"feaa") isEqual:@"FEAA"]);
        assert([WFBLEServiceUUID(@"12345678") isEqual:@"12345678"]);
        assert(!WFBLEServiceUUID(@"123"));
        assert([WFBLECaptureAdvertisement(@{CBAdvertisementDataServiceUUIDsKey:@3})[@"service_uuids"] count] == 0);
        for (NSInteger version = 0; version <= 5; version++) {
            assert(!WFInterfaceMenuDefault(version));
            assert(WFInterfaceVolumeAllowed(version, YES));
            assert(!WFInterfaceVolumeAllowed(version, NO));
            assert(!WFInterfaceTripleTapAllowed(version, YES));
            assert(WFInterfaceNeedsFallback(version, NO, NO, YES));
            assert(!WFInterfaceNeedsFallback(version, YES, NO, NO));
            assert(!WFInterfaceNeedsFallback(version, NO, YES, NO));
        }
        assert(!WFRecoveryMethodValid(0) && !WFRecoveryMethodValid(4));
        assert(WFRecoveryUsesIcon(1) && !WFRecoveryUsesVolume(1));
        assert(!WFRecoveryUsesIcon(2) && WFRecoveryUsesVolume(2));
        assert(WFRecoveryUsesIcon(3) && WFRecoveryUsesVolume(3));
        puts("Bluetooth codec and interface policy tests passed");
    }
    return 0;
}
