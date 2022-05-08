//
//  ViewController.swift
//  EyesAligner
//
//  Created by iMamad on 07.05.22.
//

import UIKit
import AVFoundation
import Vision


class MainVC: UIViewController {
    
    class func `init`(mainVM: MainVM) -> MainVC {
        let vc = MainVC()
        vc.mainVM = mainVM
        return vc
    }
    
    // MARK: Properties
    var mainVM: MainVM! {
        didSet {
            mainVM!.viewDelegate = self
        }
    }
    
    private lazy var previewLayer = AVCaptureVideoPreviewLayer(session: mainVM.captureSession)
    
    private var drawings: [CAShapeLayer] = []
    
    // MARK: Functions
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.previewLayer.frame = self.view.frame
    }
}


// MARK: - Drawings
extension MainVC {
    private func drawFaceFeatures(from landmarks: VNFaceLandmarks2D, screenBoundingBox: CGRect) -> [CAShapeLayer] {
        var faceFeaturesDrawings: [CAShapeLayer] = []
        if let leftEye = landmarks.leftEye {
            let eyeDrawing = self.drawEye(from: leftEye, screenBoundingBox: screenBoundingBox)
            faceFeaturesDrawings.append(eyeDrawing)
        }
        if let rightEye = landmarks.rightEye {
            let eyeDrawing = self.drawEye(from: rightEye, screenBoundingBox: screenBoundingBox)
            faceFeaturesDrawings.append(eyeDrawing)
        }
        // draw other face features here
        return faceFeaturesDrawings
    }
    private func drawEye(from eye: VNFaceLandmarkRegion2D, screenBoundingBox: CGRect) -> CAShapeLayer {
        let eyePath = CGMutablePath()
        let eyePathPoints = eye.normalizedPoints
            .map({ eyePoint in
                CGPoint(
                    x: eyePoint.y * screenBoundingBox.height + screenBoundingBox.origin.x,
                    y: eyePoint.x * screenBoundingBox.width + screenBoundingBox.origin.y)
            })
        eyePath.addLines(between: eyePathPoints)
        eyePath.closeSubpath()
        let eyeDrawing = CAShapeLayer()
        eyeDrawing.path = eyePath
        eyeDrawing.fillColor = UIColor.clear.cgColor
        eyeDrawing.strokeColor = UIColor.green.cgColor
        
        return eyeDrawing
    }
    
    private func drawGoldenArea() -> CAShapeLayer {
        // -- prepare golden area layer --
        let screenBound = UIScreen.main.bounds
        // make size
        let goldenRectSize = CGSize(width: screenBound.width*0.8, height: screenBound.height*0.3)
        // make origin
        let goldenRectX = (screenBound.width - goldenRectSize.width) / 2
        let goldenRectY = (screenBound.height - goldenRectSize.height) / 2
        let goldenRectOrigin: CGPoint = CGPoint(x:  goldenRectX,y: goldenRectY)
        
        let goldenAreaLayer = CAShapeLayer()
        goldenAreaLayer.path = UIBezierPath(rect: CGRect(origin: goldenRectOrigin, size: goldenRectSize)).cgPath
        
        goldenAreaLayer.fillColor = UIColor.clear.cgColor
        goldenAreaLayer.strokeColor = UIColor.systemYellow.cgColor
        goldenAreaLayer.lineWidth = 10
        return goldenAreaLayer
    }
}


// MARK: - ViewDelegate
extension MainVC: MainVMViewDelegate {
    
    
    func handleFaceDetectionResults(_ observedFaces: [VNFaceObservation]) {
        
        self.clearDrawings()
        let facesBoundingBoxes: [CAShapeLayer] = observedFaces.flatMap({ (observedFace: VNFaceObservation) -> [CAShapeLayer] in
            
            // -- find face rect --
            let faceBoundingBoxOnScreen = self.previewLayer.layerRectConverted(fromMetadataOutputRect: observedFace.boundingBox)
            
            // -- add face eyes to drawings --
            var newDrawings = [CAShapeLayer]()
            if let landmarks = observedFace.landmarks {
                let faceFeatureDrawings = self.drawFaceFeatures(from: landmarks,
                                                                screenBoundingBox: faceBoundingBoxOnScreen)
                _ = faceFeatureDrawings.map { newDrawings.append($0) }
            }
            
            // -- add face golden area to drawings --
            newDrawings.append(drawGoldenArea())
            
            return newDrawings
        })
        facesBoundingBoxes.forEach({ faceBoundingBox in self.view.layer.addSublayer(faceBoundingBox) })
        self.drawings = facesBoundingBoxes
    }
    
    func configPreviewLayer() {
        self.previewLayer.videoGravity = .resizeAspectFill
        self.view.layer.addSublayer(self.previewLayer)
        self.previewLayer.frame = self.view.frame
    }
    
    func clearDrawings() {
        self.drawings.forEach({ drawing in drawing.removeFromSuperlayer() })
    }
}
