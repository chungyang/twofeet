//
//  MeasurementViewController.swift
//  twofeet
//
//  Created by chung yang on 5/21/16.
//  Copyright © 2016 chung yang. All rights reserved.
//

import Foundation
import AudioToolbox

class MeasurementViewController: UIViewController{
    
    //This array stores height points, aspect ratio, and screen size in inch for different iphone models. These values
    //are needed to translate values we receive in the software to real lengths
    let iphone5Info : [Double] = [568,16,9,4]
    var lowestPoint : CGFloat?
    var highestPoint : CGFloat?
    var pointLength : Double = 0.0
    var toeLength : Double = 0.0
    let screenSize: CGRect = UIScreen.mainScreen().bounds
    var screenHeight : CGFloat = 0.0
    var counter : Int = 0
    
    //Properties
    @IBOutlet var longPressureGesture: UILongPressGestureRecognizer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.multipleTouchEnabled = true
        screenHeight = screenSize.height
        lowestPoint = screenHeight
        highestPoint = 0.0
        pointLength = lengthPerPoint(iphone5Info)
    }
    
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {

        for obj in touches {
            let touch = obj
            let location = touch.locationInView(self.view)
            if(location.y > highestPoint){
                highestPoint = location.y
            }
            if(location.y < lowestPoint){
                lowestPoint = location.y
            }
        }
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        for obj in touches {
            let touch = obj
            let location = touch.locationInView(self.view)
            if(counter != 500){
                if(location.y > highestPoint){
                    highestPoint = location.y
                }
                if(location.y < lowestPoint){
                    lowestPoint = location.y
                }
                 counter += 1
            }
            else{
                self.counter = 0
                AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))

                let alertController = UIAlertController(title: "Finsih", message:
                    "Toe length found", preferredStyle: UIAlertControllerStyle.Alert)
                let oKAction = UIAlertAction(title: "Ok", style: .Cancel) { (action:UIAlertAction!) in
                    self.toeLength = Double(self.highestPoint! - self.lowestPoint!) * self.pointLength
                    self.lowestPoint = self.screenHeight
                    self.highestPoint = 0.0
                    print(self.toeLength)
                }
                alertController.addAction(oKAction)
                
                self.presentViewController(alertController, animated: true, completion: nil)
            }
        }
    }
    
    func lengthPerPoint(model:[Double]) -> Double{
        let d = model[3]
        let r = model[1] / model[2]
        let h = sqrt(pow(d,2)/(1 + 1 / pow(r,2)))
        
        return h / model[0]
    }
    
    //Action
    @IBAction func rootViewButton(sender: AnyObject) {
        let rootViewController = self.storyboard!.instantiateViewControllerWithIdentifier("RootViewController") as! RootViewController
        self.presentViewController(rootViewController, animated:true, completion:nil)
    }
}