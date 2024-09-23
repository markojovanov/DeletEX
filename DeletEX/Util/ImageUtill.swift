//
//  ImageUtill.swift
//  DeletEX
//
//  Created by Marko Jovanov on 20.9.24.
//

import UIKit

enum ImageUtils {
    static func resizeImageWithCoreGraphics(_ image: UIImage, newSize: CGSize) -> CGImage? {
        guard let cgImage = image.cgImage else { return nil }
        let width = Int(newSize.width)
        let height = Int(newSize.height)
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: cgImage.bitsPerComponent,
            bytesPerRow: cgImage.bitsPerPixel / 8 * width,
            space: cgImage.colorSpace ?? CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: cgImage.bitmapInfo.rawValue
        ) else {
            return nil
        }

        context.interpolationQuality = .high
        context.draw(cgImage, in: CGRect(origin: .zero, size: newSize))
        return context.makeImage()
    }
}
