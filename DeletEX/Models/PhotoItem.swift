//
//  PhotoItem.swift
//  DeletEX
//
//  Created by Marko Jovanov on 16.8.24.
//

import Photos
import UIKit
import Vision

struct PhotoItem: Identifiable, Hashable {
    let id = UUID()
    let image: UIImage
    let phAsset: PHAsset
    let faceObservation: VNFaceObservation
}
