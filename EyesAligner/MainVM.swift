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
    func handleFaceDetectionResults(_ observedFaces: [VNFaceObservation])
    func clearDrawings()
    func configPreviewLayer()
}
class MainVM: NSObject {
    var viewDelegate: MainVMViewDelegate?
    
    func start() {
        self.addCameraInput()
        viewDelegate!.configPreviewLayer()
        self.getCameraFrames()
        self.captureSession.startRunning()
    }
    
    let captureSession = AVCaptureSession() //it's front camera within itself
    // 1- fill capture session from device
    private func addCameraInput() {
        guard let device = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera, .builtInDualCamera, .builtInTrueDepthCamera],
            mediaType: .video,
            position: .front).devices.first else {
                fatalError("No back camera device found, please make sure to run SimpleLaneDetection in an iOS device and not a simulator")
        }
        let cameraInput = try! AVCaptureDeviceInput(device: device)
        self.captureSession.addInput(cameraInput)
    }
    
    private let videoDataOutput = AVCaptureVideoDataOutput()
    // 3- config videoDataOutput and add it on captureSession
    private func getCameraFrames() {
        self.videoDataOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as NSString) : NSNumber(value: kCVPixelFormatType_32BGRA)] as [String : Any]
        self.videoDataOutput.alwaysDiscardsLateVideoFrames = true
        self.videoDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "camera_frame_processing_queue"))
        self.captureSession.addOutput(self.videoDataOutput)
        guard let connection = self.videoDataOutput.connection(with: AVMediaType.video),
            connection.isVideoOrientationSupported else { return }
        connection.videoOrientation = .portrait
    }
    
    // 5- perform face detection command
    private func detectFace(in image: CVPixelBuffer) {
        let faceDetectionRequest = VNDetectFaceLandmarksRequest(completionHandler: { (request: VNRequest, error: Error?) in
            DispatchQueue.main.async {
                if let results = request.results as? [VNFaceObservation] {
                    self.viewDelegate?.handleFaceDetectionResults(results)
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
    // 4- convert output to frame
    // and call detectFace
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection) {
        
        guard let frame = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            debugPrint("unable to get image from sample buffer")
            return
        }
        self.detectFace(in: frame)
    }
}
