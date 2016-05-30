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
    var imageProcessor = ImageProcessor()
    var gotSkinTone = false
    
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
        ImagePicked.contentMode = UIViewContentMode.ScaleAspectFill
        ImagePicked.clipsToBounds = true;
        setupSession(1)
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
        
        gotSkinTone = false;
        
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

    func imageFromSampleBuffer(sampleBuffer:CMSampleBuffer) -> UIImage{
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
         // Create a device-dependent RGB color space or GRAY color space
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        //let colorSpace = CGColorSpaceCreateDeviceGray()
        //let context = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow,colorSpace, CGImageAlphaInfo.None.rawValue);
        let context = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow,colorSpace, CGImageAlphaInfo.NoneSkipLast.rawValue);
        if(context == nil){
            print("context returned nil")
        }
        let dstCGImage = CGBitmapContextCreateImage(context);
        // Unlock the pixel buffer
        CVPixelBufferUnlockBaseAddress(imageBuffer!,0);
        let dstUIImage = UIImage(CGImage: dstCGImage!);
        return dstUIImage
    }
    
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!) {
        
        dispatch_async(queue,{
            print("start processing")
            let imagebuffer = self.imageFromSampleBuffer(sampleBuffer)
          //  if(!self.gotSkinTone){
                self.imageProcessor.extractSkinTone(imagebuffer)
           //     self.gotSkinTone = true
            //}
           // else{
                //let processedImage = self.imageProcessor.showsOnlySkinTone(imagebuffer)
                print("finsih processing")
                dispatch_async(dispatch_get_main_queue(),{
                    print("post result")
                   // self.ImagePicked.image = processedImage
                    self.ImagePicked.transform = CGAffineTransformMakeRotation(CGFloat(M_PI_2));
                })
            //}
        })
    }

    
    //Actions
    
    @IBAction func startCameraButton(sender: AnyObject) {
        view.layer.addSublayer(previewLayer)
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
