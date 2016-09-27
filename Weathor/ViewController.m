//
//  ViewController.m
//  Weathor
//
//  Created by Jeff Spingeld on 6/17/16.
//  Copyright © 2016 Jeff Spingeld. All rights reserved.
//

#import "ViewController.h"
#import "SMRotaryWheel.h"
#import "SMClove.h"
#import "JDSLocationClient.h"

@interface ViewController () <JSLocationClientDelegate>

@property (strong, nonatomic) JDSLocationClient *locationClient;
@property (strong, nonatomic) SMRotaryWheel *wheel;
@property (strong, nonatomic) NSDictionary *forecast;
@property (strong, nonatomic) UIImageView *backgroundImageView;
// labels
@property (strong, nonatomic) UILabel *currentDateLabel;
@property (strong, nonatomic) UILabel *wheelDateLabel;
@property (strong, nonatomic) UILabel *tempLabel;
@property (strong, nonatomic) UILabel *precipLabel;


@end


@implementation ViewController

-(void)viewDidLoad {
    [super viewDidLoad];
    
    // Set up UI stuff
    [self makeWheel];
    [self setUpLabels];

    // Request the current location. (When received, the receivedLocation method will be called)
    self.locationClient = [JDSLocationClient new];
    self.locationClient.delegate = self;
    [self.locationClient getCurrentLocation];
    
    // Credit to Darksky.net, in accordance with their Terms of Service :)
    // https://darksky.net/dev/docs/terms
    // "You agree that any application or service which incorporates data obtained from the Service shall prominently display the message “Powered by Dark Sky” in a legible manner near the data or any information derived from any data from the Service. This message must, if possible, open a link to https://darksky.net/poweredby/ when clicked or touched."
    
    [self setUpCreditButton];
    
}

-(void)receivedLocation:(CLLocation *)location {

    // Send location to the darksky.net API for a weather forecast
    [JDSAPIClient getForecastForLocation:location withCompletion:^(id responseObject) {
       
        // Update the forecast property and update views
        self.forecast = (NSDictionary *)responseObject;
        [self updateViewsWithForecast];
        
    }];
    
}


// Update views according to the forecast for the day the user has selected
-(void)updateViewsWithForecast {
    
    NSUInteger day = self.wheel.currentValue;
    NSDictionary *weather;
    CGFloat temp;
    if (day == 0) {
        weather = self.forecast[@"currently"];
        temp = [weather[@"temperature"] floatValue];
    } else {
        weather = self.forecast[@"daily"][@"data"][day];
        temp = [weather[@"temperatureMax"] floatValue];
    }
    
    // Update labels
    [self updateLabelsForWeather:weather];
    
    // Set the background image based on type of weather, and set its tintColor according based on the temperature
    NSString *icon = weather[@"icon"];
    [self setBackgroundForIcon:icon temperature:temp];
    
}

#pragma mark - UI setup

-(void)makeWheel {
    
    // Create wheel
    self.wheel = [[SMRotaryWheel alloc] initWithFrame:CGRectMake(0, 0, 400, 400)
                                          andDelegate:self
                                         withSections:8];
    
    
    // Position it at the bottom middle of the screen
    CGFloat centerX = self.view.center.x;
    CGFloat centerY = CGRectGetMaxY(self.view.frame) - 20 - (self.wheel.frame.size.height / 2);
    self.wheel.center = CGPointMake(centerX, centerY);
    [self.view addSubview:self.wheel];
    
}

-(void)setUpLabels {
  
    self.tempLabel = [UILabel new];
    self.currentDateLabel = [UILabel new];
    self.wheelDateLabel = [UILabel new];
    self.precipLabel = [UILabel new];
    
    NSArray *labels = @[self.currentDateLabel, self.wheelDateLabel, self.tempLabel, self.precipLabel];
    
    for (int i = 0; i < [labels count]; i++) {
        
        UILabel *label = labels[i];
        
        // Size and position
        label.text = @"";
        [label sizeToFit];
        label.center = CGPointMake(self.view.frame.size.width / 2, (30 * i + label.frame.size.height + 100));
        
        // Styling
        label.textColor = [UIColor purpleColor];
        label.backgroundColor = [UIColor yellowColor];
        label.font = [UIFont fontWithName:@"Copperplate-Light" size:19];
        label.layer.cornerRadius = 5;
        label.layer.masksToBounds = YES;
        
        [self.view addSubview:label];
        
    }
    
    // Set current date label (set text, resize, re-center)
    self.currentDateLabel.text = [NSString stringWithFormat:@"Today: %@", [self dateForDay:0]];
    [self.currentDateLabel sizeToFit];
    self.currentDateLabel.center = CGPointMake(self.view.frame.size.width / 2, self.currentDateLabel.center.y);
    
}

// Display weather for the correct day when user moves the dial.
-(void)didChangeValue:(NSUInteger)newValue {
    
    NSLog(@"The dial is turned to: %lu", newValue);
    [self updateViewsWithForecast];
    
}

-(void)setUpCreditButton {
    
    // Create button
    UIButton *creditsButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.view addSubview:creditsButton];
    [creditsButton addTarget:self
                      action:@selector(openCredits)
            forControlEvents:UIControlEventTouchUpInside];
    
    // Style and position
    [creditsButton setTitle:@"Powered by Dark Sky" forState:UIControlStateNormal];
    [creditsButton setTintColor:[UIColor yellowColor]];
    creditsButton.titleLabel.font = [UIFont fontWithName:@"Optima-Bold" size:15];
    [creditsButton sizeToFit];
    
    creditsButton.frame = CGRectMake(CGRectGetMaxX(self.view.frame) - creditsButton.frame.size.width - 5, (self.view.frame.size.height - creditsButton.frame.size.height), creditsButton.frame.size.width, creditsButton.frame.size.height);
    
}

-(void)openCredits {
    
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString: @"https://darksky.net/poweredby/"]];

}

#pragma mark - UI updates

-(void)updateLabelsForWeather:(NSDictionary *)weather {
    
    // Update text of labels
    self.wheelDateLabel.text = [self dateForDay:self.wheel.currentValue];
    [self updateTempLabel];
    [self updatePrecipitationLabelForWeather:weather];
    
    // Resize and horizontally re-center the labels whose text may have changed
    dispatch_async(dispatch_get_main_queue(), ^{
        
        for (UILabel *label in @[self.tempLabel, self.wheelDateLabel, self.precipLabel]) {
            
            [label sizeToFit];
            label.center = CGPointMake(self.view.center.x, label.center.y);
            
        }
        
    });
    
}

-(void)updateTempLabel {
    
    NSUInteger day = self.wheel.currentValue;
    NSDictionary *weather;
    CGFloat temp;
    
    // Looking at current conditions
    if (day == 0) {
        
        weather = self.forecast[@"currently"];
        temp = [weather[@"temperature"] floatValue];
        
        // Set temperature label (high, current, low)
        NSString *highTemp = [NSString stringWithFormat:@"%lu", (unsigned long)[self.forecast[@"daily"][@"data"][0][@"temperatureMax"] floatValue]];
        NSString *lowTemp = [NSString stringWithFormat:@"%lu", (unsigned long)[self.forecast[@"daily"][@"data"][0][@"temperatureMin"] floatValue]];
        NSString *currentTemp = [NSString stringWithFormat:@"%lu", (unsigned long)[weather[@"temperature"] floatValue]];
        
        self.tempLabel.text = [NSString stringWithFormat:@"(High: %@° F) Currently %@° F (Low: %@° F)", highTemp, currentTemp, lowTemp];
        
        // Looking at another day
    } else {
        
        weather = self.forecast[@"daily"][@"data"][day];
        temp = [weather[@"temperatureMax"] floatValue];
        
        // Set temperature label (just high and low)
        NSString *highTemp = [NSString stringWithFormat:@"%lu", (unsigned long)[weather[@"temperatureMax"] floatValue]];
        NSString *lowTemp = [NSString stringWithFormat:@"%lu", (unsigned long)[weather[@"temperatureMin"] floatValue]];
        
        self.tempLabel.text = [NSString stringWithFormat:@"High: %@° F / Low: %@° F", highTemp, lowTemp];
        
    }
    
}

-(void)updatePrecipitationLabelForWeather:(NSDictionary *)weather {
    
    CGFloat precipProb = [weather[@"precipProbability"] floatValue];
    NSString *precipType = weather[@"precipType"];
    if (precipProb >= 0.01) {
        
        self.precipLabel.text = [NSString stringWithFormat:@"%lu%% chance of %@", (unsigned long)(precipProb * 100), precipType];
        
    } else {
        
        self.precipLabel.text = @"";
        
    }
    
}


-(void)setBackgroundForIcon: (NSString *)icon temperature: (CGFloat)temp {
    
    // Get an image representing this weather
    NSArray *weatherTypesIHaveAnImageFor = @[@"rain", @"snow", @"sleet", @"wind", @"fog", @"cloudy", @"partly-cloudy-day", @"partly-cloudy-night"];
    
    UIImage *backgroundImage = [UIImage new];
    UIImageView *backgroundImageView = [[UIImageView alloc] init];
    if ([weatherTypesIHaveAnImageFor containsObject:icon]) {
        NSString *imageName = [NSString stringWithFormat:@"%@.jpg", icon];
        backgroundImage = [UIImage imageNamed:imageName];
        [backgroundImageView setImage:backgroundImage];
    } // No picture necessary for "clear-day" or "clear-night"
    
    // COLOR OVERLAY: tint the picture blue/red, depending on the temperature, by adding a translucent view with the right color
    
    /* Explanation:
     1. The overlay is red if the temperature is above 67 F, blue if temp <= 67. (I somewhat arbitrarily chose this as the dividing line between "cool/cold" and "warm/hot".)
     2. The overlay's alpha value is calculated based on how extreme the temperature is (quantified as the distance of the temperature from 67).
     3. Based on experimenting with what looks good, the max alpha for red is 0.6, min 0.3; max for blue is 0.4, min 0.1.
     4. Again somewhat arbitrarily, I picked 32 Fahrenheit and 95 Fahrenheit as the temperatures at which the maximum alpha values should be reached.
     */
    
    UIColor *overlayColor = [UIColor new];
    CGFloat overlayAlpha;
    
    if (temp > 67) {
        overlayColor = [UIColor redColor];
        
        if (temp > 95) {
            overlayAlpha = 0.6;
        } else {
            CGFloat percentOfAlpha = (temp - 67) / 28;
            overlayAlpha = 0.3 + percentOfAlpha * (0.6 - 0.3);
        }
        
        
        
    } else {
        overlayColor = [UIColor blueColor];
        
        if (temp < 32) {
            overlayAlpha = 0.4;
        } else {
            CGFloat percentOfAlpha = 1 - ((temp - 32) / 35);
            overlayAlpha = 0.3 + percentOfAlpha * (0.6 - 0.3);
        }
        
    }
    
    UIView *overlay = [[UIView alloc] init];
    overlay.backgroundColor = overlayColor;
    overlay.alpha = overlayAlpha;
    // Add it as a subview of backgroundImageView
    [backgroundImageView addSubview:overlay];
    // Bring to front
    [backgroundImageView bringSubviewToFront:overlay];
    // Constrain to edges of backgroundImageview
    overlay.translatesAutoresizingMaskIntoConstraints = NO;
    [overlay.topAnchor constraintEqualToAnchor:backgroundImageView.topAnchor].active = YES;
    [overlay.bottomAnchor constraintEqualToAnchor:backgroundImageView.bottomAnchor].active = YES;
    [overlay.leftAnchor constraintEqualToAnchor:backgroundImageView.leftAnchor].active = YES;
    [overlay.rightAnchor constraintEqualToAnchor:backgroundImageView.rightAnchor].active = YES;
    
    // Add background image view to main view. Update labels.
    
    // Remove the existing background image
    [self.backgroundImageView removeFromSuperview];
    
    // add background image
    self.backgroundImageView = backgroundImageView;
    [self.view addSubview:self.backgroundImageView];
    [self.view sendSubviewToBack:self.backgroundImageView];
    // constrain and scale
    self.backgroundImageView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.backgroundImageView.topAnchor constraintEqualToAnchor:self.view.topAnchor].active = YES;
    [self.backgroundImageView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor].active = YES;
    [self.backgroundImageView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor].active = YES;
    [self.backgroundImageView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor].active = YES;
    self.backgroundImageView.contentMode = UIViewContentModeScaleAspectFill;
    
}



#pragma mark - Non-UI methods

// Called when the refresh button is tapped
-(void)refreshForecastData {
    
    [self.locationClient getCurrentLocation];
    
}

-(NSString *)dateForDay:(NSUInteger)day {
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"EEE, MMM d"; // format example: "Wed, July 2"
    NSDateComponents *dayComponent = [[NSDateComponents alloc] init];
    dayComponent.day = day;
    NSCalendar *theCalendar = [NSCalendar currentCalendar];
    NSDate *date = [theCalendar dateByAddingComponents:dayComponent toDate:[NSDate date] options:0];
    NSString *dateString = [formatter stringFromDate:date];
    
    return dateString;
    
}

/*
 This project includes code by Cesare Rocchi:
 The wheel interface is from the project in this tutorial (but modified by me): https://www.raywenderlich.com/9864/how-to-create-a-rotating-wheel-control-with-uikit)
 That project's GitHub repo: https://github.com/funkyboy/How-To-Create-a-Rotating-Wheel-Control-with-UIKit-UIView-Version
*/

@end
