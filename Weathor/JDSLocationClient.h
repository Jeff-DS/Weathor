//
//  JSLocationManager.h
//  Weathor
//
//  Created by Jeff Spingeld on 7/14/16.
//  Copyright © 2016 Jeff Spingeld. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@protocol JSLocationClientDelegate <NSObject>

- (void)receivedLocation:(CLLocation *)location;

@end

@interface JDSLocationClient : NSObject

@property (nonatomic, weak) id <JSLocationClientDelegate> delegate;
-(void)getCurrentLocation;

@end
