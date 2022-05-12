//
//  Face.swift
//  EyesAligner
//
//  Created by iMamad on 08.05.22.
//

import Vision

struct Face {
    
    var faceRect: CGRect
    var leftEye: VNFaceLandmarkRegion2D
    var rightEye: VNFaceLandmarkRegion2D
    
    init(faceRect: CGRect, leftEye: VNFaceLandmarkRegion2D, rightEye: VNFaceLandmarkRegion2D) {
        self.faceRect = faceRect
        self.leftEye = leftEye
        self.rightEye = rightEye
    }
    
    var leftEyeCGPoints: [CGPoint] {
        let eyePathPoints = leftEye.normalizedPoints
            .map{ eyePoint in
                CGPoint(
                    x: eyePoint.y * faceRect.height + faceRect.origin.x,
                    y: eyePoint.x * faceRect.width + faceRect.origin.y)
            }
        return eyePathPoints
    }
    
    var rightEyeCGPoints: [CGPoint] {
        let eyePathPoints = rightEye.normalizedPoints
            .map{ eyePoint in
                CGPoint(
                    x: eyePoint.y * faceRect.height + faceRect.origin.x,
                    y: eyePoint.x * faceRect.width + faceRect.origin.y)
            }
        return eyePathPoints
    }
}
