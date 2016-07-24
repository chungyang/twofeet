//
//  RootViewController.swift
//  twofeet
//
//  Created by chung yang on 5/13/16.
//  Copyright © 2016 two feet inc. All rights reserved.
//


import Foundation
import UIKit
import AVFoundation

class RootViewController: UIViewController, UIImagePickerControllerDelegate,UINavigationControllerDelegate,AVCaptureVideoDataOutputSampleBufferDelegate{
    
    
 
    //Properties
    @IBOutlet weak var ImagePicked: UIImageView!
    @IBOutlet weak var toolBar: UIToolbar!
    let queue = dispatch_queue_create("com.twofeet.queue", DISPATCH_QUEUE_SERIAL)
    let captureDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo) as AVCaptureDevice?
    var imagePicker = UIImagePickerController()
    var imageProcessor:ImageProcessor?
    var url = ""
    
    lazy var captureSession : AVCaptureSession = {
        let s = AVCaptureSession()
        s.sessionPreset = AVCaptureSessionPresetMedium
        return s
    }()
    
    lazy var previewLayer: AVCaptureVideoPreviewLayer = {
        let preview =  AVCaptureVideoPreviewLayer(session: self.captureSession)
        preview.bounds = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: self.view.bounds.height / 2)
        preview.position = CGPoint(x: CGRectGetMidX(self.view.bounds), y: CGRectGetMidY(self.view.bounds)/2)
        preview.videoGravity = AVLayerVideoGravityResize
        return preview
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ImagePicked.contentMode = UIViewContentMode.ScaleAspectFit
        ImagePicked.clipsToBounds = true;
        setupSession(1)
        

//        for i in 1...19{
//            
//            if(i > 10 && i < 100){
//                url = "https://s3.ap-northeast-2.amazonaws.com/skintoneimages/original/00\(i).jpg"
//            }
//            else if(i > 100){
//                url = "https://s3.ap-northeast-2.amazonaws.com/skintoneimages/original/0\(i).jpg"
//            }
//            downloadImage(url)
//        }
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        
        for obj in touches{
            let touchPoint = obj
            
            if let device = self.captureDevice {
                do{
                    try device.lockForConfiguration()
                    device.focusPointOfInterest = touchPoint.locationInView(self.view)
                    device.focusMode = AVCaptureFocusMode.AutoFocus

                    device.unlockForConfiguration()
                    
                }catch let error as NSError{
                    NSLog("\(error),\(error.localizedDescription)")
               
                }
            }
        }
        
    }
    
    
    func setupSession(rgbFlag:Int) {
                
        do{
            let deviceInput = try AVCaptureDeviceInput(device: captureDevice)
            
            captureSession.beginConfiguration()
            if(captureSession.canAddInput(deviceInput) == true){
                captureSession.addInput(deviceInput)
            }
            
            let dataOutput = AVCaptureVideoDataOutput()
            
            if(rgbFlag == 0){
                dataOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as NSString) : NSNumber(unsignedInt: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]
            }
            else if(rgbFlag == 1){
                dataOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as NSString) : NSNumber(unsignedInt: kCVPixelFormatType_32BGRA)]
            }
            dataOutput.alwaysDiscardsLateVideoFrames = true
            
            if (captureSession.canAddOutput(dataOutput) == true) {
                captureSession.addOutput(dataOutput)
            }
            
            captureSession.commitConfiguration()
            
            dataOutput.setSampleBufferDelegate(self, queue: queue)
            
        }catch let error as NSError{
            NSLog("\(error),\(error.localizedDescription)")
        }

    }

    func imagePickerController(picker: UIImagePickerController!, didFinishPickingImage image: UIImage!, editingInfo: NSDictionary!){
        
        self.dismissViewControllerAnimated(true, completion: { () -> Void in
            
        })
        
        ImagePicked.image = ImageProcessor.cannyEdge(image,threshold1: 40,threshold2: 90,flag: 0);
        
    }

    func imageFromSampleBuffer(sampleBuffer:CMSampleBuffer, RGBFlag:Bool, CbCrFlag:Bool) -> UIImage{
        // Get a CMSampleBuffer's Core Video image buffer for the media data
        let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
        // Lock the base address of the pixel buffer
        CVPixelBufferLockBaseAddress(imageBuffer!, 0);
        //Get the base address
        let baseAddress = CVPixelBufferGetBaseAddressOfPlane(imageBuffer!,0)
        // Get the number of bytes per row for the pixel buffer
        let bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(imageBuffer!,0);

        // Get the pixel buffer width and height
        let width = CVPixelBufferGetWidth(imageBuffer!)
        let height = CVPixelBufferGetHeight(imageBuffer!);
        var context:CGContext?
         // Create a device-dependent RGB color space or GRAY color space
        if(RGBFlag || CbCrFlag){
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            context = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow,colorSpace, CGImageAlphaInfo.NoneSkipLast.rawValue);
        }
        else if(!RGBFlag && !CbCrFlag){
            let colorSpace = CGColorSpaceCreateDeviceGray()
            context = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow,colorSpace, CGImageAlphaInfo.None.rawValue);
        }
        else{
            
        }
        let dstCGImage = CGBitmapContextCreateImage(context);
        // Unlock the pixel buffer
        CVPixelBufferUnlockBaseAddress(imageBuffer!,0);
        let dstUIImage = UIImage(CGImage: dstCGImage!);
        return dstUIImage
    }
    
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!) {
        
        dispatch_async(queue,{
            let imagebuffer = self.imageFromSampleBuffer(sampleBuffer,RGBFlag: false, CbCrFlag:true)
            let processedImage = ImageProcessor.extractSkin(imagebuffer) //ImageProcessor.cannyEdge(imagebuffer,threshold1: 30,threshold2: 90,flag: 0);
            dispatch_async(dispatch_get_main_queue(),{
                self.ImagePicked.image = processedImage
                self.ImagePicked.transform = CGAffineTransformMakeRotation(CGFloat(M_PI_2));
            })
        })
        
    }
    
   
    
    func downloadImage(url : String){
        let url = NSURL(string : url)
        
        dispatch_async(queue, {
            
            let data = NSData(contentsOfURL: url!)
            if(data != nil){
                dispatch_async(self.queue, {
                    let image = UIImage(data: data!)
                    let processedImage = ImageProcessor.extractSkin(image)
                    dispatch_async(dispatch_get_main_queue(), {
                            self.ImagePicked.image = processedImage
                        })
                })
                //Inserting algorithm that needs to be trained
            }
        })
    }
    
    //Actions
    
    @IBAction func startCameraButton(sender: AnyObject) {
        view.layer.addSublayer(previewLayer)
        imageProcessor = ImageProcessor()
        captureSession.startRunning()
    }
    
    @IBAction func pauseCameraButton(sender: AnyObject) {
        captureSession.stopRunning()
    }
    
    @IBAction func openGalleryButton(sender: AnyObject) {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.SavedPhotosAlbum){
            
            imagePicker.delegate = self
            imagePicker.sourceType = UIImagePickerControllerSourceType.SavedPhotosAlbum;
            imagePicker.allowsEditing = false
            
            self.presentViewController(imagePicker, animated: true, completion: nil)
        }
    }

    @IBAction func swifthViewButton(sender: AnyObject) {
        let measurementViewController = self.storyboard!.instantiateViewControllerWithIdentifier("MeasurementViewController") as! MeasurementViewController
        self.presentViewController(measurementViewController, animated:true, completion:nil)
    }
}
