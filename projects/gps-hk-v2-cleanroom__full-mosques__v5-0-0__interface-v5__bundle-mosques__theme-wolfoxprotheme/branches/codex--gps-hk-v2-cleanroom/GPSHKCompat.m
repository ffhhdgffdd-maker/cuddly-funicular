#import "GPSHKCompat.h"

static NSString * const GPSHKLocationsKey = @"GPSHKCompat.locations";
static NSString * const GPSHKActiveLocationKey = @"GPSHKCompat.activeLocationID";
static NSString * const GPSHKSpoofingKey = @"GPSHKCompat.spoofingEnabled";
static NSString * const GPSHKIdentifierKey = @"GPSHKCompat.identifierUUID";
static NSString * const GPSHKRouteLoopKey = @"GPSHKCompat.routeLoop";
static NSString * const GPSHKGpxNameKey = @"GPSHKCompat.gpxName";
static NSString * const GPSHKJitterMetersKey = @"GPSHKCompat.jitterMeters";

@implementation GPSHKSavedLocation
+ (BOOL)supportsSecureCoding { return YES; }
- (instancetype)initWithCoder:(NSCoder *)coder {
    if ((self = [super init])) {
        _locationID = [coder decodeIntegerForKey:@"locationID"];
        _name = [coder decodeObjectOfClass:NSString.class forKey:@"name"] ?: @"Location";
        _latitude = [coder decodeDoubleForKey:@"latitude"];
        _longitude = [coder decodeDoubleForKey:@"longitude"];
        _altitude = [coder decodeDoubleForKey:@"altitude"];
        _lastUsedAt = [coder decodeDoubleForKey:@"lastUsedAt"];
    }
    return self;
}
- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeInteger:self.locationID forKey:@"locationID"];
    [coder encodeObject:self.name forKey:@"name"];
    [coder encodeDouble:self.latitude forKey:@"latitude"];
    [coder encodeDouble:self.longitude forKey:@"longitude"];
    [coder encodeDouble:self.altitude forKey:@"altitude"];
    [coder encodeDouble:self.lastUsedAt forKey:@"lastUsedAt"];
}
@end

@implementation GPSHKRoutePoint
+ (BOOL)supportsSecureCoding { return YES; }
- (instancetype)initWithCoder:(NSCoder *)coder {
    if ((self = [super init])) {
        _latitude = [coder decodeDoubleForKey:@"latitude"];
        _longitude = [coder decodeDoubleForKey:@"longitude"];
        _altitude = [coder decodeDoubleForKey:@"altitude"];
    }
    return self;
}
- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeDouble:self.latitude forKey:@"latitude"];
    [coder encodeDouble:self.longitude forKey:@"longitude"];
    [coder encodeDouble:self.altitude forKey:@"altitude"];
}
@end

@interface GPSHKGPXParser : NSObject <NSXMLParserDelegate>
@property (nonatomic, strong) NSMutableArray<GPSHKRoutePoint *> *points;
@property (nonatomic, strong, nullable) GPSHKRoutePoint *current;
@property (nonatomic, strong) NSMutableString *text;
@end

@implementation GPSHKGPXParser
- (instancetype)init {
    if ((self = [super init])) {
        _points = [NSMutableArray array];
        _text = [NSMutableString string];
    }
    return self;
}
- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary<NSString *,NSString *> *)attributeDict {
    (void)parser; (void)namespaceURI; (void)qName;
    [self.text setString:@""];
    if ([elementName isEqualToString:@"trkpt"] || [elementName isEqualToString:@"wpt"] || [elementName isEqualToString:@"rtept"]) {
        GPSHKRoutePoint *p = [GPSHKRoutePoint new];
        p.latitude = attributeDict[@"lat"].doubleValue;
        p.longitude = attributeDict[@"lon"].doubleValue;
        p.altitude = 0;
        self.current = p;
    }
}
- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    (void)parser;
    [self.text appendString:string];
}
- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
    (void)parser; (void)namespaceURI; (void)qName;
    if ([elementName isEqualToString:@"ele"] && self.current) self.current.altitude = self.text.doubleValue;
    if (([elementName isEqualToString:@"trkpt"] || [elementName isEqualToString:@"wpt"] || [elementName isEqualToString:@"rtept"]) && self.current) {
        CLLocationCoordinate2D c = CLLocationCoordinate2DMake(self.current.latitude, self.current.longitude);
        if (CLLocationCoordinate2DIsValid(c)) [self.points addObject:self.current];
        self.current = nil;
    }
}
@end

@interface GPSHKCompatStore ()
@property (nonatomic, strong) NSMutableArray<GPSHKSavedLocation *> *mutableLocations;
@property (nonatomic, assign) NSInteger nextLocationID;
@end

@implementation GPSHKCompatStore
+ (instancetype)shared {
    static GPSHKCompatStore *store;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ store = [GPSHKCompatStore new]; });
    return store;
}
- (instancetype)init {
    if ((self = [super init])) {
        _mutableLocations = [NSMutableArray array];
        NSUserDefaults *d = NSUserDefaults.standardUserDefaults;
        NSData *saved = [d dataForKey:GPSHKLocationsKey];
        if (saved.length) {
            NSSet *classes = [NSSet setWithObjects:NSArray.class, GPSHKSavedLocation.class, NSString.class, nil];
            NSArray *decoded = [NSKeyedUnarchiver unarchivedObjectOfClasses:classes fromData:saved error:NULL];
            if ([decoded isKindOfClass:NSArray.class]) [_mutableLocations addObjectsFromArray:decoded];
        }
        _nextLocationID = 1;
        for (GPSHKSavedLocation *l in _mutableLocations) _nextLocationID = MAX(_nextLocationID, l.locationID + 1);
        _spoofingEnabled = [d boolForKey:GPSHKSpoofingKey];
        _routeLoop = [d boolForKey:GPSHKRouteLoopKey];
        _gpxName = [d stringForKey:GPSHKGpxNameKey];
        _activeIdentifierUUID = [d stringForKey:GPSHKIdentifierKey];
        _jitterMeters = [d doubleForKey:GPSHKJitterMetersKey];
        NSInteger activeID = [d integerForKey:GPSHKActiveLocationKey];
        _activeLocation = [self locationWithID:activeID];
    }
    return self;
}
- (NSArray<GPSHKSavedLocation *> *)locations { return [self.mutableLocations copy]; }
- (void)persist {
    NSUserDefaults *d = NSUserDefaults.standardUserDefaults;
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self.mutableLocations requiringSecureCoding:YES error:NULL];
    if (data) [d setObject:data forKey:GPSHKLocationsKey];
    [d setInteger:self.activeLocation.locationID forKey:GPSHKActiveLocationKey];
    [d setBool:self.spoofingEnabled forKey:GPSHKSpoofingKey];
    [d setBool:self.routeLoop forKey:GPSHKRouteLoopKey];
    if (self.gpxName) [d setObject:self.gpxName forKey:GPSHKGpxNameKey]; else [d removeObjectForKey:GPSHKGpxNameKey];
    if (self.activeIdentifierUUID) [d setObject:self.activeIdentifierUUID forKey:GPSHKIdentifierKey]; else [d removeObjectForKey:GPSHKIdentifierKey];
    [d setDouble:self.jitterMeters forKey:GPSHKJitterMetersKey];
}
- (GPSHKSavedLocation *)saveLocationNamed:(NSString *)name latitude:(CLLocationDegrees)latitude longitude:(CLLocationDegrees)longitude altitude:(CLLocationDistance)altitude {
    GPSHKSavedLocation *l = [GPSHKSavedLocation new];
    l.locationID = self.nextLocationID++;
    l.name = name.length ? name : [NSString stringWithFormat:@"Location %ld", (long)l.locationID];
    l.latitude = latitude;
    l.longitude = longitude;
    l.altitude = altitude;
    l.lastUsedAt = NSDate.date.timeIntervalSince1970;
    [self.mutableLocations addObject:l];
    [self persist];
    return l;
}
- (BOOL)deleteLocationID:(NSInteger)locationID {
    NSUInteger idx = [self.mutableLocations indexOfObjectPassingTest:^BOOL(GPSHKSavedLocation *obj, NSUInteger idx, BOOL *stop) {
        (void)idx; (void)stop; return obj.locationID == locationID;
    }];
    if (idx == NSNotFound) return NO;
    if (self.activeLocation.locationID == locationID) { self.activeLocation = nil; self.spoofingEnabled = NO; }
    [self.mutableLocations removeObjectAtIndex:idx];
    [self persist];
    return YES;
}
- (GPSHKSavedLocation *)locationWithID:(NSInteger)locationID {
    for (GPSHKSavedLocation *l in self.mutableLocations) if (l.locationID == locationID) return l;
    return nil;
}
- (void)activateLocationID:(NSInteger)locationID {
    GPSHKSavedLocation *l = [self locationWithID:locationID];
    if (!l) return;
    l.lastUsedAt = NSDate.date.timeIntervalSince1970;
    self.activeLocation = l;
    self.spoofingEnabled = YES;
    [self persist];
}
- (void)stopSpoofing { self.spoofingEnabled = NO; [self persist]; }
- (CLLocation *)currentSpoofLocation {
    GPSHKSavedLocation *l = self.activeLocation;
    if (!self.spoofingEnabled || !l) return nil;
    CLLocationDegrees lat = l.latitude, lon = l.longitude;
    if (self.jitterMeters > 0.01) {
        double angle = ((double)arc4random_uniform(36000) / 100.0) * M_PI / 180.0;
        double radius = ((double)arc4random_uniform(10000) / 10000.0) * self.jitterMeters;
        lat += (radius * cos(angle)) / 111111.0;
        double denom = MAX(1000.0, 111111.0 * cos(lat * M_PI / 180.0));
        lon += (radius * sin(angle)) / denom;
    }
    CLLocationCoordinate2D c = CLLocationCoordinate2DMake(lat, lon);
    return [[CLLocation alloc] initWithCoordinate:c altitude:l.altitude horizontalAccuracy:5 verticalAccuracy:5 course:-1 speed:-1 timestamp:NSDate.date];
}
- (NSArray<GPSHKRoutePoint *> *)parseGPXData:(NSData *)data error:(NSError **)error {
    GPSHKGPXParser *delegate = [GPSHKGPXParser new];
    NSXMLParser *parser = [[NSXMLParser alloc] initWithData:data ?: NSData.data];
    parser.delegate = delegate;
    BOOL ok = [parser parse];
    if (!ok && error) *error = parser.parserError;
    return ok ? [delegate.points copy] : @[];
}
- (void)setSpoofingEnabled:(BOOL)v { _spoofingEnabled = v; [self persist]; }
- (void)setRouteLoop:(BOOL)v { _routeLoop = v; [self persist]; }
- (void)setGpxName:(NSString *)v { _gpxName = [v copy]; [self persist]; }
- (void)setActiveIdentifierUUID:(NSString *)v { _activeIdentifierUUID = [v copy]; [self persist]; }
- (void)setJitterMeters:(CLLocationDegrees)v { _jitterMeters = MAX(0, v); [self persist]; }
@end
