#import "WFExpiryNotifications.h"
#import "WFLicenseDates.h"
#import <CommonCrypto/CommonDigest.h>

static NSString *const WFExpiryLedger = @"WF_EXPIRY_NOTIFICATION_LEDGER_V2";
static NSString *const WFExpirySoon = @"wolfox.expiry.reminder";
static NSString *const WFExpiryEnded = @"wolfox.expiry.ended";

@interface WFSystemExpiryCenter : NSObject <WFExpiryNotificationCenter>
@end
@implementation WFSystemExpiryCenter
- (void)authorization:(void (^)(BOOL))completion {
    [UNUserNotificationCenter.currentNotificationCenter getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings *settings) {
        completion(settings.authorizationStatus == UNAuthorizationStatusAuthorized || settings.authorizationStatus == UNAuthorizationStatusProvisional);
    }];
}
- (void)pending:(void (^)(NSArray<UNNotificationRequest *> *))completion {
    [UNUserNotificationCenter.currentNotificationCenter getPendingNotificationRequestsWithCompletionHandler:completion];
}
- (void)delivered:(void (^)(NSArray<NSString *> *))completion {
    [UNUserNotificationCenter.currentNotificationCenter getDeliveredNotificationsWithCompletionHandler:^(NSArray<UNNotification *> *notifications) {
        NSMutableArray *ids = [NSMutableArray array];
        for (UNNotification *notification in notifications) [ids addObject:notification.request.identifier];
        completion(ids);
    }];
}
- (void)add:(UNNotificationRequest *)request completion:(void (^)(NSError *))completion {
    [UNUserNotificationCenter.currentNotificationCenter addNotificationRequest:request withCompletionHandler:completion];
}
- (void)remove:(NSArray<NSString *> *)identifiers {
    [UNUserNotificationCenter.currentNotificationCenter removePendingNotificationRequestsWithIdentifiers:identifiers];
    [UNUserNotificationCenter.currentNotificationCenter removeDeliveredNotificationsWithIdentifiers:identifiers];
}
@end

@interface WFExpiryNotifications ()
@property (nonatomic, strong) id<WFExpiryNotificationCenter> center;
@property (nonatomic, strong) NSUserDefaults *defaults;
@property (nonatomic, copy) NSDate *(^clock)(void);
@property (nonatomic, copy) NSDictionary *nextUpdate;
@property (nonatomic) BOOL busy;
- (void)drain;
- (void)finish;
@end

@implementation WFExpiryNotifications
+ (instancetype)shared {
    static WFExpiryNotifications *service;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ service = [[self alloc] initWithCenter:[WFSystemExpiryCenter new] defaults:NSUserDefaults.standardUserDefaults clock:^{ return NSDate.date; }]; });
    return service;
}
- (instancetype)initWithCenter:(id<WFExpiryNotificationCenter>)center defaults:(NSUserDefaults *)defaults clock:(NSDate *(^)(void))clock {
    if ((self = [super init])) { _center = center; _defaults = defaults; _clock = [clock copy]; }
    return self;
}
- (void)updateEnabled:(BOOL)enabled code:(NSString *)code expiry:(NSString *)expiry state:(WFExpiryState)state {
    NSDictionary *update = @{@"enabled": @(enabled), @"code": code ?: @"", @"expiry": expiry ?: @"", @"state": @(state)};
    dispatch_async(dispatch_get_main_queue(), ^{ self.nextUpdate = update; [self drain]; });
}
- (void)finish {
    self.busy = NO;
    [self drain];
}
- (void)drain {
    if (self.busy || !self.nextUpdate) return;
    self.busy = YES;
    NSDictionary *update = self.nextUpdate; self.nextUpdate = nil;
    NSArray *all = @[WFExpirySoon, WFExpiryEnded];
    if (![update[@"enabled"] boolValue]) {
        [self.center remove:all]; // Keep the ledger so off/on does not repeat an already delivered alert.
        [self finish]; return;
    }
    WFExpiryState state = [update[@"state"] integerValue];
    if (state == WFExpiryStateUncertain) { [self finish]; return; } // Network failures must not erase reminders.
    NSDate *expiry = WFParseLicenseDate(update[@"expiry"]);
    if (state == WFExpiryStateNone || ![update[@"code"] length] || (state == WFExpiryStateActive && !expiry)) {
        [self.center remove:all];
        [self.defaults removeObjectForKey:WFExpiryLedger];
        [self finish]; return;
    }
    // Hash the license code; never put the code in notification content or identifiers.
    NSData *data = [update[@"code"] dataUsingEncoding:NSUTF8StringEncoding];
    unsigned char digest[CC_SHA256_DIGEST_LENGTH]; CC_SHA256(data.bytes, (CC_LONG)data.length, digest);
    NSString *identity = [[NSData dataWithBytes:digest length:sizeof(digest)] base64EncodedStringWithOptions:0];
    NSString *generation = [NSString stringWithFormat:@"%@|%@", identity, expiry ? @(expiry.timeIntervalSince1970) : @"expired"];
    NSMutableDictionary *ledger = [[self.defaults dictionaryForKey:WFExpiryLedger] mutableCopy];
    if (![ledger[@"generation"] isEqual:generation]) {
        [self.center remove:all];
        ledger = [@{@"generation": generation} mutableCopy];
        [self.defaults setObject:ledger forKey:WFExpiryLedger];
    }
    [self.center authorization:^(BOOL allowed) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!allowed) { [self.center remove:all]; [self finish]; return; }
            [self.center pending:^(NSArray<UNNotificationRequest *> *pending) {
                [self.center delivered:^(NSArray<NSString *> *delivered) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        NSDate *now = self.clock();
                        BOOL ended = state == WFExpiryStateExpired || [expiry compare:now] != NSOrderedDescending;
                        NSArray *identifiers = ended ? @[WFExpiryEnded] : all;
                        if (ended) [self.center remove:@[WFExpirySoon]];
                        dispatch_group_t group = dispatch_group_create();
                        for (NSString *identifier in identifiers) {
                            BOOL soon = [identifier isEqual:WFExpirySoon];
                            NSDate *due = soon ? [expiry dateByAddingTimeInterval:-3 * 24 * 60 * 60] : (ended ? now : expiry);
                            BOOL immediate = [due compare:now] != NSOrderedDescending;
                            NSString *shownKey = [identifier stringByAppendingString:@".shown"];
                            BOOL wasDelivered = [delivered containsObject:identifier];
                            if (wasDelivered) ledger[shownKey] = @YES;
                            NSString *title = soon ? @"اشتراك WolFox يوشك على الانتهاء" : @"انتهى اشتراك WolFox";
                            NSString *body = soon ? @"يتبقى ثلاثة أيام أو أقل على انتهاء اشتراكك. افتح معلومات التفعيل للتجديد." : @"انتهت صلاحية اشتراكك. جدّد الاشتراك لمتابعة استخدام WolFox.";
                            if (immediate && ![ledger[shownKey] boolValue] && self.presentNotice && self.presentNotice(title, body)) {
                                [self.center remove:@[identifier]];
                                ledger[shownKey] = @YES; ledger[identifier] = @(now.timeIntervalSince1970);
                                continue;
                            }
                            NSNumber *accepted = ledger[identifier];
                            if (immediate && ([ledger[shownKey] boolValue] || (accepted && accepted.doubleValue <= now.timeIntervalSince1970))) continue;
                            BOOL alreadyPending = NO;
                            for (UNNotificationRequest *request in pending) {
                                if ([request.identifier isEqual:identifier] && [request.content.userInfo[@"generation"] isEqual:generation] && (!immediate || [request.content.userInfo[@"immediate"] boolValue])) { alreadyPending = YES; break; }
                            }
                            if (alreadyPending) continue;
                            UNMutableNotificationContent *content = [UNMutableNotificationContent new];
                            content.title = title; content.body = body; content.sound = UNNotificationSound.defaultSound;
                            content.userInfo = @{@"generation": generation, @"immediate": @(immediate)};
                            NSTimeInterval delay = MAX(1.0, [due timeIntervalSinceDate:now]);
                            UNTimeIntervalNotificationTrigger *trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:delay repeats:NO];
                            UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:identifier content:content trigger:trigger];
                            dispatch_group_enter(group);
                            [self.center add:request completion:^(NSError *error) {
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    if (!error) ledger[identifier] = @([now timeIntervalSince1970] + delay);
                                    dispatch_group_leave(group);
                                });
                            }];
                        }
                        dispatch_group_notify(group, dispatch_get_main_queue(), ^{
                            [self.defaults setObject:ledger forKey:WFExpiryLedger];
                            [self finish];
                        });
                    });
                }];
            }];
        });
    }];
}
@end
