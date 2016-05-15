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

class RootViewController: UIViewController, UIImagePickerControllerDelegate,UINavigationControllerDelegate{
    
    //Properties
    
    @IBOutlet weak var ImagePicked: UIImageView!
    var imagePicker = UIImagePickerController()
    let captureSession = AVCaptureSession()
    var captureDevice : AVCaptureDevice?
    var previewLayer : AVCaptureVideoPreviewLayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        captureSession.sessionPreset = AVCaptureSessionPresetLow
        
        let devices = AVCaptureDevice.devices()
        
        // Loop through all the capture devices on this phone
        for device in devices {
            // Make sure this particular device supports video
            if (device.hasMediaType(AVMediaTypeVideo)) {
                // Finally check the position and confirm we've got the back camera
                if(device.position == AVCaptureDevicePosition.Back) {
                    captureDevice = (device as? AVCaptureDevice)!
                    if(captureDevice != nil){
                        beginSession()
                    }
                }
            }
        }
    }
    
    func beginSession() {
        
        if(try! captureSession.canAddInput(AVCaptureDeviceInput(device: captureDevice))){
            try! captureSession.addInput(AVCaptureDeviceInput(device: captureDevice))
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        self.view.layer.addSublayer(previewLayer!)
        previewLayer?.frame = self.view.layer.frame
        captureSession.startRunning()
    }
    
    func imagePickerController(picker: UIImagePickerController!, didFinishPickingImage image: UIImage!, editingInfo: NSDictionary!){
        
        self.dismissViewControllerAnimated(true, completion: { () -> Void in
            
        })
        
        ImagePicked.image = ImageProcessor.CannyEdge(image,threshold1: 0,threshold2: 50);
        
    }
    
    //Actions
    @IBAction func openCameraButton(sender: AnyObject) {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera){
           
            imagePicker.delegate = self
            imagePicker.sourceType = UIImagePickerControllerSourceType.Camera;
            imagePicker.allowsEditing = true;
             self.presentViewController(imagePicker, animated: true, completion: nil)
        }
    }
    
    @IBAction func OpenGalleryButton(sender: AnyObject) {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.SavedPhotosAlbum){
            
            imagePicker.delegate = self
            imagePicker.sourceType = UIImagePickerControllerSourceType.SavedPhotosAlbum;
            imagePicker.allowsEditing = false
            
            self.presentViewController(imagePicker, animated: true, completion: nil)
        }
    }
}
