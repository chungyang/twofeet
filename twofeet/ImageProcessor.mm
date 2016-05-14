//
//  ImageProcessor.m
//  twofeet
//
//  Created by chung yang on 5/13/16.
//  Copyright © 2016 chung yang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ImageProcessor.h"
#import "UIImageOpenCV.h"

@implementation ImageProcessor

+(UIImage*)CannyEdge:(UIImage*) image threshold1:(double) th1 threshold2:(double) th2{
    cv::Mat grayImage = [UIImageOpenCV UIImage2CVMat:image];   //First convert UIImage to Mat
    
    //If the image is not gray scale, convert it to gray scale
    if(grayImage.elemSize() > 1){
        cv::cvtColor(grayImage,grayImage,CV_RGB2GRAY);
    }
    cv::Mat edges;
    cv::Canny(grayImage, edges, th1, th2);
    UIImage *edgeImage = [UIImageOpenCV  CVMat2UIImage:edges];
    return edgeImage;
}


@end