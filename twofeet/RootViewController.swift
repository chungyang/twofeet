//
//  RootViewController.swift
//  twofeet
//
//  Created by chung yang on 5/13/16.
//  Copyright © 2016 two feet inc. All rights reserved.
//

import Foundation
import UIKit

class RootViewController: UIViewController, UIImagePickerControllerDelegate,UINavigationControllerDelegate{
    
    //Properties
    
    @IBOutlet weak var ImagePicked: UIImageView!
    var imagePicker = UIImagePickerController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func imagePickerController(picker: UIImagePickerController!, didFinishPickingImage image: UIImage!, editingInfo: NSDictionary!){
        self.dismissViewControllerAnimated(true, completion: { () -> Void in
            
        })
        
        ImagePicked.image = image
        
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
