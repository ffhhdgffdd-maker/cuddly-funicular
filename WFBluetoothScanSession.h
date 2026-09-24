#import "WFBluetoothProfileCodec.h"

typedef NS_ENUM(NSInteger, WFBLEScanPhase) {
    WFBLEScanIdle, WFBLEScanWaiting, WFBLEScanRunning,
    WFBLEScanComplete, WFBLEScanCancelled, WFBLEScanFailed
};

// Owned by the main queue. Timers and callbacks must carry the current generation.
@interface WFBluetoothScanSession : NSObject
@property (nonatomic, readonly) NSUInteger generation;
@property (nonatomic, readonly) WFBLEScanPhase phase;
@property (nonatomic, readonly, getter=isPending) BOOL pending;
@property (nonatomic, copy, readonly) NSString *message;
@property (nonatomic, copy, readonly) NSArray<NSDictionary *> *records;
- (NSUInteger)begin;
- (BOOL)isCurrent:(NSUInteger)generation;
- (BOOL)startGeneration:(NSUInteger)generation;
- (BOOL)addRecord:(NSDictionary *)record generation:(NSUInteger)generation;
- (BOOL)finishGeneration:(NSUInteger)generation;
- (BOOL)failGeneration:(NSUInteger)generation message:(NSString *)message;
- (void)cancel;
@end

static inline BOOL WFBLEHasUsageDescription(NSDictionary *info) {
    id value = info[@"NSBluetoothAlwaysUsageDescription"];
    return [value isKindOfClass:NSString.class] &&
        [[value stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet] length] > 0;
}
