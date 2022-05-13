//
//  Face.swift
//  EyesAligner
//
//  Created by iMamad on 08.05.22.
//

import Vision

struct Face {
    
    let faceRectOnVision: CGRect
    let eyes: (leftEye: Eye, rightEye: Eye)
    var faceRectOnScreen: CGRect?
    
    init(faceRectOnVision: CGRect, leftEye: VNFaceLandmarkRegion2D, rightEye: VNFaceLandmarkRegion2D) {
        self.faceRectOnVision = faceRectOnVision
        self.eyes.leftEye = Eye(landMark: leftEye)
        self.eyes.rightEye = Eye(landMark: rightEye)
    }
}

struct Eye {
    let landMark: VNFaceLandmarkRegion2D
    init(landMark: VNFaceLandmarkRegion2D) { self.landMark = landMark }
    
    func makeCGPoints(in faceRectOnScreen: CGRect) -> [CGPoint] {
        landMark.normalizedPoints
            .map{ eyePoint in
                CGPoint(
                    x: eyePoint.y * faceRectOnScreen.height + faceRectOnScreen.origin.x,
                    y: eyePoint.x * faceRectOnScreen.width + faceRectOnScreen.origin.y)
            }
    }
}
