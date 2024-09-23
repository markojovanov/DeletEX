//
//  FaceNet.swift
//  DeletEX
//
//  Created by Marko Jovanov on 19.9.24.
//

import Accelerate
import TensorFlowLite
import UIKit

class FaceNet {
    static let shared = FaceNet()
    private let imgSize = 160
    private let embeddingDim = 128
    private let maxRGBValue: Float32 = 255.0
    private var interpreter: Interpreter

    private init() {
        let options = Interpreter.Options()
        guard let modelPath = Bundle.main.path(forResource: "facenet", ofType: "tflite") else {
            print("Failed to load TensorFlow FaceNet model.")
            fatalError()
        }
        do {
            self.interpreter = try Interpreter(modelPath: modelPath, options: options)
            try interpreter.allocateTensors()
        } catch {
            print("Failed to create interpreter: \(error)")
            fatalError()
        }
    }

    /// Gets a face embedding using FaceNet
    func getFaceEmbedding(image: UIImage) async -> [Float] {
        guard let inputBuffer = processImage(image) else { return [] }

        do {
            try interpreter.copy(inputBuffer, toInputAt: 0)
            try interpreter.invoke()
            let outputTensor = try interpreter.output(at: 0)
            let outputCount = outputTensor.data.count / MemoryLayout<Float>.size
            guard outputCount > 0 else { return [] }
            let embeddings = outputTensor.data.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) -> [Float] in
                let baseAddress = ptr.baseAddress?.assumingMemoryBound(to: Float.self)
                return Array(UnsafeBufferPointer(start: baseAddress, count: outputCount))
            }
            return embeddings
        } catch {
            print("Error during FaceNet processing: \(error)")
            return []
        }
    }

    /// Resize the given UIImage to 160x160 and convert it to normalized RGB Data.
    func processImage(_ image: UIImage) -> Data? {
        let startTime = Date()
        let imgSize = CGSize(width: 160, height: 160)
        guard let resizedImage = ImageUtils.resizeImageWithCoreGraphics(image, newSize: imgSize) else {
            return nil
        }

        guard let context = CGContext(
            data: nil,
            width: Int(imgSize.width),
            height: Int(imgSize.height),
            bitsPerComponent: 8,
            bytesPerRow: Int(imgSize.width) * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        ) else {
            return nil
        }

        context.draw(resizedImage, in: CGRect(x: 0, y: 0, width: Int(imgSize.width), height: Int(imgSize.height)))
        guard let imageData = context.data else { return nil }

        var inputData = Data()
        for row in 0 ..< Int(imgSize.height) {
            for col in 0 ..< Int(imgSize.width) {
                let offset = 4 * (row * context.width + col)

                let red = imageData.load(fromByteOffset: offset, as: UInt8.self)
                let green = imageData.load(fromByteOffset: offset + 1, as: UInt8.self)
                let blue = imageData.load(fromByteOffset: offset + 2, as: UInt8.self)

                // Normalize the RGB values
                let normalizedRed = Float32(red) / maxRGBValue
                let normalizedGreen = Float32(green) / maxRGBValue
                let normalizedBlue = Float32(blue) / maxRGBValue

                // Append normalized values to the Data object in RGB order
                inputData.append(contentsOf: withUnsafeBytes(of: normalizedRed) { Data($0) })
                inputData.append(contentsOf: withUnsafeBytes(of: normalizedGreen) { Data($0) })
                inputData.append(contentsOf: withUnsafeBytes(of: normalizedBlue) { Data($0) })
            }
        }
        let timeInterval = Date().timeIntervalSince(startTime) * 1000
        print("processImage: \(timeInterval) milliseconds")
        return inputData
    }
}
