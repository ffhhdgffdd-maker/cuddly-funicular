#import "WFBluetoothScanSession.h"

@implementation WFBluetoothScanSession {
    NSMutableArray<NSDictionary *> *_records;
    NSString *_message;
}
- (instancetype)init {
    if ((self = [super init])) { _records = [NSMutableArray new]; _message = @""; }
    return self;
}
- (NSArray<NSDictionary *> *)records { return [_records copy]; }
- (NSString *)message { return _message; }
- (BOOL)isPending { return _phase == WFBLEScanWaiting || _phase == WFBLEScanRunning; }
- (NSUInteger)begin {
    _generation++; _phase = WFBLEScanWaiting; [_records removeAllObjects];
    _message = @"بانتظار جاهزية Bluetooth والإذن";
    return _generation;
}
- (BOOL)isCurrent:(NSUInteger)generation { return generation == _generation && self.pending; }
- (BOOL)startGeneration:(NSUInteger)generation {
    if (![self isCurrent:generation] || _phase != WFBLEScanWaiting) return NO;
    _phase = WFBLEScanRunning; _message = @"جارٍ البحث عن أجهزة قريبة"; return YES;
}
- (BOOL)addRecord:(NSDictionary *)record generation:(NSUInteger)generation {
    if (![self isCurrent:generation] || _phase != WFBLEScanRunning) return NO;
    NSDictionary *valid = WFBLEValidatedRecord(record);
    if (!valid) return NO;
    NSUInteger index = [_records indexOfObjectPassingTest:^BOOL(NSDictionary *old, __unused NSUInteger idx, __unused BOOL *stop) {
        return [old[@"uuid"] isEqual:valid[@"uuid"]];
    }];
    if (index == NSNotFound) {
        if (_records.count >= 128) return NO;
        [_records addObject:valid];
    } else {
        NSDictionary *previous = _records[index];
        NSMutableDictionary *merged = [previous mutableCopy];
        [merged addEntriesFromDictionary:valid];
        // A later RSSI-only packet must not discard previously captured payloads.
        NSMutableOrderedSet *services = [NSMutableOrderedSet orderedSetWithArray:previous[@"service_uuids"] ?: @[]];
        [services addObjectsFromArray:valid[@"service_uuids"] ?: @[]];
        merged[@"service_uuids"] = services.array;
        NSMutableDictionary *data = [(previous[@"service_data_b64"] ?: @{}) mutableCopy];
        [data addEntriesFromDictionary:valid[@"service_data_b64"] ?: @{}];
        merged[@"service_data_b64"] = data;
        if (![valid[@"local_name"] length]) merged[@"local_name"] = previous[@"local_name"] ?: @"";
        if ([valid[@"name"] isEqual:@"جهاز غير معروف"]) merged[@"name"] = previous[@"name"];
        NSDictionary *checked = WFBLEValidatedRecord(merged);
        if (!checked) return NO;
        _records[index] = checked;
    }
    _message = [NSString stringWithFormat:@"جارٍ البحث • %lu جهاز", (unsigned long)_records.count];
    return YES;
}
- (BOOL)finishGeneration:(NSUInteger)generation {
    if (![self isCurrent:generation] || _phase != WFBLEScanRunning) return NO;
    _phase = WFBLEScanComplete;
    _message = _records.count ? [NSString stringWithFormat:@"اكتمل البحث • %lu جهاز", (unsigned long)_records.count]
        : @"اكتمل البحث دون العثور على أجهزة تعلن عبر Bluetooth";
    return YES;
}
- (BOOL)failGeneration:(NSUInteger)generation message:(NSString *)message {
    if (![self isCurrent:generation]) return NO;
    _phase = WFBLEScanFailed; _message = [message copy]; return YES;
}
- (void)cancel {
    if (!self.pending) return;
    _generation++; _phase = WFBLEScanCancelled; _message = @"تم إيقاف البحث";
}
@end
