//
//  ViewController.swift
//  smartsight
//
//  Created by Tyler Ilunga on 7/18/17.
//  Copyright © 2017 Tyler Ilunga. All rights reserved.
//

import UIKit
import AVKit
import Vision

class SmartSight: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    let labelID: UILabel = {
        let label = UILabel()
        label.text = "Analyzing..."
        label.textColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let titleID: UILabel = {
        let label = UILabel()
        label.text = "SmartSight"
        label.textColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .black
        
        setUpCamera()
        setupIDConfidenceLabel()
        setUpTitleLabel()
    }
    
    fileprivate func setupIDConfidenceLabel() {
        view.addSubview(labelID)
        labelID.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -25).isActive = true
        labelID.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        labelID.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        labelID.heightAnchor.constraint(equalToConstant: 50).isActive = true
    }
    
    fileprivate func setUpTitleLabel() {
        view.addSubview(titleID)
        titleID.topAnchor.constraint(equalTo: view.topAnchor, constant: 25).isActive = true
        titleID.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        titleID.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        titleID.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        
        
        
    }
    
    func setUpCamera() {
        let captureSession = AVCaptureSession()
        captureSession.sessionPreset = .photo
        guard let captureDevice = AVCaptureDevice.default(for: .video) else { return }
        guard let input = try? AVCaptureDeviceInput(device: captureDevice) else { return }
        captureSession.addInput(input)
        captureSession.startRunning()
        
        //proxy to what we are seeing
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        view.layer.addSublayer(previewLayer)
        previewLayer.frame = view.frame
        
        //access to camera's frame layer | monitor frames being captured
        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        captureSession.addOutput(dataOutput)
        
    }
    
    //called everytime the camera is able to capture a frame
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        //cvpixalbuffer
        guard let pixalBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        //analyze image
        var models = [VNCoreMLModel]()
        
        guard let rModel = try? VNCoreMLModel(for: Resnet50().model) else {return}
        guard let sModel = try? VNCoreMLModel(for: SqueezeNet().model) else {return}
        guard let iModel = try? VNCoreMLModel(for: Inceptionv3().model) else {return}
        guard let vModel = try? VNCoreMLModel(for: VGG16().model) else {return}
        
        models += [rModel, sModel, iModel, vModel]
        
        for m in models {
            let request = VNCoreMLRequest(model: m) { (finishReq, err) in
                //check err
                if let err = err {
                    print(err)
                }
                
                //camera guessing images
                guard let results = finishReq.results as? [VNClassificationObservation] else { return }
                
                guard let firstObservation = results.first else { return }
                
                let identity = firstObservation.identifier
                let confidence = firstObservation.confidence
                
                if confidence >= 0.5 {
                    print(identity, confidence)
                    
                    DispatchQueue.main.async {
                        self.labelID.text = "Object: \(identity) Confidence: \(Int(confidence * 100))" + "%"
                    }
                    
                }
                
            }
            
            try? VNImageRequestHandler(cvPixelBuffer: pixalBuffer, options: [:]).perform([request])
        }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }


}

