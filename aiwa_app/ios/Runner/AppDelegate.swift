import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var eventSink: FlutterEventSink?
  
  // Thread-safe dictionary to store cancellation flags for each tokenId
  private var cancellationFlags: [String: Bool] = [:]
  private let cancellationQueue = DispatchQueue(label: "com.example.aiwa.cancellation", attributes: .concurrent)
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    let controller = window?.rootViewController as! FlutterViewController
    
    // Register MethodChannel for starting extraction
    let methodChannel = FlutterMethodChannel(name: "com.example.aiwa/video_frames",
                                             binaryMessenger: controller.binaryMessenger)
    
    methodChannel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
      if call.method == "startExtraction" {
        guard let args = call.arguments as? [String: Any],
              let videoPath = args["videoPath"] as? String,
              let targetFps = args["targetFps"] as? Double,
              let maxWidth = args["maxWidth"] as? Int,
              let maxHeight = args["maxHeight"] as? Int else {
          result(FlutterError(code: "INVALID_ARGUMENTS",
                            message: "Missing required arguments",
                            details: nil))
          return
        }
        
        let quality = args["quality"] as? Int ?? 95
        let tokenId = args["tokenId"] as? String ?? ""
        
        // Initialize cancellation flag if tokenId provided
        if !tokenId.isEmpty {
          self?.cancellationQueue.async(flags: .barrier) {
            self?.cancellationFlags[tokenId] = false
          }
        }
        
        // Start extraction asynchronously
        DispatchQueue.global(qos: .userInitiated).async {
          // Create cancellation checker closure
          let isCancelled: () -> Bool = {
            guard !tokenId.isEmpty else { return false }
            var cancelled = false
            self?.cancellationQueue.sync {
              cancelled = self?.cancellationFlags[tokenId] == true
            }
            return cancelled
          }
          
          VideoFrameExtractor.extractFramesWithProgress(
            tokenId: tokenId,
            videoPath: videoPath,
            targetFps: targetFps,
            maxWidth: maxWidth,
            maxHeight: maxHeight,
            quality: quality,
            isCancelled: isCancelled
          ) { processed, total, frameData, error in
            DispatchQueue.main.async {
              if let error = error {
                // Clean up cancellation flag on error
                if !tokenId.isEmpty {
                  self?.cancellationQueue.async(flags: .barrier) {
                    self?.cancellationFlags.removeValue(forKey: tokenId)
                  }
                }
                self?.eventSink?(FlutterError(code: error.code,
                                              message: error.message,
                                              details: error.details))
                result(FlutterError(code: error.code,
                                  message: error.message,
                                  details: error.details))
              } else {
                // Send progress event
                var event: [String: Any] = [
                  "processed": processed,
                  "total": total
                ]
                if let frameData = frameData {
                  event["frameData"] = FlutterStandardTypedData(bytes: frameData)
                }
                self?.eventSink?(event)
                
                // Complete when done
                if processed >= total {
                  // Clean up cancellation flag
                  if !tokenId.isEmpty {
                    self?.cancellationQueue.async(flags: .barrier) {
                      self?.cancellationFlags.removeValue(forKey: tokenId)
                    }
                  }
                  result(nil)
                }
              }
            }
          }
        }
      } else if call.method == "cancelExtraction" {
        guard let args = call.arguments as? [String: Any],
              let tokenId = args["tokenId"] as? String,
              !tokenId.isEmpty else {
          result(FlutterError(code: "INVALID_ARGUMENTS",
                            message: "Missing tokenId",
                            details: nil))
          return
        }
        
        self?.cancellationQueue.async(flags: .barrier) {
          self?.cancellationFlags[tokenId] = true
        }
        result(nil)
      } else if call.method == "extractFrames" {
        // Legacy method for backward compatibility
        guard let args = call.arguments as? [String: Any],
              let videoPath = args["videoPath"] as? String,
              let targetFps = args["targetFps"] as? Double,
              let maxWidth = args["maxWidth"] as? Int,
              let maxHeight = args["maxHeight"] as? Int else {
          result(FlutterError(code: "INVALID_ARGUMENTS",
                            message: "Missing required arguments",
                            details: nil))
          return
        }
        
        let quality = args["quality"] as? Int ?? 95
        
        VideoFrameExtractor.extractFrames(
          videoPath: videoPath,
          targetFps: targetFps,
          maxWidth: maxWidth,
          maxHeight: maxHeight,
          quality: quality
        ) { frames, error in
          if let error = error {
            result(FlutterError(code: error.code,
                              message: error.message,
                              details: error.details))
          } else {
            result(frames)
          }
        }
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
    
    // Register EventChannel for progress stream
    let eventChannel = FlutterEventChannel(name: "com.example.aiwa/video_frames_events",
                                          binaryMessenger: controller.binaryMessenger)
    eventChannel.setStreamHandler(self)
    
    // Register MethodChannel for video encoding
    let encoderChannel = FlutterMethodChannel(name: "com.example.aiwa/video_encoder",
                                              binaryMessenger: controller.binaryMessenger)
    
    encoderChannel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
      if call.method == "encodeOverlayVideo" {
        guard let args = call.arguments as? [String: Any],
              let frameImages = args["frameImages"] as? [FlutterStandardTypedData],
              let keypointsPerFrame = args["keypointsPerFrame"] as? [[[String: Any]]],
              let connections = args["connections"] as? [[String: Any]],
              let keypointProperties = args["keypointProperties"] as? [String: Any],
              let outputPath = args["outputPath"] as? String,
              let fps = args["fps"] as? Int,
              let width = args["width"] as? Int,
              let height = args["height"] as? Int else {
          result(FlutterError(code: "INVALID_ARGUMENTS",
                            message: "Missing required arguments",
                            details: nil))
          return
        }
        
        // Convert FlutterStandardTypedData to [UInt8]
        let frameData = frameImages.map { Array($0.data) }
        
        // Encode video asynchronously
        DispatchQueue.global(qos: .userInitiated).async {
          do {
            let videoPath = try VideoEncoder.encodeOverlayVideo(
              frameImages: frameData,
              keypointsPerFrame: keypointsPerFrame,
              connections: connections,
              keypointProperties: keypointProperties,
              outputPath: outputPath,
              fps: fps,
              width: width,
              height: height
            )
            DispatchQueue.main.async {
              result(videoPath)
            }
          } catch {
            DispatchQueue.main.async {
              result(FlutterError(code: "ENCODING_FAILED",
                                message: "Video encoding failed: \(error.localizedDescription)",
                                details: nil))
            }
          }
        }
      } else if call.method == "isAvailable" {
        result(VideoEncoder.isAvailable())
      } else if call.method == "getMaxDimensions" {
        result(VideoEncoder.getMaxDimensions())
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

extension AppDelegate: FlutterStreamHandler {
  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    self.eventSink = events
    return nil
  }
  
  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    self.eventSink = nil
    return nil
  }
}
