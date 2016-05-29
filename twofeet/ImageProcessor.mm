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

+(UIImage*)cannyEdge:(UIImage*) image threshold1:(double) th1 threshold2:(double) th2 flag:(int) flag{
    cv::Mat grayImage;
    if(flag == 0){
        grayImage = [UIImageOpenCV UIImage2CVMat:image];
    }
    else{
        grayImage = [UIImageOpenCV UIImage2CVMatGray:image];
    }
    
    //If the image is not gray scale, convert it to gray scale
    if(grayImage.elemSize() > 1){
        cv::cvtColor(grayImage,grayImage,CV_BGRA2GRAY);
    }
    cv::Mat edges;
    cv::Canny(grayImage, edges, th1, th2);
    UIImage *edgeImage = [UIImageOpenCV  CVMat2UIImage:edges];  //Convert the processed Mat back to UIImage
    return edgeImage;
}

+(UIImage*)houghCircleTransform:(UIImage*) image{
    
    cv::Mat imageMat;
    cv::Mat grayImage;
    
    imageMat = [UIImageOpenCV UIImage2CVMat:image];
    cv::cvtColor(imageMat,grayImage,CV_BGRA2GRAY);

    std::vector<cv::Vec3f> circles;
    cv::HoughCircles(grayImage, circles, CV_HOUGH_GRADIENT,1,5,70,80,20,150);
    printf("%lu\n",circles.size());
    for(size_t i = 0; i < circles.size(); i++){
        cv::Point center(cvRound(circles[i][0]),cvRound(circles[i][1]));
        int radius = cvRound(circles[1][2]);
        cv::circle(imageMat,center,radius, cvScalar(0,0,255),2,8,0);
    }
    return [UIImageOpenCV CVMat2UIImage:imageMat];
}


+(UIImage*)showsOnlySkinTone:(UIImage*) image{
    
    //Extract skin tone
    cv::Mat imageMat;
    std::vector<cv::Mat> channels;
    static cv::Scalar componentMean[3];
    
    imageMat = [UIImageOpenCV UIImage2CVMat:image];
    
    cv::split(imageMat,channels);
    
    componentMean[0] = cv::mean(channels[0]);
    componentMean[1]  = cv::mean(channels[1]);
    componentMean[2]  = cv::mean(channels[2]);
    
    //Create a multi channel lookup table
    cv::Mat lut(1,256,CV_8UC4);
    
    for(int i = 0; i < 256; i++){
        //All three channels have to be within the tolerance to be considered as having the same color as skin
        if(fabs(i - componentMean[0][0]) < 10 && fabs(i - componentMean[1][0]) < 10 && fabs(i - componentMean[2][0]) < 10){
            lut.at<cv::Vec3b>(i)[0] = i;
            lut.at<cv::Vec3b>(i)[1] = i;
            lut.at<cv::Vec3b>(i)[2] = i;
        }
        else{
            lut.at<cv::Vec3b>(i)[0] = 0;
            lut.at<cv::Vec3b>(i)[1] = 0;
            lut.at<cv::Vec3b>(i)[2] = 0;
        }
    }
    
    //Execute color reduction using the look up table, all
    cv::LUT(imageMat,lut,imageMat);
    return [UIImageOpenCV CVMat2UIImage:imageMat];
}

@end