//
//  JSLocationManager.m
//  Weathor
//
//  Created by Jeff Spingeld on 7/14/16.
//  Copyright © 2016 Jeff Spingeld. All rights reserved.
//

#import "JDSLocationClient.h"
#import "JDSAPIClient.h"

@interface JDSLocationClient () <CLLocationManagerDelegate>

@property (strong, nonatomic) CLLocationManager *locationManager;

@end

@implementation JDSLocationClient

-(void)getCurrentLocation {
    
    // Create a location manager with self as its delegate
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
    self.locationManager.delegate = self;
    
    switch (CLLocationManager.authorizationStatus) {
            
        case kCLAuthorizationStatusDenied:
        case kCLAuthorizationStatusRestricted:
            // Don't have location authorization, can't do anything.
            break;
            
        case kCLAuthorizationStatusNotDetermined:
            
            // Ask for authorization (will call didChangeAuthorizationStatus delegate method if granted)
            [self.locationManager requestWhenInUseAuthorization];
            
        case kCLAuthorizationStatusAuthorizedAlways:
        case kCLAuthorizationStatusAuthorizedWhenInUse:
            
            // If already authorized, get the location
            [self.locationManager requestLocation];
            
    }
    
}


// When we get authorization, request location
-(void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    
    if (status == kCLAuthorizationStatusAuthorizedWhenInUse || status == kCLAuthorizationStatusAuthorizedAlways) {
        // Request location. When received, didUpdateLocations will be called.
        [self.locationManager requestLocation];
        
    }
    
}


// Pass the location back to the View Controller (our delegate)
-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    
    // Docs: "the most recent location update is at the end of the array"
    CLLocation *location = [locations lastObject];
    [self.delegate receivedLocation:location];
    
}


// Handle location failure
-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    
    NSLog(@"Location request failed");
    
}


@end
