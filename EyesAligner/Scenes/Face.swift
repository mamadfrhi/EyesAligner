//
//  Face.swift
//  EyesAligner
//
//  Created by iMamad on 08.05.22.
//

import Vision

struct Face {
    var faceRect: CGRect
    var leftEye: VNFaceLandmarkRegion2D?
    var rightEye: VNFaceLandmarkRegion2D?
    init(faceRect: CGRect) { self.faceRect = faceRect }
}
