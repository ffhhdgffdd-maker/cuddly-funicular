#import "WFMediaLifecycleHooks.h"
#import "WFVirtualCameraManager.h"
#import <objc/runtime.h>

static char WFPhotoDelegatesKey, WFUploadObserverKey;

@interface WFPhotoLifecycleProxy : NSProxy <AVCapturePhotoCaptureDelegate>
@property (nonatomic, strong) id target;
@property (nonatomic, copy) NSString *activity;
@property (nonatomic, copy) void (^completion)(void);
@end
@implementation WFPhotoLifecycleProxy
- (BOOL)respondsToSelector:(SEL)selector {
    return selector == @selector(captureOutput:didFinishCaptureForResolvedSettings:error:) ||
        class_getInstanceMethod(WFPhotoLifecycleProxy.class, selector) != NULL || [_target respondsToSelector:selector];
}
- (NSMethodSignature *)methodSignatureForSelector:(SEL)selector {
    NSMethodSignature *signature = [_target methodSignatureForSelector:selector];
    if (signature) return signature;
    struct objc_method_description method = protocol_getMethodDescription(@protocol(AVCapturePhotoCaptureDelegate), selector, NO, YES);
    return method.types ? [NSMethodSignature signatureWithObjCTypes:method.types] : [NSObject instanceMethodSignatureForSelector:selector];
}
- (void)forwardInvocation:(NSInvocation *)invocation {
    id target = _target;
    if ([target respondsToSelector:invocation.selector]) [invocation invokeWithTarget:target];
    else if (invocation.methodSignature.methodReturnLength) {
        NSMutableData *zero = [NSMutableData dataWithLength:invocation.methodSignature.methodReturnLength];
        [invocation setReturnValue:zero.mutableBytes];
    }
}
- (void)captureOutput:(AVCapturePhotoOutput *)output didFinishCaptureForResolvedSettings:(AVCaptureResolvedPhotoSettings *)settings error:(NSError *)error {
    @try {
        id target = _target;
        if ([target respondsToSelector:_cmd]) [target captureOutput:output didFinishCaptureForResolvedSettings:settings error:error];
    } @finally {
        [[WFVirtualCameraManager shared] endCameraActivity:_activity];
        void (^completion)(void) = _completion;
        _completion = nil; _target = nil;
        if (completion) completion();
    }
}
@end

id<AVCapturePhotoCaptureDelegate> WFPhotoDelegateForCapture(AVCapturePhotoOutput *output, AVCapturePhotoSettings *settings, id<AVCapturePhotoCaptureDelegate> target) {
    if (!target || ![WFVirtualCameraManager shared].enabled) return target;
    NSString *key = [NSString stringWithFormat:@"capture-%lld", settings.uniqueID];
    WFPhotoLifecycleProxy *proxy = [WFPhotoLifecycleProxy alloc];
    proxy.target = target; proxy.activity = key;
    __weak AVCapturePhotoOutput *weakOutput = output;
    proxy.completion = ^{
        AVCapturePhotoOutput *strongOutput = weakOutput;
        if (!strongOutput) return;
        @synchronized(strongOutput) {
            NSMutableDictionary *delegates = objc_getAssociatedObject(strongOutput, &WFPhotoDelegatesKey);
            [delegates removeObjectForKey:key];
        }
    };
    @synchronized(output) {
        NSMutableDictionary *delegates = objc_getAssociatedObject(output, &WFPhotoDelegatesKey);
        if (!delegates) { delegates = [NSMutableDictionary new]; objc_setAssociatedObject(output, &WFPhotoDelegatesKey, delegates, OBJC_ASSOCIATION_RETAIN_NONATOMIC); }
        delegates[key] = proxy;
    }
    [[WFVirtualCameraManager shared] beginCameraActivity:key];
    return proxy;
}

@interface WFPhotoUploadObserver : NSObject
@property (nonatomic, weak) NSURLSessionTask *task;
@property (nonatomic, copy) NSString *activity;
@property (nonatomic) BOOL observing;
@property (nonatomic) BOOL started;
- (void)watch:(NSURLSessionTask *)task;
@end
@implementation WFPhotoUploadObserver
- (void)watch:(NSURLSessionTask *)task {
    self.task = task; self.activity = [@"upload-" stringByAppendingString:NSUUID.UUID.UUIDString];
    @try { self.observing = YES; [task addObserver:self forKeyPath:@"state" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:NULL]; }
    @catch (__unused NSException *exception) { self.observing = NO; }
}
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (![keyPath isEqual:@"state"] || object != self.task) { [super observeValueForKeyPath:keyPath ofObject:object change:change context:context]; return; }
    NSURLSessionTaskState state = self.task.state;
    if (state == NSURLSessionTaskStateRunning && !self.started) {
        self.started = YES;
        [[WFVirtualCameraManager shared] beginCameraActivity:self.activity];
    } else if (state == NSURLSessionTaskStateCompleted || state == NSURLSessionTaskStateCanceling) {
        [[WFVirtualCameraManager shared] endCameraActivity:self.activity];
    }
}
- (void)dealloc {
    if (_observing && _task) { @try { [_task removeObserver:self forKeyPath:@"state"]; } @catch (__unused NSException *exception) {} }
    if (_started) [[WFVirtualCameraManager shared] endCameraActivity:_activity];
}
@end

void WFTrackPhotoUploadTask(NSURLSessionUploadTask *task, NSData *body) {
    if (!task || objc_getAssociatedObject(task, &WFUploadObserverKey) || ![[WFVirtualCameraManager shared] containsCurrentPhotoData:body]) return;
    WFPhotoUploadObserver *observer = [WFPhotoUploadObserver new];
    objc_setAssociatedObject(task, &WFUploadObserverKey, observer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [observer watch:task];
}
void WFTrackPhotoFileUploadTask(NSURLSessionUploadTask *task, NSURL *file) {
    if (!task || !file.isFileURL || ![WFVirtualCameraManager shared].enabled) return;
    NSFileHandle *handle = [NSFileHandle fileHandleForReadingFromURL:file error:NULL];
    @try { NSData *body = [handle readDataOfLength:32 * 1024 * 1024 + 1]; WFTrackPhotoUploadTask(task, body); }
    @catch (__unused NSException *exception) {}
    @finally { [handle closeFile]; }
}
