#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "WFIdentifierTransfer.h"

static const NSUInteger WFBLEMaxFileBytes = 131072;

// Capture uses original accessors even if the host previously discovered this object.
FOUNDATION_EXPORT NSUUID *WFBLEActualPeripheralIdentifier(CBPeripheral *peripheral);
FOUNDATION_EXPORT NSString *WFBLEActualPeripheralName(CBPeripheral *peripheral);

static inline NSString *WFBLEServiceUUID(id value) {
    if (![value isKindOfClass:NSString.class]) return nil;
    NSString *s = [(NSString *)value uppercaseString];
    if (s.length == 36) return WFTransferUUID(s);
    if (s.length != 4 && s.length != 8) return nil;
    NSCharacterSet *hex = [NSCharacterSet characterSetWithCharactersInString:@"0123456789ABCDEF"];
    return [s rangeOfCharacterFromSet:hex.invertedSet].location == NSNotFound ? s : nil;
}

// JSON-safe representation of a real advertisement. No connection-state data.
static inline NSDictionary *WFBLECaptureAdvertisement(NSDictionary *advertisement) {
    NSMutableArray *services = [NSMutableArray new];
    id advertisedServices = advertisement[CBAdvertisementDataServiceUUIDsKey];
    if (![advertisedServices isKindOfClass:NSArray.class]) advertisedServices = @[];
    for (id value in advertisedServices) {
        if ([value isKindOfClass:CBUUID.class] && services.count < 64)
            [services addObject:((CBUUID *)value).UUIDString];
    }
    NSMutableDictionary *serviceData = [NSMutableDictionary new];
    NSDictionary *source = advertisement[CBAdvertisementDataServiceDataKey];
    if ([source isKindOfClass:NSDictionary.class]) for (id key in source) {
        id value = source[key];
        if ([key isKindOfClass:CBUUID.class] && [value isKindOfClass:NSData.class] &&
            [(NSData *)value length] <= 4096 && serviceData.count < 64)
            serviceData[((CBUUID *)key).UUIDString] = [(NSData *)value base64EncodedStringWithOptions:0];
    }
    NSMutableDictionary *record = [@{@"service_uuids":[services copy], @"service_data_b64":[serviceData copy]} mutableCopy];
    NSData *manufacturer = advertisement[CBAdvertisementDataManufacturerDataKey];
    if ([manufacturer isKindOfClass:NSData.class] && manufacturer.length <= 4096)
        record[@"manufacturer_b64"] = [manufacturer base64EncodedStringWithOptions:0];
    NSNumber *connectable = advertisement[CBAdvertisementDataIsConnectable];
    if ([connectable isKindOfClass:NSNumber.class]) record[@"connectable"] = @([connectable boolValue]);
    return record;
}

static inline NSDictionary *WFBLEValidatedRecord(id value) {
    if (![value isKindOfClass:NSDictionary.class]) return nil;
    NSDictionary *record = value;
    NSString *uuid = WFTransferUUID(record[@"uuid"]);
    if (!uuid || ![record[@"name"] isKindOfClass:NSString.class] ||
        ![record[@"rssi"] isKindOfClass:NSNumber.class]) return nil;
    NSString *name = record[@"name"];
    double rssi = [record[@"rssi"] doubleValue];
    NSInteger integerRSSI = [record[@"rssi"] integerValue];
    if (!name.length || name.length > 200 || rssi != integerRSSI ||
        !((rssi >= -127 && rssi <= 20) || rssi == 127)) return nil;
    id rawServices = record[@"service_uuids"] ?: @[];
    id rawData = record[@"service_data_b64"] ?: @{};
    if (![rawServices isKindOfClass:NSArray.class] || [rawServices count] > 64 ||
        ![rawData isKindOfClass:NSDictionary.class] || [rawData count] > 64) return nil;
    NSMutableArray *services = [NSMutableArray new];
    for (id raw in rawServices) {
        NSString *service = WFBLEServiceUUID(raw);
        if (!service) return nil;
        if (![services containsObject:service]) [services addObject:service];
    }
    NSMutableDictionary *serviceData = [NSMutableDictionary new];
    NSUInteger payloadBytes = 0;
    for (id key in rawData) {
        NSString *service = WFBLEServiceUUID(key);
        id encoded = [rawData objectForKey:key];
        if (!service || ![encoded isKindOfClass:NSString.class] || [encoded length] > 5500) return nil;
        NSData *bytes = [[NSData alloc] initWithBase64EncodedString:encoded options:0];
        if (!bytes || bytes.length > 4096) return nil;
        payloadBytes += bytes.length;
        serviceData[service] = [encoded copy];
    }
    if (payloadBytes > 65536) return nil;
    NSMutableDictionary *result = [@{@"uuid":uuid, @"name":[name copy], @"rssi":@(integerRSSI),
        @"service_uuids":[services copy], @"service_data_b64":[serviceData copy]} mutableCopy];
    for (NSString *key in @[@"source_uuid", @"local_name"]) {
        id text = record[key];
        if (text) {
            if (![text isKindOfClass:NSString.class] || [text length] > 200) return nil;
            if ([key isEqual:@"source_uuid"] && !WFTransferUUID(text)) return nil;
            result[key] = [key isEqual:@"source_uuid"] ? WFTransferUUID(text) : [text copy];
        }
    }
    id encoded = record[@"manufacturer_b64"];
    if (encoded) {
        if (![encoded isKindOfClass:NSString.class] || [encoded length] > 5500) return nil;
        NSData *bytes = [[NSData alloc] initWithBase64EncodedString:encoded options:0];
        if (!bytes || bytes.length > 4096) return nil;
        result[@"manufacturer_b64"] = [encoded copy];
    }
    if (record[@"connectable"]) {
        if (![record[@"connectable"] isKindOfClass:NSNumber.class]) return nil;
        result[@"connectable"] = @([record[@"connectable"] boolValue]);
    }
    return [result copy];
}

static inline BOOL WFBLEMatchesPeripheral(NSDictionary *record, NSString *actualUUID) {
    NSString *target = WFTransferUUID(record[@"source_uuid"] ?: record[@"uuid"]);
    NSString *actual = WFTransferUUID(actualUUID);
    return target && actual && [target isEqual:actual];
}

static inline NSDictionary *WFBLEReplayAdvertisement(NSDictionary *original, NSDictionary *record) {
    NSMutableDictionary *result = original ? [original mutableCopy] : [NSMutableDictionary new];
    NSString *name = [record[@"local_name"] length] ? record[@"local_name"] : record[@"name"];
    if (name.length) result[CBAdvertisementDataLocalNameKey] = name;
    NSMutableArray *services = [NSMutableArray new];
    for (NSString *uuid in record[@"service_uuids"]) [services addObject:[CBUUID UUIDWithString:uuid]];
    if (services.count) result[CBAdvertisementDataServiceUUIDsKey] = services;
    NSMutableDictionary *data = [NSMutableDictionary new];
    for (NSString *uuid in record[@"service_data_b64"])
        data[[CBUUID UUIDWithString:uuid]] = [[NSData alloc] initWithBase64EncodedString:record[@"service_data_b64"][uuid] options:0];
    if (data.count) result[CBAdvertisementDataServiceDataKey] = data;
    NSString *encoded = record[@"manufacturer_b64"];
    if (encoded) result[CBAdvertisementDataManufacturerDataKey] = [[NSData alloc] initWithBase64EncodedString:encoded options:0];
    // The live connectable flag and connection callbacks are always preserved.
    return [result copy];
}

static inline NSData *WFBLEExport(NSDictionary *record) {
    NSDictionary *valid = WFBLEValidatedRecord(record);
    if (!valid) return nil;
    return [NSJSONSerialization dataWithJSONObject:@{@"format":@"wolfox.bluetooth", @"version":@1, @"device":valid}
        options:NSJSONWritingPrettyPrinted error:NULL];
}

static inline NSDictionary *WFBLEImport(NSData *data) {
    if (!data.length || data.length > WFBLEMaxFileBytes) return nil;
    id document = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
    if (![document isKindOfClass:NSDictionary.class] || ![document[@"format"] isEqual:@"wolfox.bluetooth"] ||
        ![document[@"version"] isEqual:@1]) return nil;
    return WFBLEValidatedRecord(document[@"device"]);
}
