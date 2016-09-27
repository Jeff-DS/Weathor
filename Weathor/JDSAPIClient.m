//
//  APIClient.m
//  Weathor
//
//  Created by Jeff Spingeld on 6/17/16.
//  Copyright © 2016 Jeff Spingeld. All rights reserved.
//

#import "JDSAPIClient.h"
#import "Secrets.h"
#import "Secrets.h"

@implementation JDSAPIClient

+(void)getForecastForLocation:(CLLocation *)location withCompletion:(void (^)(id responseObject))completion {
    
    // Get location
    double latitude = location.coordinate.latitude;
    double longitude = location.coordinate.longitude;
    
    // URL String
    NSString *urlString = [NSString stringWithFormat:@"https://api.darksky.net/forecast/%@/%f,%f", API_KEY, latitude, longitude];
    
    // Create session manager
    AFHTTPSessionManager *sessionManager = [AFHTTPSessionManager manager];

    // Call GET method, implement success and failure blocks
    [sessionManager GET:urlString parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        // SUCCESS BLOCK
        completion(responseObject);
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        // FAILURE BLOCK
        NSLog(@"Error: %@", error);
        completion(error);
        
    }];
    
}

@end
