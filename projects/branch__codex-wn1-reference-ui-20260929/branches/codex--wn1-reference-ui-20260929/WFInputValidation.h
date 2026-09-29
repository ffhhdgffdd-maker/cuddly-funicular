#ifndef WF_INPUT_VALIDATION_H
#define WF_INPUT_VALIDATION_H

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#include <math.h>

// JSON and older preference files are untyped at runtime. Validate before
// subscripting or sending numeric/string selectors; never reset valid data.
static inline NSString *WFValidatedString(id value) {
    return [value isKindOfClass:NSString.class] ? value : nil;
}

static inline NSNumber *WFValidatedFiniteNumber(id value) {
    double number;
    if ([value isKindOfClass:NSNumber.class]) {
        number = [value doubleValue];
    } else if ([value isKindOfClass:NSString.class]) {
        NSString *text = [value stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
        if (!text.length) return nil;
        NSScanner *scanner = [NSScanner scannerWithString:text];
        scanner.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
        if (![scanner scanDouble:&number] || !scanner.isAtEnd) return nil;
    } else {
        return nil;
    }
    return isfinite(number) ? @(number) : nil;
}

static inline BOOL WFValidatedCoordinate(id latitude, id longitude, CLLocationCoordinate2D *result) {
    NSNumber *lat = WFValidatedFiniteNumber(latitude), *lon = WFValidatedFiniteNumber(longitude);
    if (!lat || !lon) return NO;
    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(lat.doubleValue, lon.doubleValue);
    if (!CLLocationCoordinate2DIsValid(coordinate)) return NO;
    if (result) *result = coordinate;
    return YES;
}

static inline NSArray<NSNumber *> *WFValidatedWeekdays(id value) {
    NSMutableArray<NSNumber *> *days = [NSMutableArray new];
    if (![value isKindOfClass:NSArray.class]) return days;
    for (id item in value) {
        NSNumber *number = WFValidatedFiniteNumber(item);
        double day = number.doubleValue;
        if (number && day >= 1 && day <= 7 && floor(day) == day && ![days containsObject:@((NSInteger)day)])
            [days addObject:@((NSInteger)day)];
    }
    return [days copy];
}

static inline long long WFValidatedLocationID(id value) {
    NSNumber *number = WFValidatedFiniteNumber(value);
    double identifier = number.doubleValue;
    if (!number || identifier < 1 || identifier >= 9223372036854775808.0 || floor(identifier) != identifier) return 0;
    return number.longLongValue;
}

static inline NSDictionary *WFValidatedMapSearchResult(id json, NSString *query) {
    if (![json isKindOfClass:NSArray.class]) return nil;
    id first = [json firstObject];
    if (![first isKindOfClass:NSDictionary.class]) return nil;
    CLLocationCoordinate2D coordinate;
    if (!WFValidatedCoordinate(first[@"lat"], first[@"lon"], &coordinate)) return nil;
    NSString *name = WFValidatedString(first[@"display_name"]);
    return @{@"lat": @(coordinate.latitude), @"lon": @(coordinate.longitude),
             @"display_name": name.length ? name : (query ?: @"")};
}

static inline NSArray<NSDictionary *> *WFValidatedOverpassElements(id json) {
    if (![json isKindOfClass:NSDictionary.class] || ![json[@"elements"] isKindOfClass:NSArray.class]) return nil;
    NSMutableArray *valid = [NSMutableArray new];
    for (id element in json[@"elements"]) {
        if (![element isKindOfClass:NSDictionary.class]) continue;
        NSDictionary *center = [element[@"center"] isKindOfClass:NSDictionary.class] ? element[@"center"] : nil;
        CLLocationCoordinate2D coordinate;
        if (!WFValidatedCoordinate(element[@"lat"] ?: center[@"lat"], element[@"lon"] ?: center[@"lon"], &coordinate)) continue;
        NSDictionary *rawTags = [element[@"tags"] isKindOfClass:NSDictionary.class] ? element[@"tags"] : @{};
        NSMutableDictionary *tags = [NSMutableDictionary new];
        for (NSString *key in @[@"name:ar", @"name", @"amenity", @"healthcare"]) {
            NSString *text = WFValidatedString(rawTags[key]);
            if (text) tags[key] = text;
        }
        id identifier = element[@"id"];
        if (![identifier isKindOfClass:NSString.class] && ![identifier isKindOfClass:NSNumber.class]) continue;
        [valid addObject:@{@"lat": @(coordinate.latitude), @"lon": @(coordinate.longitude),
                          @"tags": tags, @"type": WFValidatedString(element[@"type"]) ?: @"poi", @"id": identifier}];
    }
    return [valid copy];
}

#endif
