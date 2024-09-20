//
//  FaceNet.swift
//  DeletEX
//
//  Created by Marko Jovanov on 19.9.24.
//
import Accelerate
import TensorFlowLite
import UIKit

let faceNetQueue = DispatchQueue(label: "com.deletex.facenetQueue")

class FaceNet {
    static let shared = FaceNet()
    private let imgSize = 160
    private let embeddingDim = 128
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
    func getFaceEmbedding(image: UIImage, completion: @escaping ([Float]) -> Void) {
        faceNetQueue.async {
            do {
                let inputBuffer = self.convertUIImageToBuffer(image: image)
//                let inputTensor = try self.interpreter.input(at: 0)
//                print("Input tensor shape: \(inputTensor.shape)")
                try self.interpreter.copy(inputBuffer, toInputAt: 0)
                try self.interpreter.invoke()
                let outputTensor = try self.interpreter.output(at: 0)
//                print("Output tensor shape: \(outputTensor.shape)")
                let outputCount = outputTensor.data.count / MemoryLayout<Float>.size
                guard outputCount > 0 else {
                    completion([])
                    return
                }
                let embeddings = outputTensor.data.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) -> [Float] in
                    let baseAddress = ptr.baseAddress?.assumingMemoryBound(to: Float.self)
                    return Array(UnsafeBufferPointer(start: baseAddress, count: outputCount))
                }
                completion(embeddings)
            } catch {
                print("Error during FaceNet processing: \(error)")
                completion([])
            }
        }
    }

    /// Resize the given UIImage and convert it to a Tensor
    private func convertUIImageToBuffer(image: UIImage) -> Data {
        let resizedImage = image.resized(to: CGSize(width: imgSize, height: imgSize))
        guard let pixelBuffer = resizedImage?.pixelBuffer() else {
            return Data()
        }
        return pixelBuffer
    }
}

/// Extension to resize UIImage
extension UIImage {
    func resized(to size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContext(size)
        draw(in: CGRect(origin: .zero, size: size))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resizedImage
    }

    func pixelBuffer() -> Data? {
        guard let cgImage = cgImage else { return nil }
        let width = cgImage.width
        let height = cgImage.height
        let rgbDataSize = width * height * 3 // RGB only
        var rgbData = [Float](repeating: 0, count: rgbDataSize)

        guard let pixelData = cgImage.dataProvider?.data else { return nil }
        let data = CFDataGetBytePtr(pixelData)

        for y in 0..<height {
            for x in 0..<width {
                let pixelIndex = (y * width + x) * 4
                let r = Float(data![pixelIndex]) / 255.0
                let g = Float(data![pixelIndex + 1]) / 255.0
                let b = Float(data![pixelIndex + 2]) / 255.0

                let rgbIndex = (y * width + x) * 3
                rgbData[rgbIndex] = r
                rgbData[rgbIndex + 1] = g
                rgbData[rgbIndex + 2] = b
            }
        }
        return Data(buffer: UnsafeBufferPointer(start: &rgbData, count: rgbData.count))
    }
}
