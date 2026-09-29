#import "WFInputValidation.h"
#import "WolFoxProStore.h"
#include <assert.h>

int main(void) { @autoreleasepool {
    for (id invalid in @[NSNull.null, @{}, @[], @"", @"not a number", @"12x", @(NAN), @(INFINITY)])
        assert(WFValidatedFiniteNumber(invalid) == nil);
    assert([WFValidatedFiniteNumber(@" 24.7136 ") doubleValue] == 24.7136);
    CLLocationCoordinate2D coordinate;
    assert(WFValidatedCoordinate(@0, @0, &coordinate));
    assert(coordinate.latitude == 0 && coordinate.longitude == 0);
    assert(!WFValidatedCoordinate(NSNull.null, @0, &coordinate));
    assert(!WFValidatedCoordinate(@91, @0, &coordinate));
    assert(!WFValidatedCoordinate(@0, @181, &coordinate));
    assert(!WFValidatedCoordinate(@(NAN), @0, &coordinate));
    assert([WFValidatedWeekdays(@[@1, @{}, @[], NSNull.null, @"3", @1, @2.5, @9]) isEqual:(@[@1, @3])]);
    assert(WFValidatedLocationID(@{}) == 0);
    assert(WFValidatedLocationID(@"42") == 42);
    assert(WFValidatedLocationID(@1.5) == 0);
    assert(WFValidatedLocationID(@(INFINITY)) == 0);
    assert(WFValidatedLocationID(@1e30) == 0);

    for (id invalid in @[NSNull.null, @{}, @[], @[NSNull.null], @[@[]], @[@{}],
                          @[@{@"lat":NSNull.null, @"lon":@0}], @[@{@"lat":@0, @"lon":@181}]])
        assert(WFValidatedMapSearchResult(invalid, @"query") == nil);
    NSDictionary *search = WFValidatedMapSearchResult(@[@{@"lat":@"0", @"lon":@"0", @"display_name":NSNull.null}], @"query");
    assert([search[@"display_name"] isEqual:@"query"] && [search[@"lat"] doubleValue] == 0);
    assert(WFValidatedMapSearchResult(@[@{@"lat":@"oops", @"lon":@0}], @"query") == nil);
    for (id invalid in @[NSNull.null, @[], @{}, @{@"elements":NSNull.null}, @{@"elements":@{}}])
        assert(WFValidatedOverpassElements(invalid) == nil);
    NSArray *places = WFValidatedOverpassElements(@{@"elements":@[
        NSNull.null, @[], @{@"center":NSNull.null}, @{@"id":@1, @"lat":@100, @"lon":@0},
        @{@"id":@2, @"center":@{@"lat":@"24.7", @"lon":@"46.6"}, @"tags":@{@"name":NSNull.null}},
        @{@"id":@3, @"lat":@0, @"lon":@0, @"tags":@{@"name:ar":@"مسجد", @"amenity":@"place_of_worship"}}
    ]});
    assert(places.count == 2);
    assert(places[0][@"tags"][@"name"] == nil);
    assert([places[1][@"tags"][@"name:ar"] isEqual:@"مسجد"]);

    // Exercise the actual store loader with malformed legacy preferences.
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    NSString *uuid = @"11111111-2222-4333-8444-555555555555";
    [defaults setObject:@[@"legacy", @[], @{@"uuid":@42},
                         @{@"uuid":uuid, @"name":@[], @"date":@{}},
                         @{@"uuid":uuid, @"name":@"kept", @"date":@"1727568000"}]
                forKey:@"WF_PRO_IDS"];
    [defaults setObject:@[@1, @{}, @[], @"3", @1, @2.5] forKey:@"WF_PRO_SCHEDULE_DAYS"];
    [defaults setBool:YES forKey:@"WF_PRO_SCHEDULE_COMMITTED_V1"];
    [defaults setObject:@[@{}, @2, @7, @2] forKey:@"WF_PRO_SCHEDULE_COMMITTED_DAYS"];
    [defaults setObject:@{} forKey:@"WF_PRO_SCHEDULE_LOCATION_ID"];
    [defaults setObject:@[] forKey:@"WF_PRO_SCHEDULE_COMMITTED_LOCATION_ID"];
    WolFoxProStore *store = [WolFoxProStore new];
    assert(store.identifiers.count == 2);
    assert([((WolFoxProIdentifier *)store.identifiers[0]).name isEqual:@""]);
    assert([((WolFoxProIdentifier *)store.identifiers[1]).name isEqual:@"kept"]);
    assert([store.scheduleWeekdays isEqual:(@[@1, @3])]);
    assert([store.committedScheduleWeekdays isEqual:(@[@2, @7])]);
    assert(store.scheduleLocationID == 0 && store.committedScheduleLocationID == 0);
    [store saveSettings];
    WolFoxProStore *reloaded = [WolFoxProStore new];
    assert(reloaded.identifiers.count == 2);
    assert([reloaded.scheduleWeekdays isEqual:store.scheduleWeekdays]);
    assert([reloaded.committedScheduleWeekdays isEqual:store.committedScheduleWeekdays]);
    puts("Malformed map responses and saved preferences are rejected; valid data survives reload");
} return 0; }
