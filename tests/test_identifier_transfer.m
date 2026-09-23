#import <Foundation/Foundation.h>
#import "WFIdentifierTransfer.h"
#include <assert.h>

static NSData *JSON(id object) {
    return [NSJSONSerialization dataWithJSONObject:object options:0 error:NULL];
}
static NSData *Encode(NSData *data) {
    NSMutableData *encoded = [data mutableCopy];
    unsigned char *bytes = encoded.mutableBytes;
    for (NSUInteger i = 0; i < encoded.length; ++i) bytes[i] ^= 0x5A;
    return encoded;
}
int main(int argc, const char *argv[]) {
    @autoreleasepool {
        NSString *bundle = @"sa.gov.moia.mosques-2";
        NSString *first = @"11111111-2222-4333-8444-555555555555";
        NSString *custom = @"AAAAAAAA-BBBB-4CCC-8DDD-EEEEEEEEEEEE";
        NSString *error = nil;
        assert([WFIdentifierFromTransfer([first dataUsingEncoding:NSUTF8StringEncoding], bundle, &error) isEqual:first]);
        assert(error == nil);
        assert([WFTransferUUID([NSString stringWithFormat:@" urn:uuid:{%@} \n", first]) isEqual:first]);
        assert(WFTransferUUID(@42) == nil);
        NSDictionary *gps = @{@"version":@"4.0", @"idf":first, @"custom_uuid":custom,
            @"keychain":@{@"talSec":@"do-not-import"}, @"keychain_locations":@[@{@"service":@"flutter_secure_storage_service", @"account":@"appUUID", @"value":first}]};
        assert([WFIdentifierFromTransfer(JSON(gps), bundle, &error) isEqual:custom]);
        assert([WFIdentifierFromTransfer(Encode(JSON(gps)), bundle, &error) isEqual:custom]);
        assert([WFIdentifierFromTransfer(JSON(@{@"version":@"4.0", @"idf":first, @"custom_uuid":@""}), bundle, &error) isEqual:first]);
        assert([WFIdentifierFromTransfer(JSON(@{@"version":@"4.0", @"idf":first, @"custom_uuid":NSNull.null}), bundle, &error) isEqual:first]);
        assert(WFIdentifierFromTransfer(JSON(@{@"version":@"4.0", @"idf":first, @"custom_uuid":@"invalid"}), bundle, &error) == nil);
        assert(error.length);
        assert(WFIdentifierFromTransfer(JSON(@{@"version":@"4.0", @"idf":first, @"custom_uuid":@[]}), bundle, &error) == nil);
        assert(WFIdentifierFromTransfer(JSON(@{@"version":@"4.0", @"keychain":@{@"deviceUID":first}}), bundle, &error) == nil);
        assert(WFIdentifierFromTransfer(JSON(@[]), bundle, &error) == nil);
        assert(WFIdentifierFromTransfer([@"bad file" dataUsingEncoding:NSUTF8StringEncoding], bundle, &error) == nil);
        assert(WFIdentifierFromTransfer(NSData.data, bundle, &error) == nil);
        assert(WFIdentifierFromTransfer([NSMutableData dataWithLength:65537], bundle, &error) == nil);
        NSData *exported = WFIdentifierExport(custom, bundle);
        assert(exported.length);
        assert([WFIdentifierFromTransfer(exported, bundle, &error) isEqual:custom]);
        assert(error == nil);
        assert(WFIdentifierFromTransfer(exported, @"other.app", &error) == nil);
        assert(WFIdentifierFromTransfer(JSON(@{@"format":@"wolfox.identifier", @"version":@2, @"uuid":first, @"bundle_id":bundle}), bundle, &error) == nil);
        assert(WFIdentifierExport(@"bad", bundle) == nil);
        assert(WFIdentifierExport(first, @"") == nil);
        NSDictionary *document = [NSJSONSerialization JSONObjectWithData:exported options:0 error:NULL];
        assert(document.count == 4 && document[@"keychain"] == nil);
        // Optional local fixture validation does not print personal identifiers.
        if (argc > 1) {
            NSData *fixture = [NSData dataWithContentsOfFile:[NSString stringWithUTF8String:argv[1]]];
            assert(WFIdentifierFromTransfer(fixture, bundle, &error).length == 36);
        }
        puts("Identifier transfer: all parser and export checks passed.");
    }
    return 0;
}
