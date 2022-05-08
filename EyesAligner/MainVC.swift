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
    private let screenBound = UIScreen.main.bounds
    var mainVM: MainVM! {
        didSet {
            mainVM!.viewDelegate = self
        }
    }
    
    private var face: Face?
    
    private var goldenAreaCGRect: CGRect {
        // make size
        let goldenRectSize = CGSize(width: screenBound.width*0.8, height: screenBound.height*0.3)
        // make origin
        let goldenRectX = (screenBound.width - goldenRectSize.width) / 2
        let goldenRectY = (screenBound.height - goldenRectSize.height) / 2
        let goldenRectOrigin: CGPoint = CGPoint(x:  goldenRectX,y: goldenRectY)
        return CGRect(origin: goldenRectOrigin, size: goldenRectSize)
    }
    
    lazy var textLayer: CATextLayer = {
        let textLayer = CATextLayer()
        
        textLayer.frame = CGRect(x: 0, y: 80, width: screenBound.width, height: 18)
        textLayer.fontSize = 12
        textLayer.alignmentMode = .center
        textLayer.string = "Please hold your beautiful eyes within the golden box! :D"
        textLayer.isWrapped = true
        textLayer.truncationMode = .none
        textLayer.backgroundColor = UIColor.white.cgColor
        textLayer.foregroundColor = UIColor.black.cgColor
        return textLayer
    }()
    
    private lazy var previewLayer = AVCaptureVideoPreviewLayer(session: mainVM.captureSession)
    
    private var drawings: [CAShapeLayer] = [] {
        didSet {
            DispatchQueue.main.async {
                self.drawings.forEach{self.view.layer.addSublayer($0) }
            }
        }
    }
    
    // MARK: Functions
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.previewLayer.frame = self.view.frame
        self.view.layer.addSublayer(drawGoldenArea())
        self.view.layer.addSublayer(textLayer) // caLayer is and instance of parent CALayer
    }
    
    private func makeFace(from landmarks: VNFaceLandmarks2D, faceRect: CGRect) -> Face {
        var face = Face(faceRect: faceRect)
        if let leftEye = landmarks.leftEye {
            face.leftEye = leftEye
        }
        if let rightEye = landmarks.rightEye {
            face.rightEye = rightEye
        }
        return face
    }
}


// MARK: - Drawings
extension MainVC {
    private func makeDrawings(from observedFace: VNFaceObservation, faceRect: CGRect) -> [CAShapeLayer] {
        return drawFaceFeatures(from: observedFace.landmarks!, screenBoundingBox: faceRect)
    }
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
        let goldenAreaLayer = CAShapeLayer()
        goldenAreaLayer.path = UIBezierPath(rect: goldenAreaCGRect).cgPath
        
        goldenAreaLayer.fillColor = UIColor.clear.cgColor
        goldenAreaLayer.strokeColor = UIColor.systemYellow.cgColor
        goldenAreaLayer.lineWidth = 10
        return goldenAreaLayer
    }
}


// MARK: - ViewDelegate
extension MainVC: MainVMViewDelegate {
    func updateLabel(text: String) {
        print(text)
        DispatchQueue.main.async {
            self.textLayer.string = text
        }
    }
    
    func handleFaceDetectionResults(_ observedFace: VNFaceObservation) {
        
        let faceBoundingBoxOnScreen = self.previewLayer.layerRectConverted(fromMetadataOutputRect: observedFace.boundingBox)
        // manage drawings
        self.clearDrawings()
        drawings = makeDrawings(from: observedFace, faceRect: faceBoundingBoxOnScreen)
        
        
        // make face & handle label
        if let landmarks = observedFace.landmarks {
            face = makeFace(from: landmarks, faceRect: faceBoundingBoxOnScreen)
            mainVM.handleLabel(face: face!, goldenArea: goldenAreaCGRect)
        }
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
