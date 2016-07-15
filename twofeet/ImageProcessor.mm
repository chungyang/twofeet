//
//  ImageProcessor.m
//  twofeet
//
//  Created by chung yang on 5/13/16.
//  Copyright © 2016 chung yang. All rights reserved.
//

#import "ImageProcessor.h"
#import "UIImageOpenCV.h"

using namespace cv;
using namespace std;


@implementation ImageProcessor:NSObject

static int x_offset[] = {0,  1,  1,  1,  0, -1, -1, -1};
static int y_offset[] = {-1, -1,  0,  1,  1,  1,  0, -1};

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


//**Algorithm of five stages to extract skin (modify chrominance range from Chai and Ngan 1999)***\\

//Stage one
+(Mat)colorSegmentation:(Mat) input{
    
    Mat output(input.rows,input.cols,CV_8UC3);
    vector<Mat> channels;
    int luminance, Cr, Cb;
    //Split input into Y,Cb,Cr
    split(input,channels);
 
    for(int i = 0; i < input.rows; i++){
        for(int j = 0; j < input.cols; j++){
            luminance = channels[0].at<uchar>(i, j);
            Cb = channels[1].at<uchar>(i,j);
            Cr = channels[2].at<uchar>(i,j);
            //For some reason the skin tone belongs to the range outside the first if statement
            if((Cr >= 100 && Cr <= 200) && (Cb >= 50 && Cb <= 150)){
                channels[0].at<uchar>(i, j) = 0;
                channels[1].at<uchar>(i, j) = 0;
                channels[2].at<uchar>(i,j) = 0;
            }
            else{
                channels[0].at<uchar>(i, j) = 255;
                channels[1].at<uchar>(i, j) = 255;
                channels[2].at<uchar>(i,j) = 255;
            }
        }
    }
    merge(channels, output);
    cvtColor(output, output, CV_RGB2GRAY);
    return output;
}

//Stage two
+(Mat)densityRegularization:(Mat)input{
    
    
    int density,nlocalFullDensity;
    NSMutableArray* x_erode_candidates = [[NSMutableArray alloc] init];
    NSMutableArray* y_erode_candidates = [[NSMutableArray alloc] init];
    NSMutableArray* x_dilate_candidates = [[NSMutableArray alloc] init];
    NSMutableArray* y_dilate_candidates = [[NSMutableArray alloc] init];
    Mat densityMap(input.rows / 4,input.cols / 4,CV_8UC1);

    //Calculating density map
    for(int y = 0; y < input.cols / 4 ; y++){
        for(int x = 0; x < input.rows / 4; x++){
            
            density = 0;
            
            for(int i = 0; i < 4;i++){
                for(int j = 0; j < 4; j++){
                    if(input.at<uchar>(4 * x + i, 4 * y + j) > 0){
                        density++;
                    }
                }
            }
            if(density == 16){
                densityMap.at<uchar>(x,y) = 255;
            }
            else if(density == 0){
                densityMap.at<uchar>(x,y) = 0;
            }
            else{
                densityMap.at<uchar>(x,y) = 125;
            }
        }
    }
    
   
    //Dilate(set it to 255) any point of either zero or intermediate density if t
    //here are more than two full-density points in its local 3x3 neighborhood.
    for(int x = 0; x < densityMap.rows; x++){
        for(int y = 0; y < densityMap.cols; y++){
            
             //Erode(set it to 0) edge points
            if(x == 0 || x == densityMap.rows - 1 || y == 0 || y == densityMap.cols - 1){
                densityMap.at<uchar>(x,y) = 0;
            }
            else{
                nlocalFullDensity = 0;
                
                //Erode(set it to 0) a full density point if it has less than 5 full density points in its 3x3 neighborhood
                if(densityMap.at<uchar>(x,y) == 255){
                    for(int i = 0; i < 8; i++){
                        if(densityMap.at<uchar>(x + x_offset[i], y + y_offset[i]) == 255){
                            nlocalFullDensity ++;
                        }
                    }
                    if(nlocalFullDensity < 5){
                        NSNumber* location_x = [NSNumber numberWithInt:x];
                        NSNumber* location_y = [NSNumber numberWithInt:y];
                        [x_erode_candidates addObject:location_x];
                        [y_erode_candidates addObject:location_y];
                    }
                }
                //Dilate(set it to 16) a zero or intermideate point it has more than 2 full density points in its 3x3 neighborhhod
                else{
                    for(int i = 0; i < 8; i++){
                        if(densityMap.at<uchar>(x + x_offset[i], y + y_offset[i]) == 255){
                            nlocalFullDensity ++;
                        }
                    }
                    if(nlocalFullDensity >=3){
                        NSNumber* location_x = [NSNumber numberWithInt:x];
                        NSNumber* location_y = [NSNumber numberWithInt:y];
                        [x_dilate_candidates addObject:location_x];
                        [y_dilate_candidates addObject:location_y];
                    }
                    else{
                        NSNumber* location_x = [NSNumber numberWithInt:x];
                        NSNumber* location_y = [NSNumber numberWithInt:y];
                        [x_erode_candidates addObject:location_x];
                        [y_erode_candidates addObject:location_y];
                    }
                }
            }
        }
    }
        
    //Dilate and erode the points from the candidate lists
    for(int i = 0; i < [x_erode_candidates count]; i++){
        densityMap.at<uchar>([[x_erode_candidates objectAtIndex:i] intValue],[[y_erode_candidates objectAtIndex:i] intValue]) = 0;
    }
    for(int i = 0; i < [x_dilate_candidates count]; i++){
              densityMap.at<uchar>([[x_dilate_candidates objectAtIndex:i] intValue],[[y_dilate_candidates objectAtIndex:i] intValue]) = 255;
    }
    return densityMap;
}

+(UIImage*)extractSkin:(UIImage*)image{
    
    Mat imageMat = [UIImageOpenCV UIImage2CVMat:image];
    //Convert the image to YCrCb
    cvtColor(imageMat, imageMat, CV_BGRA2RGB);
    cvtColor(imageMat, imageMat, CV_RGB2YCrCb);
    imageMat = [self colorSegmentation:imageMat];
    imageMat = [self densityRegularization:imageMat];
    return [UIImageOpenCV CVMat2UIImage:imageMat];
}


@end