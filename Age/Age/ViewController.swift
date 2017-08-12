//
//  ViewController.swift
//  Age
//
//  Created by Volvet Zhang on 2017/8/11.
//  Copyright © 2017 Volvet Zhang. All rights reserved.
//

import UIKit
import CoreMedia
import Vision

class ViewController: UIViewController {
    
    @IBOutlet weak var mPreviewView: UIView!
    @IBOutlet weak var mInfo: UILabel!
    @IBOutlet weak var mGenderInfo: UILabel!
    
    let ageModel = AgeNet()
    let genderModel = GenderNet()
    
    var videoCapturer : VideoCapturer?
    var ageRequest : VNCoreMLRequest!
    var genderRequest : VNCoreMLRequest!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        setupVision()
        setupCamera()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.videoCapturer?.stop()
    }
    

    func setupCamera() {
        videoCapturer = VideoCapturer()
        videoCapturer?.deletate = self
        
        videoCapturer?.setup { success in
            if success {
                if let previewLayer = self.videoCapturer?.previewLayer {
                    self.mPreviewView.layer.addSublayer(previewLayer)
                    previewLayer.frame = self.mPreviewView.bounds
                }
                
                self.videoCapturer?.start()
            }
        }
    }
    
    func setupVision() {
        guard let vnAgeModel = try? VNCoreMLModel(for: ageModel.model) else {
            NSLog("Load age model fail")
            return
        }
        ageRequest = VNCoreMLRequest(model: vnAgeModel, completionHandler: { (request : VNRequest, error : Error? ) in
            //NSLog("VNCoreML Request complete")
            
            if let observations = request.results as? [VNClassificationObservation] {
                if( observations.count > 1  && observations[0].confidence > 0.5 ){
                    DispatchQueue.main.async {
                        self.mInfo.text = "Your age is " + observations[0].identifier + "/" + String(observations[0].confidence)
                    }
                }
            }
            return
        })
        ageRequest?.imageCropAndScaleOption = .centerCrop
        
        guard let vnGenderModel = try? VNCoreMLModel(for: genderModel.model) else {
            NSLog("Load gender model fail")
            return
        }
        
        genderRequest = VNCoreMLRequest(model: vnGenderModel, completionHandler: { (request : VNRequest, error : Error?) in
            if let observations = request.results as? [VNClassificationObservation] {
                if observations.count > 1 {
                    DispatchQueue.main.async {
                        self.mGenderInfo.text = "You gender is " + observations[0].identifier
                    }
                }
            }
        })
    }
    
    func predict(pixelBuffer : CVPixelBuffer) {
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer)
        try? handler.perform([ageRequest])
        
        let genderHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer)
        try? genderHandler.perform([genderRequest])
    }
    
}

extension ViewController : VideoCapturerDelegate {
    func onVideoCaptured(_ capturer : VideoCapturer, didCaptureFrame : CVPixelBuffer, timestamp : CMTime) {
        self.predict(pixelBuffer: didCaptureFrame)
    }
}

