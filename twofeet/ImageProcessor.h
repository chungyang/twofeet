//
//  ImageProcessor.h
//  twofeet
//
//  Created by chung yang on 5/13/16.
//  Copyright © 2016 chung yang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>


@interface ImageProcessor : NSObject

+(UIImage*)cannyEdge:(UIImage*) image threshold1:(double) th1 threshold2:(double) th2 flag:(int) flag;
+(UIImage*)houghCircleTransform:(UIImage*) image;
+(UIImage*)extractSkin:(UIImage*)image;

@end

