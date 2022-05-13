//
//  MainVM.swift
//  EyesAligner
//
//  Created by iMamad on 08.05.22.
//

import UIKit
import AVFoundation
import Vision

protocol MainVMViewDelegate {
    func handleFaceDetectionResults(_ observedFace: Face)
    func clearDrawings()
    func configPreviewLayer()
    func updateLabel(text: String)
}
class MainVM: NSObject {
    
    // MARK: Properties
    var viewDelegate: MainVMViewDelegate?
    let captureSession = AVCaptureSession() // input
    
    private let videoDataOutput = AVCaptureVideoDataOutput() // output
    
    
    // MARK: Funcs
    func start() {
        addCameraInput()
        viewDelegate!.configPreviewLayer()
        getCameraFrames()
        captureSession.startRunning()
    }
    
    func handleLabel(face: Face, goldenArea: CGRect) {
        //TODO: run for loop on eyes Tuple to be DRY
        let leftEyePoint = face.eyes.leftEye.makeCGPoints(in: face.faceRectOnScreen!)
        let rightEyePoint = face.eyes.rightEye.makeCGPoints(in: face.faceRectOnScreen!)
        
        let leftEyeIsInGoldArea = goldenArea.contains(leftEyePoint.first!)
        let rightEyeIsInGoldArea = goldenArea.contains(rightEyePoint.first!)
        
        if leftEyeIsInGoldArea && rightEyeIsInGoldArea {
            viewDelegate?.updateLabel(text: "Good ✅")
        }else {
            viewDelegate?.updateLabel(text: "Fail ❌")
        }
    }
    
    // config input
    private func addCameraInput() {
        guard let device = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera, .builtInDualCamera, .builtInTrueDepthCamera],
            mediaType: .video,
            position: .front).devices.first else {
            fatalError("No back camera device found, please make sure to run SimpleLaneDetection in an iOS device and not a simulator")
        }
        let cameraInput = try! AVCaptureDeviceInput(device: device)
        captureSession.addInput(cameraInput)
    }
    
    // config output
    private func getCameraFrames() {
        videoDataOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as NSString) : NSNumber(value: kCVPixelFormatType_32BGRA)] as [String : Any]
        videoDataOutput.alwaysDiscardsLateVideoFrames = true
        videoDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "camera_frame_processing_queue"))
        captureSession.addOutput(videoDataOutput)
        guard let connection = videoDataOutput.connection(with: AVMediaType.video),
              connection.isVideoOrientationSupported else { return }
        connection.videoOrientation = .portrait
    }
    
    private func detectFace(in image: CVPixelBuffer) {
        let faceDetectionRequest = VNDetectFaceLandmarksRequest(completionHandler: { (request: VNRequest, error: Error?) in
            if let faces = request.results as? [VNFaceObservation],
               let firstFace = faces.first {
                
                if let leftEye = firstFace.landmarks?.leftEye,
                   let rightEye = firstFace.landmarks?.rightEye {
                    let face = Face(faceRectOnVision: firstFace.boundingBox,
                                    leftEye: leftEye,
                                    rightEye: rightEye)
                    self.viewDelegate?.handleFaceDetectionResults(face)
                } else {
                    self.viewDelegate?.clearDrawings()
                }
            }
        })
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: image, orientation: .leftMirrored, options: [:])
        try? imageRequestHandler.perform([faceDetectionRequest])
    }
}

extension MainVM: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection) {
            
            guard let frame = CMSampleBufferGetImageBuffer(sampleBuffer) else {
                debugPrint("unable to get image from sample buffer")
                return
            }
            detectFace(in: frame)
        }
}
