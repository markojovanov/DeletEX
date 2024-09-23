//
//  PhotoItem.swift
//  DeletEX
//
//  Created by Marko Jovanov on 16.8.24.
//

import Photos
import UIKit

struct PhotoItem: Hashable {
    let image: UIImage
    let croppedFaceImage: UIImage
    let phAsset: PHAsset
    let forFaceRecognition: Bool
}
