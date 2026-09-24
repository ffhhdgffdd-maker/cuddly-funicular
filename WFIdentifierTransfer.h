#import <Foundation/Foundation.h>

// A transfer contains one user-selected UUID, never Keychain credentials.
static const NSUInteger WFIdentifierTransferMaxBytes = 65536;

static inline NSString *WFTransferUUID(id value) {
    if (![value isKindOfClass:NSString.class]) return nil;
    NSString *text = [value stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if ([text.lowercaseString hasPrefix:@"urn:uuid:"]) text = [text substringFromIndex:9];
    if ([text hasPrefix:@"{"] && [text hasSuffix:@"}"] && text.length > 2)
        text = [text substringWithRange:NSMakeRange(1, text.length - 2)];
    if (text.length != 36) return nil;
    return [[NSUUID alloc] initWithUUIDString:text].UUIDString;
}

static inline NSString *WFIdentifierFromTransfer(NSData *data, NSString *bundleID, NSString **errorMessage) {
    if (errorMessage) *errorMessage = nil;
    if (!data.length || data.length > WFIdentifierTransferMaxBytes) {
        if (errorMessage) *errorMessage = @"اختر ملف معرّف غير فارغ بحجم لا يتجاوز 64 كيلوبايت.";
        return nil;
    }
    NSString *plain = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSString *uuid = WFTransferUUID(plain);
    if (uuid) return uuid;
    id payload = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
    if (!payload) {
        // GPS Plus v4 export uses byte-wise XOR 0x5A, not plain text.
        NSMutableData *decoded = [data mutableCopy];
        unsigned char *bytes = (unsigned char *)decoded.mutableBytes;
        for (NSUInteger i = 0; i < decoded.length; i++) bytes[i] ^= 0x5A;
        payload = [NSJSONSerialization JSONObjectWithData:decoded options:0 error:NULL];
    }
    if (![payload isKindOfClass:NSDictionary.class]) {
        if (errorMessage) *errorMessage = @"الملف غير صالح. اختر ملف تصدير GPS Plus أو WolFox أو ملف UUID نصي.";
        return nil;
    }
    NSDictionary *document = payload;
    if ([[document objectForKey:@"format"] isEqual:@"wolfox.identifier"]) {
        if (![[document objectForKey:@"version"] isEqual:@1]) {
            if (errorMessage) *errorMessage = @"إصدار ملف WolFox غير مدعوم.";
            return nil;
        }
        id target = [document objectForKey:@"bundle_id"];
        if (![target isKindOfClass:NSString.class] || ![target isEqual:bundleID]) {
            if (errorMessage) *errorMessage = @"ملف المعرّف مخصص لتطبيق آخر.";
            return nil;
        }
        uuid = WFTransferUUID([document objectForKey:@"uuid"]);
    } else if ([[document objectForKey:@"version"] isEqual:@"4.0"] &&
               ([document objectForKey:@"idf"] || [document objectForKey:@"custom_uuid"])) {
        id custom = [document objectForKey:@"custom_uuid"];
        // Prefer the explicitly saved custom UUID. Never silently substitute a
        // device/security identifier from the exported Keychain dictionary.
        BOOL hasCustom = custom && custom != NSNull.null &&
            !([custom isKindOfClass:NSString.class] && ![(NSString *)custom length]);
        uuid = WFTransferUUID(hasCustom ? custom : [document objectForKey:@"idf"]);
    } else {
        if (errorMessage) *errorMessage = @"صيغة ملف المعرّف أو إصداره غير مدعوم.";
        return nil;
    }
    if (!uuid && errorMessage) *errorMessage = @"الملف لا يحتوي معرّف UUID صالحًا.";
    return uuid;
}

static inline NSData *WFIdentifierExport(NSString *uuid, NSString *bundleID) {
    NSString *normalized = WFTransferUUID(uuid);
    if (!normalized || !bundleID.length) return nil;
    return [NSJSONSerialization dataWithJSONObject:@{
        @"format": @"wolfox.identifier", @"version": @1,
        @"bundle_id": bundleID, @"uuid": normalized
    } options:NSJSONWritingPrettyPrinted error:NULL];
}
