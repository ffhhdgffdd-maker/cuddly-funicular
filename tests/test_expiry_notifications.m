#import "WFExpiryNotifications.h"
#import "WFLicenseDates.h"
#include <assert.h>
#include <math.h>

@interface FakeExpiryCenter : NSObject <WFExpiryNotificationCenter>
@property (nonatomic) BOOL allowed;
@property (nonatomic) BOOL fail;
@property (nonatomic) NSUInteger attempts;
@property (nonatomic, strong) NSMutableDictionary<NSString *, UNNotificationRequest *> *requests;
@property (nonatomic, strong) NSMutableArray<NSString *> *deliveredIDs;
@end
@implementation FakeExpiryCenter
- (instancetype)init { if ((self = [super init])) { _allowed = YES; _requests = [NSMutableDictionary new]; _deliveredIDs = [NSMutableArray new]; } return self; }
- (void)authorization:(void (^)(BOOL))done { done(self.allowed); }
- (void)pending:(void (^)(NSArray<UNNotificationRequest *> *))done { done(self.requests.allValues); }
- (void)delivered:(void (^)(NSArray<NSString *> *))done { done(self.deliveredIDs); }
- (void)add:(UNNotificationRequest *)request completion:(void (^)(NSError *))done {
    self.attempts++;
    if (self.fail) { done([NSError errorWithDomain:@"test" code:1 userInfo:nil]); return; }
    self.requests[request.identifier] = request; done(nil);
}
- (void)remove:(NSArray<NSString *> *)ids { [self.requests removeObjectsForKeys:ids]; [self.deliveredIDs removeObjectsInArray:ids]; }
@end

static void WFTestExpirySettle(WFExpiryNotifications *service) {
    __block BOOL queued = NO;
    dispatch_async(dispatch_get_main_queue(), ^{ queued = YES; });
    NSDate *limit = [NSDate dateWithTimeIntervalSinceNow:3];
    while ((!queued || [[service valueForKey:@"busy"] boolValue] || [service valueForKey:@"nextUpdate"]) && limit.timeIntervalSinceNow > 0) {
        [NSRunLoop.currentRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.005]];
    }
    assert(queued && ![[service valueForKey:@"busy"] boolValue] && ![service valueForKey:@"nextUpdate"]);
}
static NSTimeInterval WFTestExpiryDelay(FakeExpiryCenter *center, NSString *identifier) {
    return ((UNTimeIntervalNotificationTrigger *)center.requests[identifier].trigger).timeInterval;
}

int main(void) { @autoreleasepool {
    NSDate *base = WFParseLicenseDate(@"2026-10-01T00:00:00Z");
    assert(base && [base isEqual:WFParseLicenseDate(@"2026-10-01 00:00:00")]);
    assert([base isEqual:WFParseLicenseDate(@"2026-10-01T03:00:00+03:00")]);
    assert(fabs([WFParseLicenseDate(@"2026-10-01T00:00:00.125Z") timeIntervalSinceDate:base] - 0.125) < 0.001);
    assert(!WFParseLicenseDate(@"not a date"));
    NSString *domain = [@"wolfox.test.expiry." stringByAppendingString:NSUUID.UUID.UUIDString];
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:domain];
    FakeExpiryCenter *center = [FakeExpiryCenter new];
    __block NSDate *now = base;
    WFExpiryNotifications *(^make)(void) = ^{ return [[WFExpiryNotifications alloc] initWithCenter:center defaults:defaults clock:^{ return now; }]; };
    WFExpiryNotifications *service = make();
    NSString *soon = @"wolfox.expiry.reminder", *ended = @"wolfox.expiry.ended";
    [service updateEnabled:YES code:@"TEST-CODE" expiry:@"2026-10-11T00:00:00Z" state:WFExpiryStateActive]; WFTestExpirySettle(service);
    assert(center.requests.count == 2 && WFTestExpiryDelay(center, soon) == 7 * 86400 && WFTestExpiryDelay(center, ended) == 10 * 86400);
    NSUInteger count = center.attempts;
    [service updateEnabled:YES code:@"TEST-CODE" expiry:@"2026-10-11T03:00:00+03:00" state:WFExpiryStateActive]; WFTestExpirySettle(service);
    assert(center.attempts == count); // Equivalent time zones do not create another generation.
    service = make();
    [service updateEnabled:YES code:@"TEST-CODE" expiry:@"2026-10-11T00:00:00Z" state:WFExpiryStateActive]; WFTestExpirySettle(service);
    assert(center.attempts == count); // Restart retains the schedule.
    [service updateEnabled:YES code:@"TEST-CODE" expiry:@"2026-11-01T00:00:00Z" state:WFExpiryStateActive]; WFTestExpirySettle(service);
    assert(center.attempts == count + 2 && WFTestExpiryDelay(center, ended) == 31 * 86400); // Renewal replaces both.
    [service updateEnabled:YES code:@"TEST-CODE" expiry:nil state:WFExpiryStateUncertain]; WFTestExpirySettle(service);
    assert(center.requests.count == 2); // Temporary failures preserve pending reminders.
    [service updateEnabled:YES code:@"TEST-CODE" expiry:@"2026-10-03T00:00:00Z" state:WFExpiryStateActive]; WFTestExpirySettle(service);
    assert(WFTestExpiryDelay(center, soon) == 1 && WFTestExpiryDelay(center, ended) == 2 * 86400); // First launch inside three days.
    count = center.attempts;
    now = [base dateByAddingTimeInterval:2]; [center.requests removeObjectForKey:soon];
    [service updateEnabled:YES code:@"TEST-CODE" expiry:@"2026-10-03T00:00:00Z" state:WFExpiryStateActive]; WFTestExpirySettle(service);
    assert(center.attempts == count); // Delivered/dismissed reminder is not resubmitted.
    [service updateEnabled:YES code:@"TEST-CODE" expiry:@"2026-10-03T00:00:00Z" state:WFExpiryStateExpired]; WFTestExpirySettle(service);
    assert(center.requests.count == 1 && WFTestExpiryDelay(center, ended) == 1); // Server expiry overrides a future pending alert.
    now = [base dateByAddingTimeInterval:5]; [center.requests removeAllObjects]; count = center.attempts;
    [service updateEnabled:YES code:@"TEST-CODE" expiry:@"2026-10-03T00:00:00Z" state:WFExpiryStateExpired]; WFTestExpirySettle(service);
    assert(center.attempts == count);
    [service updateEnabled:NO code:@"TEST-CODE" expiry:nil state:WFExpiryStateUncertain]; WFTestExpirySettle(service);
    [service updateEnabled:YES code:@"TEST-CODE" expiry:@"2026-10-03T00:00:00Z" state:WFExpiryStateExpired]; WFTestExpirySettle(service);
    assert(center.requests.count == 0 && center.attempts == count); // Toggle must not repeat the expired alert.
    center.fail = YES;
    [service updateEnabled:YES code:@"ANOTHER" expiry:@"2026-10-10T00:00:00Z" state:WFExpiryStateActive]; WFTestExpirySettle(service);
    count = center.attempts; assert(center.requests.count == 0);
    center.fail = NO;
    [service updateEnabled:YES code:@"ANOTHER" expiry:@"2026-10-10T00:00:00Z" state:WFExpiryStateActive]; WFTestExpirySettle(service);
    assert(center.attempts == count + 2 && center.requests.count == 2); // Failed additions are retried.
    center.allowed = NO;
    [service updateEnabled:YES code:@"DENIED" expiry:@"2026-10-02T00:00:00Z" state:WFExpiryStateActive]; WFTestExpirySettle(service);
    assert(center.requests.count == 0);
    center.allowed = YES;
    [service updateEnabled:YES code:@"DENIED" expiry:@"2026-10-02T00:00:00Z" state:WFExpiryStateActive]; WFTestExpirySettle(service);
    assert(center.requests.count == 2);
    [service updateEnabled:YES code:@"DENIED" expiry:nil state:WFExpiryStateNone]; WFTestExpirySettle(service);
    assert(center.requests.count == 0); // Revocation clears stale notifications.
    __block NSUInteger banners = 0;
    service.presentNotice = ^BOOL(NSString *title, NSString *body) { assert(title.length && body.length); banners++; return YES; };
    [service updateEnabled:YES code:@"FOREGROUND" expiry:@"2026-10-02T00:00:00Z" state:WFExpiryStateActive]; WFTestExpirySettle(service);
    assert(banners == 1 && center.requests.count == 1 && center.requests[ended]);
    [service updateEnabled:YES code:@"FOREGROUND" expiry:@"2026-10-02T00:00:00Z" state:WFExpiryStateActive]; WFTestExpirySettle(service);
    assert(banners == 1);
    now = [base dateByAddingTimeInterval:86400];
    [service updateEnabled:YES code:@"FOREGROUND" expiry:@"2026-10-02T00:00:00Z" state:WFExpiryStateActive]; WFTestExpirySettle(service);
    assert(banners == 2 && center.requests.count == 0);
    [service updateEnabled:YES code:@"FOREGROUND" expiry:@"2026-10-02T00:00:00Z" state:WFExpiryStateExpired]; WFTestExpirySettle(service);
    assert(banners == 2);
    assert(![[defaults dictionaryRepresentation].description containsString:@"FOREGROUND"]);
    [defaults removePersistentDomainForName:domain];
    puts("Expiry notifications: dates, 72h, late activation, expiry, renewal, restart, permissions, retries and foreground passed");
} return 0; }
