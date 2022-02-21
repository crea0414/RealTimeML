//
//  ViewController.swift
//  RealTimeML
//
//  Created by 吳佳穎 on 2022/2/17.
//

import UIKit
import AVFoundation
import Vision

class ViewController: UIViewController {

    
    private let session = AVCaptureSession()
    private let videoDataOutput = AVCaptureVideoDataOutput()
    private let videoDataOutputQueue = DispatchQueue(label: "VideoDataOutput", qos: .userInitiated, attributes: [], autoreleaseFrequency: .workItem)
    
    var bufferSize : CGSize = .zero
    var rootLayer:CALayer! = nil
    private var previewLayer : AVCaptureVideoPreviewLayer! = nil
    
    @IBOutlet var previewView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupAVCpature()
//        startCaptureSession()
    }


}

extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate{
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
    }
    
    func setupAVCpature(){
        
        /// 1). Find a suitable caputure device
        // a).Sort and Filter Devices with a Discovery Session
        guard let videoDevice = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .back).devices.first else {fatalError("No Camera Device!")}
        // b).Quickly Choose a Default Device
//        let  VideoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
        
        /// 2). Create DeviceInput
        var deviceInput: AVCaptureDeviceInput
        do {
            deviceInput = try AVCaptureDeviceInput(device: videoDevice)
        }catch {
            print("No inputDevice error:\(error)")
            return
        }
        
        /// 3). setup capture session
        // a). setup with smaller image for model
        session.beginConfiguration()
        session.sessionPreset = .vga640x480
        // b). Add input to session
        guard session.canAddInput(deviceInput) else {
            print("Add input device fail")
            session.commitConfiguration()
            return
        }
        session.addInput(deviceInput)
        // c). Add output to session and set it's properties
        if session.canAddOutput(videoDataOutput){
            session.addOutput(videoDataOutput)
            // configue some video output properties
            videoDataOutput.alwaysDiscardsLateVideoFrames = true
            videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_420YpCbCr8PlanarFullRange)]
            videoDataOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
        } else {print("Add output device fail!")
            session.commitConfiguration()
            return
        }
        
        // d). setup output connection
        let connection = videoDataOutput.connection(with: .video)
        connection?.isEnabled = true
        
        // e). Get device properties with lock and try error hamdling
        do {
           try videoDevice.lockForConfiguration()
            let dimension = CMVideoFormatDescriptionGetDimensions(videoDevice.activeFormat.formatDescription)
            bufferSize.width = CGFloat(dimension.width)
            bufferSize.height = CGFloat(dimension.height)
            videoDevice.unlockForConfiguration()
        } catch {
            print("Get video dimension fail with error:\(error)")
        }
        // f). commit session configuration
        session.commitConfiguration()
        
        /// 4). setup preview layer when commited capture session
        // a). init preview layer with capture session
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        // b). setup preview layer size with video gravity property.
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        
        /// 5). Config previewView layer to root layer (CALayer)
        rootLayer = previewView.layer
        previewLayer.frame = rootLayer.bounds
        rootLayer.addSublayer(previewLayer)
    }
    
    func startCaptureSession(){
        session.startRunning()
    }
    
    func teardownAVCapture(){
        previewLayer.removeFromSuperlayer()
        previewLayer = nil
    }
    
    public func exifOrientationFromDeviceOrientation() -> CGImagePropertyOrientation {
        let curDeviceOrientation = UIDevice.current.orientation
        let exifOrientation: CGImagePropertyOrientation
        
        switch curDeviceOrientation {
        case UIDeviceOrientation.portraitUpsideDown:  // Device oriented vertically, home button on the top
            exifOrientation = .left
        case UIDeviceOrientation.landscapeLeft:       // Device oriented horizontally, home button on the right
            exifOrientation = .upMirrored
        case UIDeviceOrientation.landscapeRight:      // Device oriented horizontally, home button on the left
            exifOrientation = .down
        case UIDeviceOrientation.portrait:            // Device oriented vertically, home button on the bottom
            exifOrientation = .up
        default:
            exifOrientation = .up
        }
        return exifOrientation
    }
}
