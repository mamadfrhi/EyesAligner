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
    func handleFaceDetectionResults(_ observedFace: VNFaceObservation)
    func clearDrawings()
    func configPreviewLayer()
    func updateLabel(text: String)
}
class MainVM: NSObject {
    var viewDelegate: MainVMViewDelegate?
    
    func start() {
        self.addCameraInput()
        viewDelegate!.configPreviewLayer()
        self.getCameraFrames()
        self.captureSession.startRunning()
    }
    
    func handleLabel(face: Face, goldenArea: CGRect) {
        let screenSize = UIScreen.main.bounds
        let imageSize = CGSize(width: screenSize.width, height: screenSize.height)
        
        if let leftEye = face.leftEye, let rightEye = face.rightEye {
            let leftEyePoint = getTransformedPoints(landmark: leftEye,
                                                        faceRect: face.faceRect,
                                                        imageSize: imageSize)
            let rightEyePoint = getTransformedPoints(landmark: rightEye,
                                                        faceRect: face.faceRect,
                                                        imageSize: imageSize)
            let isInGoldenArea = goldenArea.contains(leftEyePoint.first!) && goldenArea.contains(rightEyePoint.last!)
            if isInGoldenArea {
                viewDelegate?.updateLabel(text: "Good ✅")
            }else {
                viewDelegate?.updateLabel(text: "Fail ❌")
            }
        }
    }
    
    func getTransformedPoints(
        landmark:VNFaceLandmarkRegion2D,
        faceRect:CGRect,
        imageSize:CGSize) -> [CGPoint]{
            
            // last point is 0.0
            return landmark.normalizedPoints.map({ (np) -> CGPoint in
                return CGPoint(
                    x: faceRect.origin.x + np.x * faceRect.size.width,
                    y: imageSize.height - (np.y * faceRect.size.height + faceRect.origin.y))
            })
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
            if let faces = request.results as? [VNFaceObservation], let firstFace = faces.first {
                self.viewDelegate?.handleFaceDetectionResults(firstFace)
            } else {
                self.viewDelegate?.clearDrawings()
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
