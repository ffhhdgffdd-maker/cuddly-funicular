#import <Foundation/Foundation.h>
@interface WFCameraLifecycle : NSObject
@property (nonatomic) BOOL enabled;
@property (nonatomic) BOOL cameraVisible;
@property (nonatomic) BOOL foreground;
@property (nonatomic) BOOL toolVisible;
@property (nonatomic, readonly) BOOL shouldShowIcon;
@property (nonatomic, readonly) NSUInteger activityCount;
- (void)beginActivity:(NSString *)identifier;
- (void)endActivity:(NSString *)identifier;
@end
