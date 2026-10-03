#import <Foundation/Foundation.h>
#import <UserNotifications/UserNotifications.h>

typedef NS_ENUM(NSInteger, WFExpiryState) {
    WFExpiryStateNone, WFExpiryStateActive, WFExpiryStateExpired, WFExpiryStateUncertain
};

// The adapter also lets native tests exercise the real scheduler without sending notifications.
@protocol WFExpiryNotificationCenter <NSObject>
- (void)authorization:(void (^)(BOOL allowed))completion;
- (void)pending:(void (^)(NSArray<UNNotificationRequest *> *requests))completion;
- (void)delivered:(void (^)(NSArray<NSString *> *identifiers))completion;
- (void)add:(UNNotificationRequest *)request completion:(void (^)(NSError *error))completion;
- (void)remove:(NSArray<NSString *> *)identifiers;
@end

@interface WFExpiryNotifications : NSObject
+ (instancetype)shared;
- (instancetype)initWithCenter:(id<WFExpiryNotificationCenter>)center defaults:(NSUserDefaults *)defaults clock:(NSDate *(^)(void))clock;
// Return YES only if the banner was actually presented. Called on the main thread.
@property (nonatomic, copy) BOOL (^presentNotice)(NSString *title, NSString *body);
- (void)updateEnabled:(BOOL)enabled code:(NSString *)code expiry:(NSString *)expiry state:(WFExpiryState)state;
@end
