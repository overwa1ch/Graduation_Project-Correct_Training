package com.example.aiwa_milestone_a

import android.graphics.*
import android.media.MediaCodec
import android.media.MediaCodecInfo
import android.media.MediaFormat
import android.media.MediaMuxer
import android.util.Log
import java.io.File

/**
 * Video encoder using Surface input mode.
 * This avoids manual YUV conversion and stride handling by letting the system
 * handle format conversion through OpenGL ES.
 */
object VideoEncoder {
    private const val TAG = "VideoEncoder"
    private const val MIME_TYPE = "video/avc" // H.264
    private const val IFRAME_INTERVAL = 1 // I-frame interval in seconds
    private const val BIT_RATE_MULTIPLIER = 0.25 // bits per pixel
    private const val TIMEOUT_US = 10000L
    
    // Debug flag
    private var drawOverlayLogged = false

    /**
     * Encode overlay video with keypoints drawn on frames using Surface input mode
     * 
     * @param frameImages List of JPEG frame images as byte arrays
     * @param keypointsPerFrame List of keypoints for each frame
     * @param connections Skeleton connection definitions
     * @param keypointProperties Visual properties for keypoints
     * @param outputPath Output video file path
     * @param fps Frames per second
     * @param width Video width
     * @param height Video height
     * @return Absolute path to the created video file
     */
    fun encodeOverlayVideo(
        frameImages: List<ByteArray>,
        keypointsPerFrame: List<List<Map<String, Any>>>,
        connections: List<Map<String, Any>>,
        keypointProperties: Map<String, Any>,
        outputPath: String,
        fps: Int,
        width: Int,
        height: Int
    ): String {
        Log.d(TAG, "═══════════════════════════════════════════════════")
        Log.d(TAG, "🎬 Starting Surface-based video encoding")
        Log.d(TAG, "   Frames: ${frameImages.size}, FPS: $fps, Size: ${width}x${height}")
        Log.d(TAG, "═══════════════════════════════════════════════════")
        
        // Check keypoints data
        Log.d(TAG, "📊 Input data check:")
        Log.d(TAG, "   frameImages: ${frameImages.size} frames")
        Log.d(TAG, "   keypointsPerFrame: ${keypointsPerFrame.size} frames")
        Log.d(TAG, "   connections: ${connections.size} connections")
        
        // Verify sizes match
        if (frameImages.size != keypointsPerFrame.size) {
            Log.w(TAG, "⚠️ WARNING: frameImages.size (${frameImages.size}) != keypointsPerFrame.size (${keypointsPerFrame.size})")
            Log.w(TAG, "   Frames without keypoints will not have skeleton overlay")
        } else {
            Log.d(TAG, "✅ Frame count matches keypoints count")
        }
        
        // Log keypoint properties
        val confThreshold = (keypointProperties["confidenceThreshold"] as? Double) ?: 0.7
        Log.d(TAG, "   confidenceThreshold: $confThreshold")
        Log.d(TAG, "   ⚠️ DEBUG: Temporarily using threshold = 0.0 to test skeleton visibility")
        
        val outputFile = File(outputPath)
        if (outputFile.exists()) {
            outputFile.delete()
        }
        outputFile.parentFile?.mkdirs()

        var mediaCodec: MediaCodec? = null
        var mediaMuxer: MediaMuxer? = null
        var inputSurface: InputSurface? = null
        var textureRenderer: TextureRenderer? = null
        var trackIndex = -1
        var muxerStarted = false

        try {
            // Create MediaCodec encoder with Surface input
            mediaCodec = MediaCodec.createEncoderByType(MIME_TYPE)
            val format = MediaFormat.createVideoFormat(MIME_TYPE, width, height).apply {
                setInteger(MediaFormat.KEY_COLOR_FORMAT, MediaCodecInfo.CodecCapabilities.COLOR_FormatSurface)
                setInteger(MediaFormat.KEY_BIT_RATE, (width * height * BIT_RATE_MULTIPLIER * fps).toInt())
                setInteger(MediaFormat.KEY_FRAME_RATE, fps)
                setInteger(MediaFormat.KEY_I_FRAME_INTERVAL, IFRAME_INTERVAL)
            }
            
            Log.d(TAG, "🔧 Configuring MediaCodec with Surface input")
            mediaCodec.configure(format, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE)
            
            // Create input surface from MediaCodec
            val surface = mediaCodec.createInputSurface()
            Log.d(TAG, "✅ Input Surface created")
            
            // Start the encoder
            mediaCodec.start()
            Log.d(TAG, "✅ MediaCodec started")
            
            // Log encoder info
            try {
                val codecInfo = mediaCodec.codecInfo
                Log.d(TAG, "📋 Encoder Info:")
                Log.d(TAG, "   Name: ${codecInfo.name}")
                Log.d(TAG, "   Is Hardware Accelerated: ${codecInfo.isHardwareAccelerated}")
            } catch (e: Exception) {
                Log.w(TAG, "⚠️ Failed to get codec info: ${e.message}")
            }
            
            // Create EGL/OpenGL context
            inputSurface = InputSurface(surface)
            inputSurface.makeCurrent()
            Log.d(TAG, "✅ EGL context created and made current")
            
            // Initialize texture renderer
            textureRenderer = TextureRenderer()
            textureRenderer.surfaceCreated()
            Log.d(TAG, "✅ TextureRenderer initialized")
            
            // Create MediaMuxer
            mediaMuxer = MediaMuxer(outputPath, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)
            Log.d(TAG, "✅ MediaMuxer created")

            val bufferInfo = MediaCodec.BufferInfo()
            var frameIndex = 0
            var inputDone = false
            var outputDone = false
            var outputFrameCount = 0
            
            Log.d(TAG, "═══════════════════════════════════════════════════")
            Log.d(TAG, "🎥 Starting frame encoding loop")
            Log.d(TAG, "═══════════════════════════════════════════════════")
            
            while (!outputDone) {
                // Feed input frames
                if (!inputDone && frameIndex < frameImages.size) {
                    try {
                        // Decode JPEG to Bitmap
                        val bitmap = BitmapFactory.decodeByteArray(
                            frameImages[frameIndex],
                            0,
                            frameImages[frameIndex].size
                        )
                        
                        if (bitmap != null) {
                            // Save original dimensions before potential recycle
                            val originalWidth = bitmap.width
                            val originalHeight = bitmap.height
                            
                            // Scale bitmap if needed
                            val bitmapForOverlay = if (originalWidth != width || originalHeight != height) {
                                val scaled = Bitmap.createScaledBitmap(bitmap, width, height, true)
                                bitmap.recycle()
                                scaled
                            } else {
                                bitmap
                            }
                            
                            // Draw skeleton overlay
                            val overlayBitmap = if (frameIndex < keypointsPerFrame.size) {
                                val frameKeypoints = keypointsPerFrame[frameIndex]
                                
                                // Debug: Log first few frames with coordinate info
                                if (frameIndex < 3) {
                                    Log.d(TAG, "🔍 Frame $frameIndex coordinate debug:")
                                    Log.d(TAG, "   Original bitmap: ${originalWidth}x${originalHeight}")
                                    Log.d(TAG, "   Scaled bitmap: ${bitmapForOverlay.width}x${bitmapForOverlay.height}")
                                    Log.d(TAG, "   Target video size: ${width}x${height}")
                                    Log.d(TAG, "   Keypoints: ${frameKeypoints.size}")
                                    if (frameKeypoints.isNotEmpty()) {
                                        // Log first 5 keypoints to check y values
                                        Log.d(TAG, "   First 5 keypoints:")
                                        for (i in 0 until minOf(5, frameKeypoints.size)) {
                                            val kp = frameKeypoints[i]
                                            val kpX = (kp["x"] as? Double) ?: 0.0
                                            val kpY = (kp["y"] as? Double) ?: 0.0
                                            val kpScore = (kp["score"] as? Double) ?: (kp["confidence"] as? Double) ?: 0.0
                                            Log.d(TAG, "      [$i] ${kp["name"]}: x=$kpX, y=$kpY, score=$kpScore")
                                        }
                                        
                                        val sampleKp = frameKeypoints[0]
                                        val normX = (sampleKp["x"] as? Double) ?: 0.0
                                        val normY = (sampleKp["y"] as? Double) ?: 0.0
                                        val pixelX = normX * bitmapForOverlay.width
                                        val pixelY = normY * bitmapForOverlay.height
                                        Log.d(TAG, "   Sample keypoint (first): name=${sampleKp["name"]}")
                                        Log.d(TAG, "      Normalized: x=$normX, y=$normY")
                                        Log.d(TAG, "      Pixel (on scaled bitmap): x=$pixelX, y=$pixelY")
                                        // Support both "score" and "confidence"
                                        val confValue = sampleKp["score"] ?: sampleKp["confidence"]
                                        Log.d(TAG, "      Confidence/Score: $confValue")
                                        
                                        // Check if scaling was needed
                                        if (originalWidth != bitmapForOverlay.width || originalHeight != bitmapForOverlay.height) {
                                            Log.w(TAG, "   ⚠️ Bitmap was scaled from ${originalWidth}x${originalHeight} to ${bitmapForOverlay.width}x${bitmapForOverlay.height}")
                                        }
                                    }
                                }
                                
                                val overlay = drawOverlay(
                                    bitmapForOverlay,
                                    frameKeypoints,
                                    connections,
                                    keypointProperties
                                )
                                
                                if (frameIndex < 3) {
                                    Log.d(TAG, "   ✅ Overlay drawn")
                                }
                                
                                overlay
                            } else {
                                if (frameIndex == keypointsPerFrame.size) {
                                    Log.w(TAG, "⚠️ Frame $frameIndex and beyond: No keypoints data")
                                }
                                bitmapForOverlay
                            }
                            
                            // Render to Surface using OpenGL
                            textureRenderer.drawBitmap(overlayBitmap, width, height)
                            
                            // Set presentation time
                            val presentationTimeNs = frameIndex * 1_000_000_000L / fps
                            inputSurface.setPresentationTime(presentationTimeNs)
                            
                            // Submit frame to encoder
                            inputSurface.swapBuffers()
                            
                            // Cleanup bitmaps
                            overlayBitmap.recycle()
                            if (overlayBitmap != bitmapForOverlay) {
                                bitmapForOverlay.recycle()
                            }
                            
                            frameIndex++
                            
                            // Log progress every 20 frames
                            if (frameIndex % 20 == 0 || frameIndex == frameImages.size) {
                                Log.d(TAG, "📥 Submitted frame $frameIndex/${frameImages.size}")
                            }
                        } else {
                            Log.w(TAG, "⚠️ Failed to decode frame $frameIndex")
                            frameIndex++
                        }
                    } catch (e: Exception) {
                        Log.e(TAG, "❌ Error processing frame $frameIndex: ${e.message}", e)
                        frameIndex++
                    }
                }
                
                // Signal end of input stream
                if (!inputDone && frameIndex >= frameImages.size) {
                    mediaCodec.signalEndOfInputStream()
                    inputDone = true
                    Log.d(TAG, "✅ End of input stream signaled ($frameIndex frames submitted)")
                }
                
                // Process output buffers
                val outputBufferIndex = mediaCodec.dequeueOutputBuffer(bufferInfo, TIMEOUT_US)
                when {
                    outputBufferIndex == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED -> {
                        if (muxerStarted) {
                            throw IllegalStateException("Output format changed after muxer started")
                        }
                        val newFormat = mediaCodec.outputFormat
                        trackIndex = mediaMuxer.addTrack(newFormat)
                        mediaMuxer.start()
                        muxerStarted = true
                        Log.d(TAG, "✅ MediaMuxer started")
                    }
                    outputBufferIndex == MediaCodec.INFO_TRY_AGAIN_LATER -> {
                        // No output available, continue
                    }
                    outputBufferIndex >= 0 -> {
                        val outputBuffer = mediaCodec.getOutputBuffer(outputBufferIndex)
                        if (outputBuffer != null && bufferInfo.size > 0) {
                            if (muxerStarted) {
                                outputBuffer.position(bufferInfo.offset)
                                outputBuffer.limit(bufferInfo.offset + bufferInfo.size)
                                mediaMuxer.writeSampleData(trackIndex, outputBuffer, bufferInfo)
                                outputFrameCount++
                                
                                // Log progress
                                if (outputFrameCount == 1 || outputFrameCount % 20 == 0 ||
                                    (bufferInfo.flags and MediaCodec.BUFFER_FLAG_KEY_FRAME) != 0) {
                                    val keyFlag = if ((bufferInfo.flags and MediaCodec.BUFFER_FLAG_KEY_FRAME) != 0) " [KEY]" else ""
                                    Log.d(TAG, "📤 Output frame #$outputFrameCount: ${bufferInfo.size}b$keyFlag")
                                }
                            } else {
                                Log.w(TAG, "⚠️ Output buffer available but MediaMuxer not started! Dropping frame")
                            }
                        }
                        
                        mediaCodec.releaseOutputBuffer(outputBufferIndex, false)
                        
                        if ((bufferInfo.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM) != 0) {
                            outputDone = true
                            Log.d(TAG, "✅ Output stream ended (total output frames: $outputFrameCount)")
                        }
                    }
                }
            }
            
            Log.d(TAG, "═══════════════════════════════════════════════════")
            Log.d(TAG, "✅ Encoding complete")
            Log.d(TAG, "   Input frames: $frameIndex")
            Log.d(TAG, "   Output frames: $outputFrameCount")
            
            if (outputFile.exists()) {
                val fileSize = outputFile.length()
                Log.d(TAG, "   File size: ${fileSize / 1024} KB")
            }
            Log.d(TAG, "═══════════════════════════════════════════════════")
            
            return outputPath

        } catch (e: Exception) {
            Log.e(TAG, "❌ Video encoding failed", e)
            throw RuntimeException("Video encoding failed: ${e.message}", e)
        } finally {
            // Cleanup resources in reverse order
            try {
                textureRenderer?.release()
                inputSurface?.release()
                mediaCodec?.stop()
                mediaCodec?.release()
                if (muxerStarted) {
                    mediaMuxer?.stop()
                }
                mediaMuxer?.release()
                Log.d(TAG, "✅ All resources released")
            } catch (e: Exception) {
                Log.e(TAG, "❌ Error releasing resources", e)
            }
        }
    }

    /**
     * Draw keypoints and skeleton connections on bitmap
     */
    private fun drawOverlay(
        originalBitmap: Bitmap,
        keypoints: List<Map<String, Any>>,
        connections: List<Map<String, Any>>,
        keypointProperties: Map<String, Any>
    ): Bitmap {
        val bitmap = originalBitmap.copy(Bitmap.Config.ARGB_8888, true)
        val canvas = Canvas(bitmap)
        val width = bitmap.width.toFloat()
        val height = bitmap.height.toFloat()
        
        // Debug: Log overlay drawing dimensions (only once)
        if (!drawOverlayLogged) {
            Log.d(TAG, "🎨 drawOverlay() called with bitmap: ${bitmap.width}x${bitmap.height}")
        }

        // Create keypoint lookup map
        val keypointMap = keypoints.associateBy { it["name"] as String }
        
        // Debug counters
        var connectionsDrawn = 0
        var keypointsDrawn = 0

        // Extract properties
        val radius = (keypointProperties["radius"] as? Double)?.toFloat() ?: 4f
        val highConfColor = (keypointProperties["highConfidenceColor"] as? Int) ?: Color.GREEN
        val lowConfColor = (keypointProperties["lowConfidenceColor"] as? Int) ?: Color.GRAY
        // Restore normal threshold (was temporarily 0.0 for debugging)
        val confThreshold = (keypointProperties["confidenceThreshold"] as? Double) ?: 0.7

        // Draw connections (bones)
        val linePaint = Paint().apply {
            strokeWidth = 3f
            style = Paint.Style.STROKE
            isAntiAlias = true
        }

        for (connection in connections) {
            val startName = connection["start"] as? String ?: continue
            val endName = connection["end"] as? String ?: continue
            val color = (connection["color"] as? Int) ?: Color.WHITE

            val startKp = keypointMap[startName]
            val endKp = keypointMap[endName]

            if (startKp != null && endKp != null) {
                val startX = ((startKp["x"] as? Double) ?: 0.0).toFloat() * width
                val startY = ((startKp["y"] as? Double) ?: 0.0).toFloat() * height
                val endX = ((endKp["x"] as? Double) ?: 0.0).toFloat() * width
                val endY = ((endKp["y"] as? Double) ?: 0.0).toFloat() * height
                // Support both "score" and "confidence" field names
                val startConf = (startKp["score"] as? Double) ?: (startKp["confidence"] as? Double) ?: 0.0
                val endConf = (endKp["score"] as? Double) ?: (endKp["confidence"] as? Double) ?: 0.0

                // Only draw if both keypoints have sufficient confidence
                if (startConf >= confThreshold && endConf >= confThreshold) {
                    linePaint.color = color
                    canvas.drawLine(startX, startY, endX, endY, linePaint)
                    connectionsDrawn++
                    
                    // Debug: Log first connection's coordinates
                    if (connectionsDrawn == 1 && !drawOverlayLogged) {
                        Log.d(TAG, "   First connection drawn: ($startX, $startY) -> ($endX, $endY)")
                    }
                }
            }
        }

        // Draw keypoints (circles)
        val circlePaint = Paint().apply {
            style = Paint.Style.FILL
            isAntiAlias = true
        }

        for (keypoint in keypoints) {
            val normalizedX = (keypoint["x"] as? Double) ?: 0.0
            val normalizedY = (keypoint["y"] as? Double) ?: 0.0
            val x = normalizedX.toFloat() * width
            val y = normalizedY.toFloat() * height
            // Support both "score" and "confidence" field names
            val confidence = (keypoint["score"] as? Double) ?: (keypoint["confidence"] as? Double) ?: 0.0

            if (confidence >= confThreshold) {
                circlePaint.color = highConfColor
                canvas.drawCircle(x, y, radius, circlePaint)
                keypointsDrawn++
                
                // Debug: Log first keypoint's actual drawing coordinates
                if (keypointsDrawn == 1 && !drawOverlayLogged) {
                    Log.d(TAG, "   First keypoint drawn: name=${keypoint["name"]}, " +
                            "normalized=($normalizedX, $normalizedY), " +
                            "pixel=($x, $y) on ${width.toInt()}x${height.toInt()} bitmap")
                }
            } else if (confidence > 0.0) {
                circlePaint.color = lowConfColor
                canvas.drawCircle(x, y, radius * 0.7f, circlePaint)
                keypointsDrawn++
            }
        }

        // Debug: Log drawing stats (only once)
        if (!drawOverlayLogged) {
            Log.d(TAG, "🎨 drawOverlay() stats:")
            Log.d(TAG, "   Input keypoints: ${keypoints.size}")
            Log.d(TAG, "   Input connections: ${connections.size}")
            Log.d(TAG, "   Confidence threshold: $confThreshold")
            Log.d(TAG, "   Connections drawn: $connectionsDrawn")
            Log.d(TAG, "   Keypoints drawn: $keypointsDrawn")
            drawOverlayLogged = true
        }

        return bitmap
    }

    /**
     * Check if video encoding is available on this device
     * 
     * @return true if H.264 encoder is available, false otherwise
     */
    fun isAvailable(): Boolean {
        return try {
            val encoder = MediaCodec.createEncoderByType(MIME_TYPE)
            encoder.release()
            true
        } catch (e: Exception) {
            Log.w(TAG, "Video encoding not available: ${e.message}")
            false
        }
    }

    /**
     * Get maximum supported video dimensions for this device
     * 
     * @return Map with keys "maxWidth" and "maxHeight"
     */
    fun getMaxDimensions(): Map<String, Int> {
        return try {
            val encoder = MediaCodec.createEncoderByType(MIME_TYPE)
            val capabilities = encoder.codecInfo.getCapabilitiesForType(MIME_TYPE)
            
            // Query video encoder capabilities
            val videoCapabilities = capabilities.videoCapabilities
            val maxWidth = if (videoCapabilities != null && videoCapabilities.supportedWidths != null) {
                videoCapabilities.supportedWidths.upper
            } else {
                1920
            }
            
            val maxHeight = if (videoCapabilities != null && videoCapabilities.supportedHeights != null) {
                videoCapabilities.supportedHeights.upper
            } else {
                1080
            }
            
            encoder.release()
            
            mapOf(
                "maxWidth" to maxWidth,
                "maxHeight" to maxHeight
            )
        } catch (e: Exception) {
            Log.w(TAG, "Failed to query max dimensions: ${e.message}, using defaults")
            // Return safe defaults
            mapOf(
                "maxWidth" to 1920,
                "maxHeight" to 1080
            )
        }
    }
}
