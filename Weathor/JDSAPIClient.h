//
//  APIClient.h
//  Weathor
//
//  Created by Jeff Spingeld on 6/17/16.
//  Copyright © 2016 Jeff Spingeld. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AFNetworking/AFNetworking.h>
#import <CoreLocation/CoreLocation.h>

@interface JDSAPIClient : NSObject

+(void)getForecastForLocation:(CLLocation *)location withCompletion:(void (^)(id responseObject))completion;

@end
