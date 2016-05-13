//
//  UIImage+OpenCV.h
//  twofeet
//
//  Created by chung yang on 5/13/16.
//  Copyright © 2016 two feet inc. All rights reserved.
//


#ifndef UIImage_OpenCV_h
#define UIImage_OpenCV_h

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface ImageProcessor:NSObject
+(cv::Mat)UIImage2CVMat:(UIImage*) image;
+(UIImage*)CVMat2UIImage:(cv::Mat)cvMat;

@end

#endif /* UIImage_OpenCV_h */
