#import "WFCameraLifecycle.h"
@implementation WFCameraLifecycle {
    NSMutableSet<NSString *> *_activities;
}
- (instancetype)init { if ((self = [super init])) { _foreground = YES; _activities = [NSMutableSet new]; } return self; }
- (BOOL)shouldShowIcon { return _enabled && _cameraVisible && _foreground && !_toolVisible && !_activities.count; }
- (NSUInteger)activityCount { return _activities.count; }
- (void)beginActivity:(NSString *)identifier { if (identifier.length) [_activities addObject:[identifier copy]]; }
- (void)endActivity:(NSString *)identifier { if (identifier.length) [_activities removeObject:identifier]; }
@end
