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
    private var mainVM: MainVM! {
        didSet { mainVM!.viewDelegate = self }
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
    
    private lazy var textLayer: CATextLayer = {
        let textLayer = CATextLayer()
        
        textLayer.frame = CGRect(x: 0, y: 80, width: screenBound.width, height: 18)
        textLayer.fontSize = 12
        textLayer.alignmentMode = .center
        textLayer.string = "Please hold your beautiful 👀 within the golden box! :D"
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
        previewLayer.frame = view.frame
        view.layer.addSublayer(drawGoldenArea())
        view.layer.addSublayer(textLayer)
    }
    
    private func makeFace(from landmarks: VNFaceLandmarks2D, faceRect: CGRect) -> Face {
        //TODO: force unwrapp is bad
        var face = Face(faceRect: faceRect, leftEye: landmarks.leftEye!, rightEye: landmarks.rightEye!)
        if let leftEye = landmarks.leftEye { face.leftEye = leftEye }
        if let rightEye = landmarks.rightEye { face.rightEye = rightEye }
        return face
    }
}


// MARK: - Drawings
extension MainVC {
    private func makeDrawings(from observedFace: VNFaceObservation, faceRect: CGRect) -> [CAShapeLayer] {
        return drawFaceFeatures(from: observedFace.landmarks!, faceBoundingBox: faceRect)
    }
    private func drawFaceFeatures(from landmarks: VNFaceLandmarks2D, faceBoundingBox: CGRect) -> [CAShapeLayer] {
        var faceFeaturesDrawings: [CAShapeLayer] = []
        if let leftEye = landmarks.leftEye {
            let eyeDrawing = drawEye(from: leftEye, faceBoundingBox: faceBoundingBox)
            faceFeaturesDrawings.append(eyeDrawing)
        }
        if let rightEye = landmarks.rightEye {
            let eyeDrawing = drawEye(from: rightEye, faceBoundingBox: faceBoundingBox)
            faceFeaturesDrawings.append(eyeDrawing)
        }
        // draw other face features here
        return faceFeaturesDrawings
    }
    private func drawEye(from eye: VNFaceLandmarkRegion2D, faceBoundingBox: CGRect) -> CAShapeLayer {
        let eyePath = CGMutablePath()
        let eyePathPoints = eye.normalizedPoints
            .map{ eyePoint in
                CGPoint(
                    x: eyePoint.y * faceBoundingBox.height + faceBoundingBox.origin.x,
                    y: eyePoint.x * faceBoundingBox.width + faceBoundingBox.origin.y)
            }
        eyePath.addLines(between: eyePathPoints)
        eyePath.closeSubpath()
        let eyeDrawing = CAShapeLayer()
        eyeDrawing.path = eyePath
        eyeDrawing.fillColor = UIColor.clear.cgColor
        eyeDrawing.strokeColor = UIColor.white.cgColor
        
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
        DispatchQueue.main.async {
            if (self.textLayer.string as? String) != text {
                self.textLayer.string = text
                UINotificationFeedbackGenerator().notificationOccurred(.warning)
            }
        }
    }
    
    func handleFaceDetectionResults(_ observedFace: VNFaceObservation) {
        
        let faceBoundingBoxOnScreen = previewLayer.layerRectConverted(fromMetadataOutputRect: observedFace.boundingBox)
        // manage drawings
        clearDrawings()
        drawings = makeDrawings(from: observedFace, faceRect: faceBoundingBoxOnScreen)
        
        
        // make face & handle label
        if let landmarks = observedFace.landmarks {
            face = makeFace(from: landmarks, faceRect: faceBoundingBoxOnScreen)
            mainVM.handleLabel(face: face!, goldenArea: goldenAreaCGRect)
        }
    }
    
    func configPreviewLayer() {
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        previewLayer.frame = view.frame
    }
    
    func clearDrawings() {
        drawings.forEach{ drawing in drawing.removeFromSuperlayer() }
    }
}
