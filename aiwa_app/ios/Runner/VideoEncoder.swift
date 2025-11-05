import Foundation
import AVFoundation
import UIKit
import CoreGraphics

class VideoEncoder {
    /**
     * Encode overlay video with keypoints drawn on frames
     */
    static func encodeOverlayVideo(
        frameImages: [[UInt8]],
        keypointsPerFrame: [[[String: Any]]],
        connections: [[String: Any]],
        keypointProperties: [String: Any],
        outputPath: String,
        fps: Int,
        width: Int,
        height: Int
    ) throws -> String {
        print("[VideoEncoder] Starting video encoding: \(frameImages.count) frames, \(fps)fps, \(width)x\(height)")
        
        let outputURL = URL(fileURLWithPath: outputPath)
        
        // Remove existing file if present
        if FileManager.default.fileExists(atPath: outputPath) {
            try? FileManager.default.removeItem(at: outputURL)
        }
        
        // Create parent directory if needed
        let parentDir = outputURL.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: parentDir, withIntermediateDirectories: true)
        
        // Create asset writer
        guard let assetWriter = try? AVAssetWriter(outputURL: outputURL, fileType: .mp4) else {
            throw NSError(domain: "VideoEncoder", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create AVAssetWriter"])
        }
        
        // Configure video settings
        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: width,
            AVVideoHeightKey: height,
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: width * height * fps / 4,
                AVVideoMaxKeyFrameIntervalKey: fps,
                AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel
            ]
        ]
        
        let assetWriterInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        assetWriterInput.expectsMediaDataInRealTime = false
        
        let sourcePixelBufferAttributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB,
            kCVPixelBufferWidthKey as String: width,
            kCVPixelBufferHeightKey as String: height
        ]
        
        let pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: assetWriterInput,
            sourcePixelBufferAttributes: sourcePixelBufferAttributes
        )
        
        guard assetWriter.canAdd(assetWriterInput) else {
            throw NSError(domain: "VideoEncoder", code: -2, userInfo: [NSLocalizedDescriptionKey: "Cannot add input to asset writer"])
        }
        
        assetWriter.add(assetWriterInput)
        
        guard assetWriter.startWriting() else {
            throw NSError(domain: "VideoEncoder", code: -3, userInfo: [NSLocalizedDescriptionKey: "Failed to start writing: \(assetWriter.error?.localizedDescription ?? "unknown")"])
        }
        
        assetWriter.startSession(atSourceTime: .zero)
        
        // Encode frames
        var frameIndex = 0
        let frameDuration = CMTime(value: 1, timescale: CMTimeScale(fps))
        
        for (index, frameData) in frameImages.enumerated() {
            // Wait for asset writer input to be ready
            while !assetWriterInput.isReadyForMoreMediaData {
                Thread.sleep(forTimeInterval: 0.01)
            }
            
            guard let image = UIImage(data: Data(frameData)) else {
                print("[VideoEncoder] Warning: Failed to decode frame \(index)")
                continue
            }
            
            // Draw overlay on image
            let keypoints = keypointsPerFrame[safe: index] ?? []
            guard let overlayImage = drawOverlay(
                on: image,
                keypoints: keypoints,
                connections: connections,
                keypointProperties: keypointProperties
            ) else {
                print("[VideoEncoder] Warning: Failed to draw overlay on frame \(index)")
                continue
            }
            
            // Convert to pixel buffer
            guard let pixelBuffer = pixelBuffer(from: overlayImage, size: CGSize(width: width, height: height)) else {
                print("[VideoEncoder] Warning: Failed to create pixel buffer for frame \(index)")
                continue
            }
            
            // Append pixel buffer
            let presentationTime = CMTimeMultiply(frameDuration, multiplier: Int32(frameIndex))
            if !pixelBufferAdaptor.append(pixelBuffer, withPresentationTime: presentationTime) {
                print("[VideoEncoder] Warning: Failed to append frame \(index)")
                continue
            }
            
            frameIndex += 1
            if frameIndex % 10 == 0 {
                print("[VideoEncoder] Encoded frame \(frameIndex)/\(frameImages.count)")
            }
        }
        
        // Finish writing
        assetWriterInput.markAsFinished()
        
        let semaphore = DispatchSemaphore(value: 0)
        var finalError: Error?
        
        assetWriter.finishWriting {
            if let error = assetWriter.error {
                finalError = error
            }
            semaphore.signal()
        }
        
        semaphore.wait()
        
        if let error = finalError {
            throw error
        }
        
        print("[VideoEncoder] Video encoding completed: \(outputPath)")
        return outputPath
    }
    
    /**
     * Draw keypoints and skeleton connections on image
     */
    private static func drawOverlay(
        on image: UIImage,
        keypoints: [[String: Any]],
        connections: [[String: Any]],
        keypointProperties: [String: Any]
    ) -> UIImage? {
        let size = image.size
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            // Draw original image
            image.draw(in: CGRect(origin: .zero, size: size))
            
            let cgContext = context.cgContext
            let width = size.width
            let height = size.height
            
            // Create keypoint lookup map
            var keypointMap: [String: [String: Any]] = [:]
            for kp in keypoints {
                if let name = kp["name"] as? String {
                    keypointMap[name] = kp
                }
            }
            
            // Extract properties
            let radius = keypointProperties["radius"] as? CGFloat ?? 4.0
            let highConfColor = uiColor(from: keypointProperties["highConfidenceColor"] as? Int ?? 0xFF4CAF50)
            let lowConfColor = uiColor(from: keypointProperties["lowConfidenceColor"] as? Int ?? 0xFF9E9E9E)
            let confThreshold = keypointProperties["confidenceThreshold"] as? Double ?? 0.7
            
            // Draw connections (bones)
            for conn in connections {
                guard let startName = conn["start"] as? String,
                      let endName = conn["end"] as? String,
                      let startKp = keypointMap[startName],
                      let endKp = keypointMap[endName] else {
                    continue
                }
                
                guard let startX = (startKp["x"] as? Double).map({ CGFloat($0) * width }),
                      let startY = (startKp["y"] as? Double).map({ CGFloat($0) * height }),
                      let endX = (endKp["x"] as? Double).map({ CGFloat($0) * width }),
                      let endY = (endKp["y"] as? Double).map({ CGFloat($0) * height }),
                      let startScore = startKp["score"] as? Double,
                      let endScore = endKp["score"] as? Double else {
                    continue
                }
                
                // Only draw if both keypoints have reasonable confidence
                if startScore >= confThreshold && endScore >= confThreshold {
                    let color = uiColor(from: conn["color"] as? Int ?? 0xFFFFFFFF)
                    let strokeWidth = CGFloat(conn["strokeWidth"] as? Double ?? 3.0)
                    
                    cgContext.setStrokeColor(color.cgColor)
                    cgContext.setLineWidth(strokeWidth)
                    cgContext.setLineCap(.round)
                    cgContext.move(to: CGPoint(x: startX, y: startY))
                    cgContext.addLine(to: CGPoint(x: endX, y: endY))
                    cgContext.strokePath()
                }
            }
            
            // Draw keypoints
            for kp in keypoints {
                guard let x = (kp["x"] as? Double).map({ CGFloat($0) * width }),
                      let y = (kp["y"] as? Double).map({ CGFloat($0) * height }),
                      let score = kp["score"] as? Double else {
                    continue
                }
                
                if score >= confThreshold {
                    let color = score >= confThreshold ? highConfColor : lowConfColor
                    cgContext.setFillColor(color.cgColor)
                    cgContext.fillEllipse(in: CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2))
                }
            }
        }
    }
    
    /**
     * Convert UIImage to CVPixelBuffer
     */
    private static func pixelBuffer(from image: UIImage, size: CGSize) -> CVPixelBuffer? {
        let attrs = [
            kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue!,
            kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue!
        ] as CFDictionary
        
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            Int(size.width),
            Int(size.height),
            kCVPixelFormatType_32ARGB,
            attrs,
            &pixelBuffer
        )
        
        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
            return nil
        }
        
        CVPixelBufferLockBaseAddress(buffer, [])
        defer { CVPixelBufferUnlockBaseAddress(buffer, []) }
        
        let pixelData = CVPixelBufferGetBaseAddress(buffer)
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        
        guard let context = CGContext(
            data: pixelData,
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            space: rgbColorSpace,
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
        ) else {
            return nil
        }
        
        context.translateBy(x: 0, y: size.height)
        context.scaleBy(x: 1.0, y: -1.0)
        
        UIGraphicsPushContext(context)
        image.draw(in: CGRect(origin: .zero, size: size))
        UIGraphicsPopContext()
        
        return buffer
    }
    
    /**
     * Convert ARGB integer to UIColor
     */
    private static func uiColor(from argb: Int) -> UIColor {
        let alpha = CGFloat((argb >> 24) & 0xFF) / 255.0
        let red = CGFloat((argb >> 16) & 0xFF) / 255.0
        let green = CGFloat((argb >> 8) & 0xFF) / 255.0
        let blue = CGFloat(argb & 0xFF) / 255.0
        return UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }
    
    /**
     * Get maximum supported video dimensions
     */
    static func getMaxDimensions() -> [String: Int] {
        return [
            "maxWidth": 1920,
            "maxHeight": 1080
        ]
    }
    
    /**
     * Check if video encoding is available
     */
    static func isAvailable() -> Bool {
        return true // AVFoundation is always available on iOS
    }
}

// Safe array subscript extension
extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

