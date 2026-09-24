#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
typedef void (^WFBLEDiscoveryHandler)(id delegate, CBCentralManager *manager, CBPeripheral *peripheral, NSDictionary *advertisement, NSNumber *rssi);
@interface WolFoxCBProxy : NSProxy <CBCentralManagerDelegate>
- (instancetype)initWithDelegate:(id)delegate discovery:(WFBLEDiscoveryHandler)handler;
@end
