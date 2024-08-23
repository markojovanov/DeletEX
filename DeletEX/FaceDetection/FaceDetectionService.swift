//
//  FaceDetectionService.swift
//  DeletEX
//
//  Created by Marko Jovanov on 17.8.24.
//

import Foundation
import Photos
import UIKit
import Vision

// MARK: - FaceDetectionService

// U face observation imash faceCaptureQuality parameter sho kje ti gu dade najdobrata slika za da gu prikazesh na listata

protocol FaceDetectionService {
    func fetchFacePhotos(completion: @escaping ([PhotoItem]) -> Void)
    func fetchCroppedFacePhotos(from photoItems: [PhotoItem], completion: @escaping ([PhotoItem]) -> Void)
    func matchFaces(from photoItems: [PhotoItem], completion: @escaping ([[PhotoItem]]) -> Void)
}

// MARK: - FaceDetectionServiceImpl

class FaceDetectionServiceImpl: FaceDetectionService {
    func fetchFacePhotos(completion: @escaping ([PhotoItem]) -> Void) {
        let fetchOptions = PHFetchOptions()
        let allPhotos = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        let imageManager = PHImageManager.default()
        let requestOptions = PHImageRequestOptions()
        requestOptions.isSynchronous = true
        requestOptions.deliveryMode = .highQualityFormat

        var photoItems: [PhotoItem] = []

        DispatchQueue.global(qos: .userInitiated).async {
            let group = DispatchGroup()

            allPhotos.enumerateObjects { asset, _, _ in
                group.enter()
                imageManager.requestImage(for: asset,
                                          targetSize: CGSize(width: 300, height: 300),
                                          contentMode: .aspectFit,
                                          options: requestOptions) { image, _ in
                    guard let image = image, let cgImage = image.cgImage else {
                        group.leave()
                        return
                    }

                    let request = VNDetectFaceLandmarksRequest { request, _ in
                    //let request = VNDetectFaceRectanglesRequest { request, _ in

                        if let results = request.results as? [VNFaceObservation], !results.isEmpty {
                            for observation in results {
                                photoItems.append(PhotoItem(image: image, phAsset: asset, faceObservation: observation))
                            }
                        }
                        group.leave()
                    }

                    let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                    try? handler.perform([request])
                }
            }

            group.notify(queue: .main) {
                completion(photoItems)
            }
        }
    }

    func groupPhotosByFace(photoItems: [PhotoItem]) -> [[PhotoItem]] {
        var groupedPhotos: [[PhotoItem]] = []
        var faceGroups: [[VNFaceObservation]] = []

        // Helper function to find if faceObservation already exists in the groups
        func findGroup(for faceObservation: VNFaceObservation) -> Int? {
            for (index, group) in faceGroups.enumerated() {
                for existingFace in group {
                    if areFacesSimilar(faceObservation, existingFace) {
                        return index
                    }
                }
            }
            return nil
        }

        for photoItem in photoItems {
            let faceObservation = photoItem.faceObservation
            if let groupIndex = findGroup(for: faceObservation) {
                groupedPhotos[groupIndex].append(photoItem)
            } else {
                faceGroups.append([faceObservation])
                groupedPhotos.append([photoItem])
            }
        }

        return groupedPhotos
    }

    func matchFaces(from photoItems: [PhotoItem], completion: @escaping ([[PhotoItem]]) -> Void) {
//        var matchedFaces: [VNFaceObservation] = []
//        for photoItem in photoItems {
//            detectFaceLandmarks(from: photoItem.image) { observation in
//                if let observation {
//                    matchedFaces.append(observation[0])
//                }
//            }
//        }
//
//        let match = compareFaces(face1: matchedFaces[0], face2: matchedFaces[1])
//
//        if match {
//            completion(photoItems)
//        } else {
//            completion([])
//        }
        completion(groupPhotosByFace(photoItems: photoItems))
    }
//
//    func matchFaces(from photoItems: [PhotoItem], completion: @escaping ([PhotoItem]) -> Void) {
//        var matchedFaces: [VNFaceObservation] = []
//        for photoItem in photoItems {
//            detectFaceLandmarks(from: photoItem.image) { observation in
//                if let observation {
//                    matchedFaces.append(observation[0])
//                }
//            }
//        }
//
//        let match = compareFaces(face1: matchedFaces[0], face2: matchedFaces[1])
//
//        if match {
//            completion(photoItems)
//        } else {
//            completion([])
//        }
//    }

    func getLastTwoPhotos(from allPhotos: PHFetchResult<PHAsset>) -> [PHAsset] {
        // Get the last two photos
        let lastIndex = allPhotos.count - 1
        let secondLastIndex = lastIndex - 1
        let lastTwoPhotos = [allPhotos.object(at: secondLastIndex), allPhotos.object(at: lastIndex)]

        return lastTwoPhotos
    }

    func fetchCroppedFacePhotos(from photoItems: [PhotoItem], completion: @escaping ([PhotoItem]) -> Void) {
        var croppedFaceItems = [PhotoItem]()
        for photoItem in photoItems {
            let uiImage = cropFaceWithMarginFromImage(image: photoItem.image, faceObservation: photoItem.faceObservation, margin: 10)
                if let croppedFace = uiImage {
                    let croppedFaceItem = PhotoItem(image: croppedFace, phAsset: photoItem.phAsset, faceObservation: photoItem.faceObservation) // trgni ovoa
                    croppedFaceItems.append(croppedFaceItem)
                }
        }
        completion(croppedFaceItems)
    }

    func cropFaceFromImage(image: UIImage, faceObservation: VNFaceObservation) -> UIImage? {
        let boundingBox = faceObservation.boundingBox

        let size = image.size
        let rect = CGRect(x: boundingBox.origin.x * size.width,
                          y: (1 - boundingBox.origin.y - boundingBox.height) * size.height,
                          width: boundingBox.width * size.width,
                          height: boundingBox.height * size.height)

        // Crop the face from the image
        guard let cgImage = image.cgImage?.cropping(to: rect) else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }

    func cropFaceWithMarginFromImage(image: UIImage, faceObservation: VNFaceObservation, margin: CGFloat) -> UIImage? {
        let boundingBox = faceObservation.boundingBox

        // Convert bounding box to image coordinates
        let size = image.size
        var rect = CGRect(x: boundingBox.origin.x * size.width,
                          y: (1 - boundingBox.origin.y - boundingBox.height) * size.height,
                          width: boundingBox.width * size.width,
                          height: boundingBox.height * size.height)

        // Add margin around the face
        rect = rect.insetBy(dx: -margin, dy: -margin)

        // Ensure the rect doesn't exceed the image bounds
        rect.origin.x = max(rect.origin.x, 0)
        rect.origin.y = max(rect.origin.y, 0)
        rect.size.width = min(rect.size.width, size.width - rect.origin.x)
        rect.size.height = min(rect.size.height, size.height - rect.origin.y)

        // Crop the face with margin from the image
        guard let cgImage = image.cgImage?.cropping(to: rect) else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }

    func detectFaceLandmarks(from uiImage: UIImage, completion: @escaping ([VNFaceObservation]?) -> Void) {
        guard let cgImage = uiImage.cgImage else {
            completion(nil)
            return
        }

        let faceLandmarksRequest = VNDetectFaceLandmarksRequest { request, error in
            guard error == nil else {
                completion(nil)
                return
            }
            completion(request.results as? [VNFaceObservation])
        }

        do {
            let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try requestHandler.perform([faceLandmarksRequest])
        } catch {
            completion(nil)
        }
    }

    func compareFaces(face1: VNFaceObservation, face2: VNFaceObservation) -> Bool {
        let similarity = areFacesSimilar(face1, face2)

        print("Similarity \(similarity)")
        // Decide the threshold for similarity
        return similarity
    }

    func compareLandmarks1(_ landmarks1: VNFaceLandmarks2D, _ landmarks2: VNFaceLandmarks2D) -> Float {
        // Here, you can compare specific features like the positions of eyes, nose, mouth, etc.
        // This is a simplified comparison; you can enhance it based on your needs.
        var similarity: Float = 0.0
        // Example: Compare the nose points
        if let nose1 = landmarks1.nose?.normalizedPoints, let nose2 = landmarks2.nose?.normalizedPoints {
            let similarityNose = comparePoints1(nose1, nose2)
            print("Nose similarity \(similarityNose)")
            similarity += similarityNose
        }

        // Example: Compare the eye points
        if let leftEye1 = landmarks1.leftEye?.normalizedPoints, let leftEye2 = landmarks2.leftEye?.normalizedPoints {
            let similarityNose = comparePoints1(leftEye1, leftEye2)
            print("leftEye1 similarity \(similarityNose)")
            similarity += similarityNose
            // similarity += comparePoints(leftEye1, leftEye2)
        }
        // Example: Compare the eye points
        if let leftEye1 = landmarks1.rightEye?.normalizedPoints, let leftEye2 = landmarks2.rightEye?.normalizedPoints {
            let similarityNose = comparePoints1(leftEye1, leftEye2)
            print("rightEye similarity \(similarityNose)")
            similarity += similarityNose
            // similarity += comparePoints(leftEye1, leftEye2)
        }

        // Add more comparisons as needed

        return similarity / 2 // Average similarity
    }

    func compareLandmarks2(_ landmarks1: VNFaceLandmarks2D, _ landmarks2: VNFaceLandmarks2D) -> Float {
        var totalSimilarity: Float = 0.0
        var featureCount = 0

        // Compare Nose
        if let nose1 = landmarks1.nose?.normalizedPoints, let nose2 = landmarks2.nose?.normalizedPoints {
            totalSimilarity += compareAndPrintPoints(featureName: "Nose", nose1, nose2)
            featureCount += 1
        }

        // Compare Left Eye
        if let leftEye1 = landmarks1.leftEye?.normalizedPoints, let leftEye2 = landmarks2.leftEye?.normalizedPoints {
            totalSimilarity += compareAndPrintPoints(featureName: "Left Eye", leftEye1, leftEye2)
            featureCount += 1
        }

        // Compare Right Eye
        if let rightEye1 = landmarks1.rightEye?.normalizedPoints, let rightEye2 = landmarks2.rightEye?.normalizedPoints {
            totalSimilarity += compareAndPrintPoints(featureName: "Right Eye", rightEye1, rightEye2)
            featureCount += 1
        }

        // Compare Mouth
        if let mouth1 = landmarks1.outerLips?.normalizedPoints, let mouth2 = landmarks2.outerLips?.normalizedPoints {
            totalSimilarity += compareAndPrintPoints(featureName: "Mouth", mouth1, mouth2)
            featureCount += 1
        }

        // Compare Left Eyebrow
        if let leftEyebrow1 = landmarks1.leftEyebrow?.normalizedPoints, let leftEyebrow2 = landmarks2.leftEyebrow?.normalizedPoints {
            totalSimilarity += compareAndPrintPoints(featureName: "Left Eyebrow", leftEyebrow1, leftEyebrow2)
            featureCount += 1
        }

        // Compare Right Eyebrow
        if let rightEyebrow1 = landmarks1.rightEyebrow?.normalizedPoints, let rightEyebrow2 = landmarks2.rightEyebrow?.normalizedPoints {
            totalSimilarity += compareAndPrintPoints(featureName: "Right Eyebrow", rightEyebrow1, rightEyebrow2)
            featureCount += 1
        }

        // Compare Face Contour
        if let faceContour1 = landmarks1.faceContour?.normalizedPoints, let faceContour2 = landmarks2.faceContour?.normalizedPoints {
            totalSimilarity += compareAndPrintPoints(featureName: "Face Contour", faceContour1, faceContour2)
            featureCount += 1
        }

        // Ensure we don't divide by zero if no features were compared
        guard featureCount > 0 else {
            return 0.0
        }

        let averageSimilarity = totalSimilarity / Float(featureCount)
        print("Average similarity across all features: \(averageSimilarity)")

        return averageSimilarity
    }

    func comparePoints1(_ points1: [CGPoint], _ points2: [CGPoint]) -> Float {
        guard points1.count == points2.count else {
            return 0.0
        }

        var distance: Float = 0.0
        for i in 0 ..< points1.count {
            let dx = Float(points1[i].x - points2[i].x)
            let dy = Float(points1[i].y - points2[i].y)
            distance += sqrt(dx * dx + dy * dy)
        }

        return 1.0 / (1.0 + distance) // Normalized similarity
    }

    /// Function to compare two sets of points
    func compareAndPrintPoints(featureName: String, _ points1: [CGPoint], _ points2: [CGPoint]) -> Float {
        guard points1.count == points2.count else {
            return 0.0
        }

        var similarity: Float = 0.0
        for (point1, point2) in zip(points1, points2) {
            let distance = hypotf(Float(point1.x - point2.x), Float(point1.y - point2.y))
            similarity += 1.0 / (1.0 + distance)
        }
        similarity = similarity / Float(points1.count)
        print("\(featureName) similarity: \(similarity)")
        return similarity
    }

    func compareAndPrintPoints2(featureName: String, _ points1: [CGPoint], _ points2: [CGPoint]) -> Float {
            guard points1.count == points2.count else {
                print("\(featureName): Points count mismatch")
                return 0.0
            }

            var similarity: Float = 0.0
            for (point1, point2) in zip(points1, points2) {
                let distance = hypotf(Float(point1.x - point2.x), Float(point1.y - point2.y))
                similarity += 1.0 / (1.0 + distance)
            }
            similarity /= Float(points1.count)
            print("\(featureName) similarity: \(similarity)")
            return similarity
        }

    func compareLandmarks3(_ landmarks1: VNFaceLandmarks2D, _ landmarks2: VNFaceLandmarks2D) -> Float {
        var totalSimilarity: Float = 0.0
        var featureCount = 0

        // Function to compare two sets of points and print similarity
        func compareAndPrintPoints(featureName: String, _ points1: [CGPoint], _ points2: [CGPoint]) -> Float {
            guard points1.count == points2.count else {
                print("\(featureName): Points count mismatch")
                return 0.0
            }

            var similarity: Float = 0.0
            for (point1, point2) in zip(points1, points2) {
                let distance = hypotf(Float(point1.x - point2.x), Float(point1.y - point2.y))
                similarity += 1.0 / (1.0 + distance)
            }
            similarity /= Float(points1.count)
            print("\(featureName) similarity: \(similarity)")
            return similarity
        }

        // Compare Nose
        if let nose1 = landmarks1.nose?.normalizedPoints, let nose2 = landmarks2.nose?.normalizedPoints {
            totalSimilarity += compareAndPrintPoints(featureName: "Nose", nose1, nose2)
            featureCount += 1
        }

        // Compare Left Eye
        if let leftEye1 = landmarks1.leftEye?.normalizedPoints, let leftEye2 = landmarks2.leftEye?.normalizedPoints {
            totalSimilarity += compareAndPrintPoints(featureName: "Left Eye", leftEye1, leftEye2)
            featureCount += 1
        }

        // Compare Right Eye
        if let rightEye1 = landmarks1.rightEye?.normalizedPoints, let rightEye2 = landmarks2.rightEye?.normalizedPoints {
            totalSimilarity += compareAndPrintPoints(featureName: "Right Eye", rightEye1, rightEye2)
            featureCount += 1
        }

        // Compare Mouth
        if let mouth1 = landmarks1.outerLips?.normalizedPoints, let mouth2 = landmarks2.outerLips?.normalizedPoints {
            totalSimilarity += compareAndPrintPoints(featureName: "Mouth", mouth1, mouth2)
            featureCount += 1
        }

        // Compare Left Eyebrow
        if let leftEyebrow1 = landmarks1.leftEyebrow?.normalizedPoints, let leftEyebrow2 = landmarks2.leftEyebrow?.normalizedPoints {
            totalSimilarity += compareAndPrintPoints(featureName: "Left Eyebrow", leftEyebrow1, leftEyebrow2)
            featureCount += 1
        }

        // Compare Right Eyebrow
        if let rightEyebrow1 = landmarks1.rightEyebrow?.normalizedPoints, let rightEyebrow2 = landmarks2.rightEyebrow?.normalizedPoints {
            totalSimilarity += compareAndPrintPoints(featureName: "Right Eyebrow", rightEyebrow1, rightEyebrow2)
            featureCount += 1
        }

        // Compare Face Contour
        if let faceContour1 = landmarks1.faceContour?.normalizedPoints, let faceContour2 = landmarks2.faceContour?.normalizedPoints {
            totalSimilarity += compareAndPrintPoints(featureName: "Face Contour", faceContour1, faceContour2)
            featureCount += 1
        }

        // Compare Face Contour
        if let faceContour1 = landmarks1.medianLine?.normalizedPoints, let faceContour2 = landmarks2.medianLine?.normalizedPoints {
            totalSimilarity += compareAndPrintPoints(featureName: "medianLine", faceContour1, faceContour2)
            featureCount += 1
        }
        // Compare Face Contour
        if let faceContour1 = landmarks1.rightPupil?.normalizedPoints, let faceContour2 = landmarks2.rightPupil?.normalizedPoints {
            totalSimilarity += compareAndPrintPoints(featureName: "rightPupil", faceContour1, faceContour2)
            featureCount += 1
        }

        // Compare Face Contour
        if let faceContour1 = landmarks1.leftPupil?.normalizedPoints, let faceContour2 = landmarks2.leftPupil?.normalizedPoints {
            totalSimilarity += compareAndPrintPoints(featureName: "leftPupil", faceContour1, faceContour2)
            featureCount += 1
        }

        // Compare Face Contour
        if let faceContour1 = landmarks1.noseCrest?.normalizedPoints, let faceContour2 = landmarks2.noseCrest?.normalizedPoints {
            totalSimilarity += compareAndPrintPoints(featureName: "noseCrest", faceContour1, faceContour2)
            featureCount += 1
        }

        // Compare Face Contour
        if let faceContour1 = landmarks1.allPoints?.normalizedPoints, let faceContour2 = landmarks2.allPoints?.normalizedPoints {
            totalSimilarity += compareAndPrintPoints(featureName: "allPoints", faceContour1, faceContour2)
            featureCount += 1
        }

        // Ensure we don't divide by zero if no features were compared
        guard featureCount > 0 else {
            return 0.0
        }

        let averageSimilarity = totalSimilarity / Float(featureCount)
        print("Average similarity across all features: \(averageSimilarity)")

        return averageSimilarity
    }


    /// Ovoa rabote malce
    func areFacesSimilar(_ face1: VNFaceObservation, _ face2: VNFaceObservation) -> Bool {
        guard let landmarks1 = face1.landmarks, let landmarks2 = face2.landmarks else {
            return false
        }

        // Helper function to convert VNFaceLandmarkRegion2D to CGPoint array
        func points(from landmark: VNFaceLandmarkRegion2D) -> [CGPoint] {
            return (0..<landmark.pointCount).map { index in
                landmark.normalizedPoints[index]
            }
        }

        // Extract the landmarks
        let points1 = [
            points(from: landmarks1.leftEye!),
            points(from: landmarks1.rightEye!),
            points(from: landmarks1.nose!),
            points(from: landmarks1.outerLips!),
            points(from: landmarks1.innerLips!),
            points(from: landmarks1.faceContour!),
            points(from: landmarks1.leftEyebrow!),
            points(from: landmarks1.rightEyebrow!),
            points(from: landmarks1.allPoints!),
            points(from: landmarks1.leftPupil!),
            points(from: landmarks1.rightPupil!),
            points(from: landmarks1.medianLine!),
            points(from: landmarks1.noseCrest!),
            points(from: landmarks1.outerLips!)
        ]

        let points2 = [
            points(from: landmarks2.leftEye!),
            points(from: landmarks2.rightEye!),
            points(from: landmarks2.nose!),
            points(from: landmarks2.outerLips!),
            points(from: landmarks2.innerLips!),
            points(from: landmarks2.faceContour!),
            points(from: landmarks2.leftEyebrow!),
            points(from: landmarks2.rightEyebrow!),
            points(from: landmarks2.allPoints!),
            points(from: landmarks2.leftPupil!),
            points(from: landmarks2.rightPupil!),
            points(from: landmarks2.medianLine!),
            points(from: landmarks2.noseCrest!),
            points(from: landmarks2.outerLips!)
        ]

        // Calculate average Euclidean distance between corresponding landmark points
        func averageDistance(pointsA: [CGPoint], pointsB: [CGPoint]) -> CGFloat {
            guard pointsA.count == pointsB.count else {
                return CGFloat.greatestFiniteMagnitude
            }
            let distances = zip(pointsA, pointsB).map { pointA, pointB in
                sqrt(pow(pointA.x - pointB.x, 2) + pow(pointA.y - pointB.y, 2))
            }
            return distances.reduce(0, +) / CGFloat(distances.count)
        }

        // Compare each landmark set
        let averageDistances = zip(points1, points2).map { landmarkPoints1, landmarkPoints2 in
            averageDistance(pointsA: landmarkPoints1, pointsB: landmarkPoints2)
        }
        print(averageDistances)

        // Define a threshold for similarity (this might need adjustment)
        let threshold: CGFloat = 0.03

        return averageDistances.filter { $0 < threshold }.count >= 7
    }
}
