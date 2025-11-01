import Foundation
import AVFoundation
import UIKit

/// Custom error type for video frame extraction
struct VideoFrameExtractionError {
    let code: String
    let message: String
    let details: String?
}

/// Video frame extractor using AVFoundation
class VideoFrameExtractor {
    /**
     * Extract frames with progress callback (streaming mode)
     *
     * - Parameters:
     *   - tokenId: Cancellation token ID (empty string if not provided)
     *   - videoPath: Absolute path to the video file
     *   - targetFps: Desired frames per second for extraction
     *   - maxWidth: Maximum width for extracted frames (scaled if larger)
     *   - maxHeight: Maximum height for extracted frames (scaled if larger)
     *   - quality: JPEG quality (0-100)
     *   - isCancelled: Closure that returns true if extraction should be cancelled
     *   - progress: Callback(processed, total, frameData, error) - frameData is nil for progress-only updates
     */
    static func extractFramesWithProgress(
        tokenId: String = "",
        videoPath: String,
        targetFps: Double,
        maxWidth: Int,
        maxHeight: Int,
        quality: Int,
        isCancelled: @escaping () -> Bool = { false },
        progress: @escaping (Int, Int, Data?, VideoFrameExtractionError?) -> Void
    ) {
        // Validate file exists
        let fileURL = URL(fileURLWithPath: videoPath)
        guard FileManager.default.fileExists(atPath: videoPath) else {
            progress(0, 0, nil, VideoFrameExtractionError(
                code: "FILE_NOT_FOUND",
                message: "Video file not found: \(videoPath)",
                details: nil
            ))
            return
        }
        
        print("VideoFrameExtractor: Starting extraction: \(videoPath)")
        
        // Create AVAsset from file URL
        let asset = AVAsset(url: fileURL)
        
        // Get video duration
        let duration = asset.duration
        let durationSeconds = CMTimeGetSeconds(duration)
        
        guard durationSeconds.isFinite && durationSeconds > 0 else {
            progress(0, 0, nil, VideoFrameExtractionError(
                code: "INVALID_VIDEO",
                message: "Cannot get video duration",
                details: nil
            ))
            return
        }
        
        // Create image generator
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.requestedTimeToleranceBefore = .zero
        imageGenerator.requestedTimeToleranceAfter = .zero
        imageGenerator.maximumSize = CGSize(width: maxWidth, height: maxHeight)
        
        // Calculate frame timestamps
        let frameInterval = 1.0 / targetFps
        let totalFrames = Int(durationSeconds / frameInterval)
        var times: [CMTime] = []
        
        for i in 0..<totalFrames {
            let timeSeconds = Double(i) * frameInterval
            let time = CMTime(seconds: timeSeconds, preferredTimescale: 600)
            times.append(time)
        }
        
        print("VideoFrameExtractor: Video: \(durationSeconds)s, Target FPS: \(targetFps), Total frames: \(totalFrames)")
        
        // Extract frames one by one with progress updates
        var frameIndex = 0
        
        func extractNextFrame() {
            // Check for cancellation before processing
            if isCancelled() {
                print("VideoFrameExtractor: Extraction cancelled at frame \(frameIndex)/\(totalFrames)")
                return
            }
            
            guard frameIndex < times.count else {
                print("VideoFrameExtractor: Extraction complete: \(totalFrames) frames")
                return
            }
            
            let time = times[frameIndex]
            let currentIndex = frameIndex
            
            // Log every 50 frames
            if frameIndex % 50 == 0 {
                print("VideoFrameExtractor: Progress: \(frameIndex)/\(totalFrames) frames")
            }
            
            do {
                let cgImage = try imageGenerator.copyCGImage(at: time, actualTime: nil)
                
                // Convert CGImage to JPEG Data
                if let jpegData = convertToJPEG(cgImage: cgImage, quality: quality) {
                    progress(currentIndex + 1, totalFrames, jpegData, nil)
                } else {
                    progress(currentIndex + 1, totalFrames, nil, nil)
                }
                
                frameIndex += 1
                
                // Check cancellation before continuing
                guard !isCancelled() else {
                    print("VideoFrameExtractor: Extraction cancelled after frame \(frameIndex)/\(totalFrames)")
                    return
                }
                
                // Continue with next frame (with small delay to avoid blocking)
                DispatchQueue.global(qos: .userInitiated).async {
                    extractNextFrame()
                }
                
            } catch {
                print("VideoFrameExtractor: Frame extraction error at \(frameIndex): \(error.localizedDescription)")
                progress(currentIndex + 1, totalFrames, nil, nil)
                frameIndex += 1
                
                // Check cancellation before continuing even on error
                guard !isCancelled() else {
                    print("VideoFrameExtractor: Extraction cancelled after error at frame \(frameIndex)/\(totalFrames)")
                    return
                }
                
                // Continue with next frame even on error
                DispatchQueue.global(qos: .userInitiated).async {
                    extractNextFrame()
                }
            }
        }
        
        // Start extraction
        extractNextFrame()
    }
    
    /**
     * Extract frames from a video file using AVFoundation (legacy method)
     *
     * - Parameters:
     *   - videoPath: Absolute path to the video file
     *   - targetFps: Desired frames per second for extraction
     *   - maxWidth: Maximum width for extracted frames (scaled if larger)
     *   - maxHeight: Maximum height for extracted frames (scaled if larger)
     *   - quality: JPEG quality (0-100)
     *   - completion: Callback with frames array or error
     */
    static func extractFrames(
        videoPath: String,
        targetFps: Double,
        maxWidth: Int,
        maxHeight: Int,
        quality: Int,
        completion: @escaping ([FlutterStandardTypedData]?, VideoFrameExtractionError?) -> Void
    ) {
        var frames: [FlutterStandardTypedData] = []
        
        extractFramesWithProgress(
            videoPath: videoPath,
            targetFps: targetFps,
            maxWidth: maxWidth,
            maxHeight: maxHeight,
            quality: quality
        ) { processed, total, frameData, error in
            if let error = error {
                completion(nil, error)
            } else if let frameData = frameData {
                frames.append(FlutterStandardTypedData(bytes: frameData))
            }
            
            // Complete when done
            if processed >= total {
                completion(frames, nil)
            }
        }
    }
    
    /**
     * Extract frames from a video file using AVFoundation (old async implementation, kept for reference)
     */
    private static func extractFramesOld(
        videoPath: String,
        targetFps: Double,
        maxWidth: Int,
        maxHeight: Int,
        quality: Int,
        completion: @escaping ([FlutterStandardTypedData]?, VideoFrameExtractionError?) -> Void
    ) {
        // Validate file exists
        let fileURL = URL(fileURLWithPath: videoPath)
        guard FileManager.default.fileExists(atPath: videoPath) else {
            completion(nil, VideoFrameExtractionError(
                code: "FILE_NOT_FOUND",
                message: "Video file not found: \(videoPath)",
                details: nil
            ))
            return
        }
        
        // Create AVAsset from file URL
        let asset = AVAsset(url: fileURL)
        
        // Get video duration
        let duration = asset.duration
        let durationSeconds = CMTimeGetSeconds(duration)
        
        guard durationSeconds.isFinite && durationSeconds > 0 else {
            completion(nil, VideoFrameExtractionError(
                code: "INVALID_VIDEO",
                message: "Cannot get video duration",
                details: nil
            ))
            return
        }
        
        // Create image generator
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.requestedTimeToleranceBefore = .zero
        imageGenerator.requestedTimeToleranceAfter = .zero
        imageGenerator.maximumSize = CGSize(width: maxWidth, height: maxHeight)
        
        // Calculate frame timestamps
        let frameInterval = 1.0 / targetFps
        let totalFrames = Int(durationSeconds / frameInterval)
        var times: [NSValue] = []
        
        for i in 0..<totalFrames {
            let timeSeconds = Double(i) * frameInterval
            let time = CMTime(seconds: timeSeconds, preferredTimescale: 600)
            times.append(NSValue(time: time))
        }
        
        // Extract frames asynchronously
        var extractedFrames: [FlutterStandardTypedData] = []
        let queue = DispatchQueue(label: "com.example.aiwa.frameExtraction", qos: .userInitiated)
        
        queue.async {
            var hasError = false
            let semaphore = DispatchSemaphore(value: 0)
            
            imageGenerator.generateCGImagesAsynchronously(forTimes: times) { _, cgImage, _, result, error in
                defer { semaphore.signal() }
                
                if let error = error {
                    print("Frame extraction error: \(error.localizedDescription)")
                    return
                }
                
                if result == .succeeded, let cgImage = cgImage {
                    // Convert CGImage to JPEG Data
                    if let jpegData = self.convertToJPEG(cgImage: cgImage, quality: quality) {
                        let flutterData = FlutterStandardTypedData(bytes: jpegData)
                        extractedFrames.append(flutterData)
                    }
                } else if result == .failed {
                    hasError = true
                }
            }
            
            // Wait for all frames to complete
            for _ in 0..<times.count {
                semaphore.wait()
            }
            
            // Return results on main thread
            DispatchQueue.main.async {
                if hasError && extractedFrames.isEmpty {
                    completion(nil, VideoFrameExtractionError(
                        code: "EXTRACTION_FAILED",
                        message: "Failed to extract any frames from video",
                        details: nil
                    ))
                } else {
                    completion(extractedFrames, nil)
                }
            }
        }
    }
    
    /**
     * Convert CGImage to JPEG Data
     *
     * - Parameters:
     *   - cgImage: Source CGImage
     *   - quality: JPEG quality (0-100)
     * - Returns: JPEG data or nil if conversion fails
     */
    private static func convertToJPEG(cgImage: CGImage, quality: Int) -> Data? {
        let uiImage = UIImage(cgImage: cgImage)
        let compressionQuality = CGFloat(quality) / 100.0
        return uiImage.jpegData(compressionQuality: compressionQuality)
    }
}

