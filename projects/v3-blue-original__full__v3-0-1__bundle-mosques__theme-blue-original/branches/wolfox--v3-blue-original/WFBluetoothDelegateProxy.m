#import "WFBluetoothDelegateProxy.h"
#import <objc/runtime.h>
@implementation WolFoxCBProxy {
    __weak id _delegate;
    WFBLEDiscoveryHandler _handler;
}
- (instancetype)initWithDelegate:(id)delegate discovery:(WFBLEDiscoveryHandler)handler { _delegate = delegate; _handler = [handler copy]; return self; }
- (NSMethodSignature *)methodSignatureForSelector:(SEL)selector {
    id delegate = _delegate;
    NSMethodSignature *signature = [delegate methodSignatureForSelector:selector];
    if (signature) return signature;
    struct objc_method_description method = protocol_getMethodDescription(@protocol(CBCentralManagerDelegate), selector, NO, YES);
    if (!method.types) method = protocol_getMethodDescription(@protocol(CBCentralManagerDelegate), selector, YES, YES);
    return method.types ? [NSMethodSignature signatureWithObjCTypes:method.types] : [NSObject instanceMethodSignatureForSelector:selector];
}
- (void)forwardInvocation:(NSInvocation *)invocation {
    id delegate = _delegate;
    if ([delegate respondsToSelector:invocation.selector]) [invocation invokeWithTarget:delegate];
    else if (invocation.methodSignature.methodReturnLength) {
        NSMutableData *zero = [NSMutableData dataWithLength:invocation.methodSignature.methodReturnLength];
        [invocation setReturnValue:zero.mutableBytes];
    }
}
- (BOOL)respondsToSelector:(SEL)selector {
    return class_getInstanceMethod(WolFoxCBProxy.class, selector) != NULL || [_delegate respondsToSelector:selector];
}
- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    id delegate = _delegate;
    if ([delegate respondsToSelector:_cmd]) [delegate centralManagerDidUpdateState:central];
}
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisement RSSI:(NSNumber *)rssi {
    id delegate = _delegate;
    if (![delegate respondsToSelector:_cmd]) return;
    if (_handler) _handler(delegate, central, peripheral, advertisement, rssi);
    else [delegate centralManager:central didDiscoverPeripheral:peripheral advertisementData:advertisement RSSI:rssi];
}
@end
