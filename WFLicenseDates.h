#import <Foundation/Foundation.h>

static inline NSDate *WFParseLicenseDate(NSString *value) {
    if (![value isKindOfClass:NSString.class] || !value.length) return nil;
    NSISO8601DateFormatter *iso = [NSISO8601DateFormatter new];
    NSDate *date = [iso dateFromString:value];
    if (date) return date;
    iso.formatOptions = NSISO8601DateFormatWithInternetDateTime | NSISO8601DateFormatWithFractionalSeconds;
    date = [iso dateFromString:value];
    if (date) return date;
    NSDateFormatter *formatter = [NSDateFormatter new];
    formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    formatter.calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    formatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    formatter.lenient = NO;
    for (NSString *format in @[@"yyyy-MM-dd HH:mm:ss", @"yyyy-MM-dd'T'HH:mm:ssZ", @"yyyy-MM-dd"]) {
        formatter.dateFormat = format;
        date = [formatter dateFromString:value];
        if (date) return date;
    }
    return nil;
}
