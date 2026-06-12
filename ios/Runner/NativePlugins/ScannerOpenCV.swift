// ios/Runner/NativePlugins/ScannerOpenCV.swift
// iOS 端 OpenCV 桥接(使用 Vision Framework 做透视矫正,免额外依赖)
import Foundation
import CoreImage
import Vision
import UIKit

@objc class ScannerOpenCV: NSObject {

  /// 使用 Vision 框架进行透视矫正(Apple 原生,无需 OpenCV)
  @objc static func warpPerspective(
    imageData: Data,
    width: Int,
    height: Int,
    corners: [NSNumber],  // [x0,y0, x1,y1, x2,y2, x3,y3]
    outWidth: Int,
    outHeight: Int,
    completion: @escaping (Data?) -> Void
  ) {
    guard let cgImage = UIImage(data: imageData)?.cgImage else {
      completion(nil)
      return
    }

    // 源角点(Vision 使用归一化坐标 [0,1])
    let srcPoints = [
      CGPoint(x: corners[0].doubleValue, y: corners[1].doubleValue),
      CGPoint(x: corners[2].doubleValue, y: corners[3].doubleValue),
      CGPoint(x: corners[4].doubleValue, y: corners[5].doubleValue),
      CGPoint(x: corners[6].doubleValue, y: corners[7].doubleValue)
    ]

    // 目标角点
    let dstPoints = [
      CGPoint(x: 0, y: 0),
      CGPoint(x: 1, y: 0),
      CGPoint(x: 1, y: 1),
      CGPoint(x: 0, y: 1)
    ]

    // 使用 Core Image 的 CIPerspectiveCorrection
    let ciImage = CIImage(cgImage: cgImage)
    let filter = CIFilter(name: "CIPerspectiveCorrection")!

    filter.setValue(ciImage, forKey: kCIInputImageKey)
    filter.setValue(CIVector(cgPoint: srcPoints[0]), forKey: "inputTopLeft")
    filter.setValue(CIVector(cgPoint: srcPoints[1]), forKey: "inputTopRight")
    filter.setValue(CIVector(cgPoint: srcPoints[2]), forKey: "inputBottomRight")
    filter.setValue(CIVector(cgPoint: srcPoints[3]), forKey: "inputBottomLeft")

    guard let outputImage = filter.outputImage else {
      completion(nil)
      return
    }

    let context = CIContext()
    guard let resultCG = context.createCGImage(outputImage, from: outputImage.extent) else {
      completion(nil)
      return
    }

    let resultUI = UIImage(cgImage: resultCG)
    completion(resultUI.jpegData(compressionQuality: 0.92))
  }

  /// 检测文档边缘(Vision 框架)
  @objc static func detectDocumentRectangle(
    in imageData: Data,
    completion: @escaping ([NSNumber]?) -> Void
  ) {
    guard let cgImage = UIImage(data: imageData)?.cgImage else {
      completion(nil)
      return
    }

    let request = VNDetectRectanglesRequest { request, error in
      guard let observations = request.results as? [VNRectangleObservation],
            let rect = observations.first else {
        completion(nil)
        return
      }

      // Vision 使用归一化坐标(原点左下),转换为图像坐标(原点在左上)
      let w = CGFloat(cgImage.width)
      let h = CGFloat(cgImage.height)

      let result: [NSNumber] = [
        NSNumber(value: Double(rect.topLeft.x * w)),
        NSNumber(value: Double((1 - rect.topLeft.y) * h)),
        NSNumber(value: Double(rect.topRight.x * w)),
        NSNumber(value: Double((1 - rect.topRight.y) * h)),
        NSNumber(value: Double(rect.bottomRight.x * w)),
        NSNumber(value: Double((1 - rect.bottomRight.y) * h)),
        NSNumber(value: Double(rect.bottomLeft.x * w)),
        NSNumber(value: Double((1 - rect.bottomLeft.y) * h))
      ]
      completion(result)
    }

    request.minimumAspectRatio = 0.3
    request.maximumAspectRatio = 1.0
    request.minimumSize = 0.2
    request.minimumConfidence = 0.6
    request.quadratureTolerance = 20
    request.maximumObservations = 1

    let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
    try? handler.perform([request])
  }
}
