//
//  VideoCapturer.swift
//  Age
//
//  Created by Volvet Zhang on 2017/8/11.
//  Copyright © 2017 Volvet Zhang. All rights reserved.
//

import Foundation
import CoreVideo
import AVFoundation
import UIKit

public protocol VideoCapturerDelegate : class {
    func onVideoCaptured(_ capturer : VideoCapturer, didCaptureFrame : CVPixelBuffer, timestamp : CMTime)
}

public class VideoCapturer : NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    public var previewLayer : AVCaptureVideoPreviewLayer?
    public weak var deletate : VideoCapturerDelegate?
    public let fps = 1
    
    let captureSession = AVCaptureSession()
    let videoOutput = AVCaptureVideoDataOutput()
    let queue = DispatchQueue(label: "CaptureSessionQueue")
    var lastTimestamp = CMTime()
    
    
    public func setup(sessionPreset : AVCaptureSession.Preset = .medium,
                      completion : @escaping (Bool) -> Void) {
        queue.async {
            let success = self.setupCamera(sessionPreset: sessionPreset)
            
            DispatchQueue.main.async {
                completion(success)
            }
        }
    }
    
    func setupCamera(sessionPreset : AVCaptureSession.Preset) -> Bool {
        captureSession.beginConfiguration()
        
        captureSession.sessionPreset = sessionPreset
        
        guard let device = AVCaptureDevice.default(AVCaptureDevice.DeviceType.builtInWideAngleCamera, for: AVMediaType.video, position: AVCaptureDevice.Position.front) else {
            NSLog("no video capture device found")
            captureSession.commitConfiguration()
            return false
        }
        
        guard let videoInput = try? AVCaptureDeviceInput(device: device) else {
            NSLog("create video input fail")
            captureSession.commitConfiguration()
            return false
        }
        
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        }
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspect
        previewLayer.connection?.videoOrientation = .portrait
        self.previewLayer = previewLayer
        
        let settings: [String : Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: NSNumber(value: kCVPixelFormatType_32BGRA)
        ]
        
        videoOutput.videoSettings = settings
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.setSampleBufferDelegate(self, queue: queue)
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }
        
        videoOutput.connection(with: AVMediaType.video)?.videoOrientation = .portrait
        
        captureSession.commitConfiguration()
        return true
    }
    
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        let deltatime = timestamp - lastTimestamp
        if deltatime >= CMTimeMake(1, Int32(fps)){
            guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
                return
            }
            lastTimestamp = timestamp
            deletate?.onVideoCaptured(self, didCaptureFrame: imageBuffer, timestamp: timestamp)
        }
    }
    
    public func start() {
        if !captureSession.isRunning {
            captureSession.startRunning()
        }
    }
    
    public func stop() {
        if captureSession.isRunning {
            captureSession.stopRunning()
        }
    }
}
