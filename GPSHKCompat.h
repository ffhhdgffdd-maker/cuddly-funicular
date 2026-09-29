#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

NS_ASSUME_NONNULL_BEGIN

@interface GPSHKSavedLocation : NSObject <NSSecureCoding>
@property (nonatomic, assign) NSInteger locationID;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) CLLocationDegrees latitude;
@property (nonatomic, assign) CLLocationDegrees longitude;
@property (nonatomic, assign) CLLocationDistance altitude;
@property (nonatomic, assign) NSTimeInterval lastUsedAt;
@end

@interface GPSHKRoutePoint : NSObject <NSSecureCoding>
@property (nonatomic, assign) CLLocationDegrees latitude;
@property (nonatomic, assign) CLLocationDegrees longitude;
@property (nonatomic, assign) CLLocationDistance altitude;
@end

@interface GPSHKCompatStore : NSObject
+ (instancetype)shared;
@property (nonatomic, readonly) NSArray<GPSHKSavedLocation *> *locations;
@property (nonatomic, strong, nullable) GPSHKSavedLocation *activeLocation;
@property (nonatomic, assign) BOOL spoofingEnabled;
@property (nonatomic, assign) BOOL routeLoop;
@property (nonatomic, copy, nullable) NSString *gpxName;
@property (nonatomic, copy, nullable) NSString *activeIdentifierUUID;
@property (nonatomic, assign) CLLocationDegrees jitterMeters;
- (GPSHKSavedLocation *)saveLocationNamed:(NSString *)name
                                 latitude:(CLLocationDegrees)latitude
                                longitude:(CLLocationDegrees)longitude
                                 altitude:(CLLocationDistance)altitude;
- (BOOL)deleteLocationID:(NSInteger)locationID;
- (nullable GPSHKSavedLocation *)locationWithID:(NSInteger)locationID;
- (void)activateLocationID:(NSInteger)locationID;
- (void)stopSpoofing;
- (CLLocation *)currentSpoofLocation;
- (NSArray<GPSHKRoutePoint *> *)parseGPXData:(NSData *)data error:(NSError **)error;
@end

NS_ASSUME_NONNULL_END
