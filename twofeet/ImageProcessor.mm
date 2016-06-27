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

using namespace cv;
using namespace std;

@implementation ImageProcessor:NSObject


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
    Mat edges;
    Canny(grayImage, edges, th1, th2);
    UIImage *edgeImage = [UIImageOpenCV  CVMat2UIImage:edges];  //Convert the processed Mat back to UIImage
    return edgeImage;
}

+(UIImage*)houghCircleTransform:(UIImage*) image{
    
    Mat imageMat;
    Mat grayImage;
    
    imageMat = [UIImageOpenCV UIImage2CVMat:image];
    cvtColor(imageMat,grayImage,CV_BGRA2GRAY);

    vector<cv::Vec3f> circles;
    HoughCircles(grayImage, circles, CV_HOUGH_GRADIENT,1,5,70,80,20,150);
    printf("%lu\n",circles.size());
    for(size_t i = 0; i < circles.size(); i++){
        cv::Point center(cvRound(circles[i][0]),cvRound(circles[i][1]));
        int radius = cvRound(circles[1][2]);
        circle(imageMat,center,radius, cvScalar(0,0,255),2,8,0);
    }
    return [UIImageOpenCV CVMat2UIImage:imageMat];
}

-(void)extractSkinTone:(UIImage*) image{
    //Extract skin tone
    Mat imageMat;
    vector<Mat> channels;
    vector<Scalar> means;
    vector<Scalar> std;
    
    means.reserve(3);
    std.reserve(3);
    
    imageMat = [UIImageOpenCV UIImage2CVMat:image];
    cvtColor(imageMat, imageMat, CV_BGRA2RGB);
    split(imageMat,channels);
    
    for(int i = 0; i < 3; i++){
        meanStdDev(channels[i], means[i], std[i]);
    }

    *self.componentMean = means[0][0];
    *(self.componentMean + 1) = means[1][0];
    *(self.componentMean + 2) = means[2][0];
    
    *(self.componentStd) = sqrt(std[0][0]);
    *(self.componentStd + 1) = sqrt(std[1][0]);
    *(self.componentStd + 2) = sqrt(std[1][0]);
}

-(void)allocateMemory{
    self.componentMean = (double*) malloc(sizeof(double)*3);
    self.componentStd = (double*) malloc(sizeof(double)*3);
}

-(void)releaseMemory{
    free(self.componentStd);
    free(self.componentMean);
}

-(UIImage*)showsOnlySkinTone:(UIImage*) image{
    
    cv::Mat lut(1,256,CV_8UC3);
    
    
    double_t std1 = *(self.componentStd) * 2;
    double_t std2 = *(self.componentStd + 1 * 2);
    double_t std3 = *(self.componentStd + 2) * 2;
    
    for(int i = 0; i < 256; i++){
        //All three channels have to be within the tolerance to be considered as having the same color as skin
        if(fabs(i - *(self.componentMean)) < std1){
            lut.at<Vec3b>(i)[0] = i;
        }
        else{
            lut.at<Vec3b>(i)[0] = 0;
        }
        
        if(fabs(i - *(self.componentMean + 1)) < std2){
            lut.at<Vec3b>(i)[1] = i;
        }
        else{
             lut.at<Vec3b>(i)[1] = 0;
        }
        
        if(fabs(i - *(self.componentMean + 2)) < std3){
            lut.at<Vec3b>(i)[2] = i;
        }
        else{
            lut.at<Vec3b>(i)[2] = 0;
        }
    }
    
    Mat imageMat;
    
    imageMat = [UIImageOpenCV UIImage2CVMat:image];
    
    cvtColor(imageMat, imageMat, CV_BGRA2RGB);
   
    LUT(imageMat,lut,imageMat);
    cvtColor(imageMat, imageMat, CV_RGB2RGBA);
    return [UIImageOpenCV CVMat2UIImage:imageMat];
}

-(UIImage*)rectangleMasking:(UIImage*)image{
    
    Mat imageMat;
    Mat imageMatGray;
    Mat mask;
    vector<Mat> channels;
    vector<vector<cv::Point> > contours;
    vector<Vec4i> hierarchy;
    
    imageMat = [UIImageOpenCV UIImage2CVMatGray:image];
    
    mask =  Mat::zeros(imageMat.rows, imageMat.cols, CV_8UC1);
    mask(cv::Rect(mask.cols / 2, mask.rows / 2 - 50, mask.cols / 2, 100)) = 1;
    
    if(imageMat.elemSize() > 1){
        cvtColor(imageMat, imageMat, CV_BGRA2RGB);
        split(imageMat,channels);
        channels[0] = channels[0].mul(mask);
        channels[1] = channels[1].mul(mask);
        channels[2] = channels[2].mul(mask);
        merge(channels, imageMat);
        cvtColor(imageMat, imageMatGray, CV_RGB2GRAY);
    }
    else{
        imageMatGray = imageMat;
        imageMatGray = imageMatGray.mul(mask);
    }
    
    GaussianBlur(imageMatGray, imageMatGray, cv::Size(5,5), 0);
    
    cvtColor(imageMat, imageMat, CV_GRAY2RGB);
    
    Mat edges;
    Canny(imageMatGray, edges, 45, 130);
    findContours(edges, contours, hierarchy, CV_RETR_CCOMP, CV_CHAIN_APPROX_NONE, cv::Point(0, 0) );
    
    Mat drawing = Mat::zeros( edges.size(), CV_8UC3);
    Scalar color = Scalar(255,255,255);
    
    for(int i = 0; i < contours.size(); i++){
        if(contours[i].size() > 100){
            drawContours( drawing, contours, i, color, 1, 8, hierarchy, 0, cv::Point() );
        }
    }

    return [UIImageOpenCV CVMat2UIImage:drawing];
}

@end