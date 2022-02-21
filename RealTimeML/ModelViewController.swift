//
//  ModelViewController.swift
//  RealTimeML
//
//  Created by 吳佳穎 on 2022/2/21.
//

import UIKit
import AVFoundation
import Vision

class ModelViewController: ViewController {

    
    @IBOutlet weak var classLabel: UILabel!
    @IBOutlet weak var confidenceLabel: UILabel!
    var allRequests =  [VNImageBasedRequest]()
    override func viewDidLoad() {
        super.viewDidLoad()
        setupModel()
        startCaptureSession()

    }

    func setupModel(){
        // 1). load core ml model
        guard let model = try? VNCoreMLModel(for: MobileNet(configuration: MLModelConfiguration()).model) else {fatalError("No model found when loading")}
        // 2). make core ml request
        let singleRequest = VNCoreMLRequest(model: model) { request, error in
        guard let result = request.results as? [VNClassificationObservation] else {fatalError("No detection result!")}
            if let firstResult = result.first {
                DispatchQueue.main.sync {
                    self.classLabel.text = firstResult.identifier
                    self.confidenceLabel.text = String("\(firstResult.confidence)")
                }
            }
        }
        self.allRequests = [singleRequest]
    }
    
    override func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // convert sample buffer to image buffer
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            print("conver sample buffer to image buffer fail!")
            return
        }
        // setup orientation
        let exifOrientation = exifOrientationFromDeviceOrientation()
        
        // 3). new a vision image request handler
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: exifOrientation, options: [:])
        
        // 4). Perform request
        do {
            try handler.perform(self.allRequests)
        }catch {
            print("detection handler error: \(error)")
        }
        
        
        
    }
    
}
