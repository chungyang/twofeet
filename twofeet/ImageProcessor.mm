//
//  ImageProcessor.m
//  twofeet
//
//  Created by chung yang on 5/13/16.
//  Copyright © 2016 chung yang. All rights reserved.
//

//There is a orientation difference between OpenCV and Quertz 2D. So in the image processing with OpenCV, rows corresponds to x-axis and columns corresponds to y-axis. After the image is processed, the processed image is rotated 90 degree so it aligns with the image aquired from the camera. Why is the orientation changed in OpenCV is currently unknown.

//        Quertz 2D                 OpenCV
//
//      x<---------                 ------------>y
//                |                 |
//                |                 |
//                |                 |
//                |                 |
//                ∨                 ∨
//                y                 x

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
            if((Cr >= 100 && Cr <= 210) && (Cb >= 40 && Cb <= 150)){
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

//Stage 3
+(Mat)luminanceRegularization:(Mat)outputfromstage2 luminance:(Mat)luminance{
    
    double sum,meanSquare, squareMean,std;
    
    for(int x = 0; x < outputfromstage2.rows; x++){
        for(int y = 0; y < outputfromstage2.cols; y++){
            
            sum = 0;
            
            for(int i = 0; i < 4;i++){
                for(int j = 0; j < 4; j++){
                    sum += luminance.at<uchar>(4 * x + i, 4 * y + j);
                }
            }
            
            meanSquare = pow(sum / 16, 2);
            squareMean = pow(sum,2) / 16;
            std = sqrt(squareMean - meanSquare);
            
            if(std < 2){
                outputfromstage2.at<uchar>(x,y) = 0;
            }
            
        }
    }
    
    return outputfromstage2;
}

//Stage 4
+(Mat)geometricCorrection:(Mat)outputfromstage3{
    
    //The paper suggests filtering out the noise using similar step from stage 2
    int nlocalFullDensity,counter = 0;
    bool detectedPixelsExist;
    
    NSMutableArray* x_erode_candidates = [[NSMutableArray alloc] init];
    NSMutableArray* y_erode_candidates = [[NSMutableArray alloc] init];
    NSMutableArray* x_dilate_candidates = [[NSMutableArray alloc] init];
    NSMutableArray* y_dilate_candidates = [[NSMutableArray alloc] init];
    NSMutableArray* firstDetectedPixel = [[NSMutableArray alloc] init];
    
    for(int x = 0; x < outputfromstage3.rows; x++){
        
        detectedPixelsExist = false;
        
        for(int y = 0; y < outputfromstage3.cols; y++){
        
            if(!(x == 0 || x == outputfromstage3.rows - 1 || y == 0 || y == outputfromstage3.cols - 1)){
                
                nlocalFullDensity = 0;
                
                if(outputfromstage3.at<uchar>(x,y) == 255){
                    
                    if(!detectedPixelsExist){
                        detectedPixelsExist = true;
                        NSNumber* row_number = [NSNumber numberWithInteger:x];
                        NSNumber* col_number = [NSNumber numberWithInteger:y];
                        [firstDetectedPixel addObject:row_number];
                        [firstDetectedPixel addObject:col_number];
                    }
                    
                    for(int i = 0; i < 8; i++){
                        
                        if(outputfromstage3.at<uchar>(x + x_offset[i], y + y_offset[i]) == 255){
                            nlocalFullDensity ++;
                        }
                        
                    }
                    
                    if(nlocalFullDensity < 3){
                        NSNumber* location_x = [NSNumber numberWithInt:x];
                        NSNumber* location_y = [NSNumber numberWithInt:y];
                        [x_erode_candidates addObject:location_x];
                        [y_erode_candidates addObject:location_y];
                    }
                    
                }
                else{
                    
                    for(int i = 0; i < 8; i++){
                        
                        if(outputfromstage3.at<uchar>(x + x_offset[i], y + y_offset[i]) == 255){
                            nlocalFullDensity ++;
                        }
                        
                    }
                    
                    if(nlocalFullDensity >= 5){
                        NSNumber* location_x = [NSNumber numberWithInt:x];
                        NSNumber* location_y = [NSNumber numberWithInt:y];
                        [x_dilate_candidates addObject:location_x];
                        [y_dilate_candidates addObject:location_y];
                    }
                }

            }
        }
    }
    //Dilate and erode the points from the candidate lists
    for(int i = 0; i < [x_erode_candidates count]; i++){
        outputfromstage3.at<uchar>([[x_erode_candidates objectAtIndex:i] intValue],[[y_erode_candidates objectAtIndex:i] intValue]) = 0;
    }
    for(int i = 0; i < [x_dilate_candidates count]; i++){
        outputfromstage3.at<uchar>([[x_dilate_candidates objectAtIndex:i] intValue],[[y_dilate_candidates objectAtIndex:i] intValue]) = 255;
    }
    
    //Scanning the rows and erode groups of points that don't have a count above 5
    for(int i = 0; i < [firstDetectedPixel count] / 2; i++){
        
        int rowScanning = [[firstDetectedPixel objectAtIndex:i] intValue];
        int coln = [[firstDetectedPixel objectAtIndex:i+1] intValue] - 1;  //subtracted by one to compensate for the first increment
        
        while(true){
            
            if(outputfromstage3.at<uchar>(rowScanning,coln + 1) == 255){
                counter++;
                coln++;
            }
            else{
                
                if(counter < 6){
                    for(int j = 0; j < counter; j++){
                        outputfromstage3.at<uchar>(rowScanning,coln - j) = 0;
                    }
                }
                
                counter = 0;
                coln++;
                
                if(coln > outputfromstage3.cols - 1){
                    break;
                }
            }
        }
    }
    
    //Maybe it can fix memory leaks
    x_erode_candidates = nil;
    x_dilate_candidates = nil;
    y_erode_candidates = nil;
    y_dilate_candidates = nil;
    firstDetectedPixel = nil;
    
    return outputfromstage3;
}

//Stage 5
+(Mat)contourExtraction:(Mat)outputfromstage4 segementedResult:(Mat)segementedResult{
    
    Mat edges,mask,finalResult;
    Mat detectedRegions = Mat::zeros(outputfromstage4.rows * 4, outputfromstage4.cols * 4, CV_8UC1);
    
    Canny(outputfromstage4,edges,1, 254);  //Note the threshold here doesn't really matter cause we are extracting edges from a binary image
    vector<vector<cv::Point>> contours;
    vector<Vec4i> hierarchy;
    
    findContours(edges, contours, hierarchy, CV_RETR_TREE, CV_CHAIN_APPROX_NONE);
    
    for(int i = 0; i < contours.size(); i++){
        
        vector<cv::Point> points = contours[i];
        int topRight_x = detectedRegions.rows / 4,topRight_y = detectedRegions.cols / 4,botLeft_x = 1,botLeft_y = 1;
        
        for(int j = 0; j < points.size(); j++){
            
            //Points extracted by findContours are rotated for some reason
            int x = points[j].y;
            int y = points[j].x;
            
            if(x < topRight_x){
                topRight_x = x;
            }
            if(x > botLeft_x){
                botLeft_x = x;
            }
            if(y > botLeft_y){
                botLeft_y = y;
            }
            if(y < topRight_y){
                topRight_y = y;
            }
        }
        
        //Transform the points to the ones on a original resolution Mat
        
        for(int x = 0; x < abs(botLeft_x - topRight_x); x++){
            for(int y = 0; y < abs(botLeft_y - topRight_y); y++){

                detectedRegions.at<uchar>(topRight_x + x ,topRight_y + y) = 1;
                
            }
        }
    }
    
    cv::Size size(segementedResult.cols,segementedResult.rows);
    resize(outputfromstage4, outputfromstage4, size);
    
    finalResult = segementedResult.mul(outputfromstage4);
    
    return finalResult;
}

+(UIImage*)extractSkin:(UIImage*)image{
    
    Mat imageMat = [UIImageOpenCV UIImage2CVMat:image];
    vector<Mat> channels;
    split(imageMat,channels);
    
    //Convert the image to YCrCb
    cvtColor(imageMat, imageMat, CV_BGRA2RGB);
    cvtColor(imageMat, imageMat, CV_RGB2YCrCb);
    imageMat = [self colorSegmentation:imageMat];
    Mat segmentedResult = imageMat.clone();
    imageMat = [self densityRegularization:imageMat];
    imageMat = [self luminanceRegularization:imageMat luminance:channels[0]];
    imageMat = [self geometricCorrection:imageMat];
    imageMat = [self contourExtraction:imageMat segementedResult:segmentedResult];
    return [UIImageOpenCV CVMat2UIImage:imageMat];
}


@end