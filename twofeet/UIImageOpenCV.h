//
//  UIImageOpenCV.h
//  twofeet
//
//  Created by chung yang on 5/13/16.
//  Copyright © 2016 two feet inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImageOpenCV:NSObject

+(cv::Mat)UIImage2CVMat:(UIImage*) image;
+(UIImage*)CVMat2UIImage:(cv::Mat)cvMat;
+(cv::Mat)UIImage2CVMatGray:(UIImage*) image;

@end