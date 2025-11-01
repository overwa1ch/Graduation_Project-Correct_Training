package com.example.aiwa_milestone_a

import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.ConcurrentHashMap

class MainActivity : FlutterActivity() {
    private val METHOD_CHANNEL = "com.example.aiwa/video_frames"
    private val EVENT_CHANNEL = "com.example.aiwa/video_frames_events"
    private val VIDEO_ENCODER_CHANNEL = "com.example.aiwa/video_encoder"
    
    private var eventSink: EventChannel.EventSink? = null
    private val mainHandler = Handler(Looper.getMainLooper())
    
    // Thread-safe map to store cancellation flags for each tokenId
    private val cancellationFlags = ConcurrentHashMap<String, Boolean>()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // MethodChannel for starting extraction
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startExtraction" -> {
                        val videoPath = call.argument<String>("videoPath")
                        val targetFps = call.argument<Double>("targetFps")
                        val maxWidth = call.argument<Int>("maxWidth")
                        val maxHeight = call.argument<Int>("maxHeight")
                        val quality = call.argument<Int>("quality") ?: 95
                        val tokenId = call.argument<String>("tokenId")

                        if (videoPath == null || targetFps == null || maxWidth == null || maxHeight == null) {
                            result.error("INVALID_ARGUMENTS", "Missing required arguments", null)
                            return@setMethodCallHandler
                        }

                        // Initialize cancellation flag if tokenId provided
                        val actualTokenId = tokenId ?: ""
                        if (actualTokenId.isNotEmpty()) {
                            cancellationFlags[actualTokenId] = false
                        }

                        // Start extraction in background thread
                        Thread {
                            try {
                                // Create cancellation checker lambda
                                val isCancelled: () -> Boolean = {
                                    actualTokenId.isNotEmpty() && (cancellationFlags[actualTokenId] == true)
                                }

                                VideoFrameExtractor.extractFramesWithProgress(
                                    context = applicationContext,
                                    tokenId = actualTokenId,
                                    videoPath = videoPath,
                                    targetFps = targetFps,
                                    maxWidth = maxWidth,
                                    maxHeight = maxHeight,
                                    quality = quality,
                                    isCancelled = isCancelled,
                                    onProgress = { processed, total, frameData ->
                                        // Send progress event on main thread
                                        mainHandler.post {
                                            eventSink?.let { sink ->
                                                val event = mutableMapOf<String, Any>(
                                                    "processed" to processed,
                                                    "total" to total
                                                )
                                                if (frameData != null) {
                                                    event["frameData"] = frameData
                                                }
                                                sink.success(event)
                                            }
                                        }
                                    }
                                )
                                
                                // Signal completion on main thread
                                mainHandler.post {
                                    // Clean up cancellation flag
                                    if (actualTokenId.isNotEmpty()) {
                                        cancellationFlags.remove(actualTokenId)
                                    }
                                    result.success(null)
                                }
                            } catch (e: Exception) {
                                // Send error event on main thread
                                mainHandler.post {
                                    // Clean up cancellation flag on error
                                    if (actualTokenId.isNotEmpty()) {
                                        cancellationFlags.remove(actualTokenId)
                                    }
                                    eventSink?.error(
                                        e::class.java.simpleName,
                                        e.message ?: "Unknown error",
                                        e.stackTraceToString()
                                    )
                                    
                                    result.error(
                                        e::class.java.simpleName,
                                        e.message ?: "Unknown error",
                                        e.stackTraceToString()
                                    )
                                }
                            }
                        }.start()
                    }
                    "cancelExtraction" -> {
                        val tokenId = call.argument<String>("tokenId")
                        if (tokenId != null && tokenId.isNotEmpty()) {
                            cancellationFlags[tokenId] = true
                            result.success(null)
                        } else {
                            result.error("INVALID_ARGUMENTS", "Missing tokenId", null)
                        }
                    }
                    // Keep old method for backward compatibility
                    "extractFrames" -> {
                        val videoPath = call.argument<String>("videoPath")
                        val targetFps = call.argument<Double>("targetFps")
                        val maxWidth = call.argument<Int>("maxWidth")
                        val maxHeight = call.argument<Int>("maxHeight")
                        val quality = call.argument<Int>("quality") ?: 95

                        if (videoPath == null || targetFps == null || maxWidth == null || maxHeight == null) {
                            result.error("INVALID_ARGUMENTS", "Missing required arguments", null)
                            return@setMethodCallHandler
                        }

                        try {
                            val frames = VideoFrameExtractor.extractFrames(
                                context = applicationContext,
                                videoPath = videoPath,
                                targetFps = targetFps,
                                maxWidth = maxWidth,
                                maxHeight = maxHeight,
                                quality = quality
                            )
                            result.success(frames)
                        } catch (e: Exception) {
                            result.error(
                                e::class.java.simpleName,
                                e.message ?: "Unknown error",
                                e.stackTraceToString()
                            )
                        }
                    }
                    else -> result.notImplemented()
                }
            }
        
        // EventChannel for progress stream
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            })
        
        // MethodChannel for video encoding
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, VIDEO_ENCODER_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "encodeOverlayVideo" -> {
                        val frameImages = call.argument<List<ByteArray>>("frameImages")
                        val keypointsPerFrame = call.argument<List<List<Map<String, Any>>>>("keypointsPerFrame")
                        val connections = call.argument<List<Map<String, Any>>>("connections")
                        val keypointProperties = call.argument<Map<String, Any>>("keypointProperties")
                        val outputPath = call.argument<String>("outputPath")
                        val fps = call.argument<Int>("fps")
                        val width = call.argument<Int>("width")
                        val height = call.argument<Int>("height")

                        if (frameImages == null || keypointsPerFrame == null || connections == null || 
                            keypointProperties == null || outputPath == null || fps == null || 
                            width == null || height == null) {
                            result.error("INVALID_ARGUMENTS", "Missing required arguments", null)
                            return@setMethodCallHandler
                        }

                        // Encode video in background thread
                        Thread {
                            try {
                                val videoPath = VideoEncoder.encodeOverlayVideo(
                                    frameImages = frameImages,
                                    keypointsPerFrame = keypointsPerFrame,
                                    connections = connections,
                                    keypointProperties = keypointProperties,
                                    outputPath = outputPath,
                                    fps = fps,
                                    width = width,
                                    height = height
                                )
                                mainHandler.post {
                                    result.success(videoPath)
                                }
                            } catch (e: Exception) {
                                mainHandler.post {
                                    result.error(
                                        e::class.java.simpleName,
                                        e.message ?: "Video encoding failed",
                                        e.stackTraceToString()
                                    )
                                }
                            }
                        }.start()
                    }
                    "isAvailable" -> {
                        result.success(VideoEncoder.isAvailable())
                    }
                    "getMaxDimensions" -> {
                        result.success(VideoEncoder.getMaxDimensions())
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
