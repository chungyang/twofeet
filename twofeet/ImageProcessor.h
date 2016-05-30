//
//  ImageProcessor.h
//  twofeet
//
//  Created by chung yang on 5/13/16.
//  Copyright © 2016 chung yang. All rights reserved.
//

#ifndef ImageProcessor_h
#define ImageProcessor_h

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface ImageProcessor : NSObject

@property (atomic) double* componenetMean;

+(UIImage*)cannyEdge:(UIImage*) image threshold1:(double) th1 threshold2:(double) th2 flag:(int) flag;
+(UIImage*)houghCircleTransform:(UIImage*) image;
-(void)extractSkinTone:(UIImage*) image;
-(UIImage*)showsOnlySkinTone:(UIImage*) image;
@end



#endif /* ImageProcessor_h */
