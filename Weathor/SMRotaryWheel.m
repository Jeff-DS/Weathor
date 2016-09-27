//
//  SMRotaryWheel.m
//  RotaryWheelProject
//
//  Created by cesarerocchi on 2/10/12.
//  Copyright (c) 2012 studiomagnolia.com. All rights reserved.

#import "SMRotaryWheel.h"
#import <QuartzCore/QuartzCore.h>

#define RADIANS_TO_DEGREES(radians) ((radians) * (180.0 / M_PI))
#define DEGREES_TO_RADIANS(angle) ((angle) / 180.0 * M_PI)


static float deltaAngle;
static float minAlphavalue = 0.8;
static float maxAlphavalue = 1.0;


@implementation SMRotaryWheel

@synthesize startTransform, container, cloves, currentValue, delegate, wheelCenter, cloveNames, numberOfSections;

              
- (id) initWithFrame:(CGRect)frame andDelegate:(id)del withSections:(int)sectionsNumber {
    
    if ((self = [super initWithFrame:frame])) {
		
        self.numberOfSections = sectionsNumber;
        self.delegate = del;
		[self initWheel];
        
	}
    return self;
}


- (void) initWheel {
        
    container = [[UIView alloc] initWithFrame:self.frame];
    
    cloves = [NSMutableArray arrayWithCapacity:numberOfSections];
    
    // Calculate angle between each clove
    CGFloat angleSize = 2*M_PI/numberOfSections;
    
    // Create image for each clove and add as subviews to container
    for (int i = 0; i < numberOfSections; i++) {
        
        // Add generic clove/segment image
        UIImageView *im = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"segment.png"]];
        // Double its size
        im.bounds = CGRectMake(0, 0, im.bounds.size.width * 2, im.bounds.size.height * 2);
        
        im.layer.anchorPoint = CGPointMake(1.0f, 0.5f);
        im.layer.position = CGPointMake(container.bounds.size.width/2.0-container.frame.origin.x, 
                                                container.bounds.size.height/2.0-container.frame.origin.y); 
        im.transform = CGAffineTransformMakeRotation(angleSize*i);
        im.alpha = minAlphavalue;
        im.tag = i;
        
        if (i == 0) {
            im.alpha = maxAlphavalue;
        }
        
        // Get date string
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"EEE, M/d"; // format example: "Wed, July 2"
        NSDateComponents *dayComponent = [[NSDateComponents alloc] init];
        dayComponent.day = i;
        NSCalendar *theCalendar = [NSCalendar currentCalendar];
        NSDate *date = [theCalendar dateByAddingComponents:dayComponent toDate:[NSDate date] options:0];
        NSString *dateString = [formatter stringFromDate:date];
        
        // Make date label
        UILabel *dateLabel = [[UILabel alloc] initWithFrame:CGRectMake(35, 60, 40, 40)];
        dateLabel.text = dateString;
        [dateLabel setFont:[UIFont fontWithName:@"Cochin-BoldItalic" size:17]];
        if (i == 0) {
            dateLabel.textColor = [UIColor blueColor];
        } else {
            dateLabel.textColor = [UIColor whiteColor];
        }
        [dateLabel sizeToFit];
        // Add label to the segment
        [im addSubview:dateLabel];
        
        // Add the completed segment to container as subview
        [container addSubview:im];
        
    }
    
    container.userInteractionEnabled = NO;
    [self addSubview:container];
    
    // put in the wheel's background image
    UIImageView *bg = [[UIImageView alloc] initWithFrame:self.frame];
    bg.image = [UIImage imageNamed:@"bg.png"];
    [self addSubview:bg];
    
    // put in the wheel's center button
    UIImageView *mask = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 116, 116)]; // 58, 58)];
    mask.image =[UIImage imageNamed:@"centerButton.png"];
    mask.center = self.center;
    mask.center = CGPointMake(mask.center.x, mask.center.y+3);
    [self addSubview:mask];
    
    // make it tappable and call refreshForecastData when tapped
    [mask setUserInteractionEnabled:YES];
    [mask addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(refreshForecast)]];
    
    
    // put the cloves in
    if (numberOfSections % 2 == 0) {
    
        [self buildClovesEven];
        
    } else {
    
        [self buildClovesOdd];
        
    }
    
    // tell the delegate that the wheel is at its starting place
    [self.delegate didChangeValue:0];
    
}

- (void)refreshForecast {
    
    NSLog(@"Refresh button tapped");
    [self.delegate refreshForecastData];
    
}

- (UILabel *) getLabelByValue:(int)value {
    
    UILabel *res;
    
    NSArray *labels = [container subviews];
    
    for (UILabel *lab in labels) {
        
        if (lab.tag == value)
            res = lab;
        
    }
    
    return res;
    
}

- (void) buildClovesEven {
    
    CGFloat fanWidth = M_PI*2/numberOfSections;
    CGFloat mid = 0;
    
    for (int i = 0; i < numberOfSections; i++) {
        
        SMClove *clove = [[SMClove alloc] init];
        clove.midValue = mid;
        clove.minValue = mid - (fanWidth/2);
        clove.maxValue = mid + (fanWidth/2);
        clove.value = i;
        
        
        if (clove.maxValue-fanWidth < - M_PI) {
            
            mid = 3.14;
            clove.midValue = mid;
            clove.minValue = fabsf(clove.maxValue);
            
        }
        
        mid -= fanWidth;

        
        [cloves addObject:clove];
        
    }

}




- (float) calculateDistanceFromCenter:(CGPoint)point {

    CGPoint center = CGPointMake(self.bounds.size.width/2.0f, self.bounds.size.height/2.0f);
	float dx = point.x - center.x;
	float dy = point.y - center.y;
	return sqrt(dx*dx + dy*dy);
    
}

-(void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {

    UITouch *touch = [touches anyObject];
    CGPoint delta = [touch locationInView:self];
    float dist = [self calculateDistanceFromCenter:delta];
    
    if (dist < 80 || dist > 200) // doubled wheel size -> had to double these numbers. This fixes the issue of the segments disappearing when you touch them.
    {
        // forcing a tap to be on the ferrule
//        NSLog(@"ignoring tap (%f,%f)", delta.x, delta.y);
        return;
    }
    
    startTransform = container.transform;
    
    UILabel *lab = [self getLabelByValue:currentValue];
    lab.alpha = minAlphavalue;
    
	float dx = delta.x  - container.center.x;
	float dy = delta.y  - container.center.y;
	deltaAngle = atan2(dy,dx); 
    
}




- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    
    CGPoint pt = [touch locationInView:self];
	
	float dx = pt.x  - container.center.x;
	float dy = pt.y  - container.center.y;
	float ang = atan2(dy,dx);
    
    float angleDif = deltaAngle - ang;
    
    CGAffineTransform newTrans = CGAffineTransformRotate(startTransform, -angleDif);
    container.transform = newTrans;
    
    //[self sendActionsForControlEvents:UIControlEventValueChanged];
}


- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {

    CGFloat radians = atan2f(container.transform.b, container.transform.a);
//    NSLog(@"rad is %f", radians);
    
    CGFloat newVal = 0.0;
    
    for (SMClove *c in cloves) {
        
        if (c.minValue > 0 && c.maxValue < 0) {
            
            if (c.maxValue > radians || c.minValue < radians) {
                
                if (radians > 0) {
                    
                    newVal = radians - M_PI;
                    
                } else {
                    
                    newVal = M_PI + radians;                    
                    
                }
                currentValue = c.value;
                
            }
            
        }
        
        if (radians > c.minValue && radians < c.maxValue) {
            
            newVal = radians - c.midValue;
            currentValue = c.value;
            
        }
        
    }
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.2];
    
    CGAffineTransform t = CGAffineTransformRotate(container.transform, -newVal);
    container.transform = t;
    
    [UIView commitAnimations];
    
    UILabel *lab = [self getLabelByValue:currentValue];
    lab.alpha = maxAlphavalue;
    
    [self.delegate didChangeValue:currentValue];
    
}

- (void) buildClovesOdd {
    
    CGFloat fanWidth = M_PI*2/numberOfSections;
    CGFloat mid = 0;
    
    for (int i = 0; i < numberOfSections; i++) {
        
        SMClove *clove = [[SMClove alloc] init];
        clove.midValue = mid;
        clove.minValue = mid - (fanWidth/2);
        clove.maxValue = mid + (fanWidth/2);
        clove.value = i;
        
        mid -= fanWidth;
        
        if (clove.minValue < - M_PI) { // odd sections
            
            mid = -mid;
            mid -= fanWidth; 
            
        }
        
        [cloves addObject:clove];
        
    }
    
    
}

@end
