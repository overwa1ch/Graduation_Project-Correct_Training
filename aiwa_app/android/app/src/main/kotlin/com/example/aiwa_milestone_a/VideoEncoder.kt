package com.example.aiwa_milestone_a

import android.content.Context
import android.graphics.*
import android.media.MediaCodec
import android.media.MediaCodecInfo
import android.media.MediaFormat
import android.media.MediaMuxer
import android.util.Log
import java.io.File
import java.io.IOException
import java.nio.ByteBuffer

object VideoEncoder {
    private const val TAG = "VideoEncoder"
    private const val MIME_TYPE = "video/avc" // H.264
    private const val IFRAME_INTERVAL = 1 // I-frame interval in seconds
    private const val BIT_RATE_MULTIPLIER = 0.25 // bits per pixel
    private const val TIMEOUT_US = 10000L

    /**
     * Encode overlay video with keypoints drawn on frames
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
        Log.d(TAG, "Starting video encoding: ${frameImages.size} frames, ${fps}fps, ${width}x${height}")
        
        val outputFile = File(outputPath)
        if (outputFile.exists()) {
            outputFile.delete()
        }
        outputFile.parentFile?.mkdirs()

        var mediaCodec: MediaCodec? = null
        var mediaMuxer: MediaMuxer? = null
        var trackIndex = -1
        var muxerStarted = false

        try {
            // Create MediaCodec encoder
            mediaCodec = MediaCodec.createEncoderByType(MIME_TYPE)
            val format = MediaFormat.createVideoFormat(MIME_TYPE, width, height).apply {
                setInteger(MediaFormat.KEY_COLOR_FORMAT, MediaCodecInfo.CodecCapabilities.COLOR_FormatYUV420Flexible)
                setInteger(MediaFormat.KEY_BIT_RATE, (width * height * BIT_RATE_MULTIPLIER * fps).toInt())
                setInteger(MediaFormat.KEY_FRAME_RATE, fps)
                setInteger(MediaFormat.KEY_I_FRAME_INTERVAL, IFRAME_INTERVAL)
            }
            
            mediaCodec.configure(format, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE)
            mediaCodec.start()
            
            // Create MediaMuxer
            mediaMuxer = MediaMuxer(outputPath, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)

            val bufferInfo = MediaCodec.BufferInfo()
            var frameIndex = 0
            var inputDone = false
            var outputDone = false

            while (!outputDone) {
                // Feed input frames
                if (!inputDone) {
                    val inputBufferIndex = mediaCodec.dequeueInputBuffer(TIMEOUT_US)
                    if (inputBufferIndex >= 0) {
                        if (frameIndex < frameImages.size) {
                            val inputBuffer = mediaCodec.getInputBuffer(inputBufferIndex)
                            if (inputBuffer != null) {
                                // Decode JPEG to Bitmap
                                val bitmap = BitmapFactory.decodeByteArray(
                                    frameImages[frameIndex], 
                                    0, 
                                    frameImages[frameIndex].size
                                )
                                
                                if (bitmap != null) {
                                    // Draw keypoints and skeleton on bitmap
                                    val overlayBitmap = drawOverlay(
                                        bitmap,
                                        keypointsPerFrame.getOrNull(frameIndex) ?: emptyList(),
                                        connections,
                                        keypointProperties
                                    )
                                    
                                    // Convert bitmap to YUV
                                    val yuvData = bitmapToYUV420(overlayBitmap)
                                    inputBuffer.clear()
                                    inputBuffer.put(yuvData)
                                    
                                    val presentationTimeUs = frameIndex * 1000000L / fps
                                    mediaCodec.queueInputBuffer(
                                        inputBufferIndex,
                                        0,
                                        yuvData.size,
                                        presentationTimeUs,
                                        0
                                    )
                                    
                                    bitmap.recycle()
                                    if (overlayBitmap != bitmap) {
                                        overlayBitmap.recycle()
                                    }
                                    
                                    frameIndex++
                                    Log.d(TAG, "Encoded frame $frameIndex/${frameImages.size}")
                                } else {
                                    Log.w(TAG, "Failed to decode frame $frameIndex")
                                    mediaCodec.queueInputBuffer(inputBufferIndex, 0, 0, 0, 0)
                                    frameIndex++
                                }
                            }
                        } else {
                            // Signal end of input
                            mediaCodec.queueInputBuffer(
                                inputBufferIndex,
                                0,
                                0,
                                0,
                                MediaCodec.BUFFER_FLAG_END_OF_STREAM
                            )
                            inputDone = true
                            Log.d(TAG, "Input stream ended")
                        }
                    }
                }

                // Get encoded output
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
                        Log.d(TAG, "MediaMuxer started")
                    }
                    outputBufferIndex >= 0 -> {
                        val outputBuffer = mediaCodec.getOutputBuffer(outputBufferIndex)
                        if (outputBuffer != null && bufferInfo.size > 0 && muxerStarted) {
                            outputBuffer.position(bufferInfo.offset)
                            outputBuffer.limit(bufferInfo.offset + bufferInfo.size)
                            mediaMuxer.writeSampleData(trackIndex, outputBuffer, bufferInfo)
                        }
                        
                        mediaCodec.releaseOutputBuffer(outputBufferIndex, false)
                        
                        if ((bufferInfo.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM) != 0) {
                            outputDone = true
                            Log.d(TAG, "Output stream ended")
                        }
                    }
                }
            }

            Log.d(TAG, "Video encoding completed: $outputPath")
            return outputPath

        } catch (e: Exception) {
            Log.e(TAG, "Video encoding failed", e)
            throw IOException("Video encoding failed: ${e.message}", e)
        } finally {
            try {
                mediaCodec?.stop()
                mediaCodec?.release()
                if (muxerStarted) {
                    mediaMuxer?.stop()
                }
                mediaMuxer?.release()
            } catch (e: Exception) {
                Log.e(TAG, "Error releasing resources", e)
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

        // Create keypoint lookup map
        val keypointMap = keypoints.associateBy { it["name"] as String }

        // Extract properties
        val radius = (keypointProperties["radius"] as? Double)?.toFloat() ?: 4f
        val highConfColor = (keypointProperties["highConfidenceColor"] as? Int) ?: Color.GREEN
        val lowConfColor = (keypointProperties["lowConfidenceColor"] as? Int) ?: Color.GRAY
        val confThreshold = (keypointProperties["confidenceThreshold"] as? Double) ?: 0.7

        // Draw connections (bones)
        val linePaint = Paint().apply {
            style = Paint.Style.STROKE
            strokeCap = Paint.Cap.ROUND
            isAntiAlias = true
        }

        for (conn in connections) {
            val startName = conn["start"] as? String ?: continue
            val endName = conn["end"] as? String ?: continue
            val startKp = keypointMap[startName] ?: continue
            val endKp = keypointMap[endName] ?: continue

            val startX = ((startKp["x"] as? Double) ?: 0.0).toFloat() * width
            val startY = ((startKp["y"] as? Double) ?: 0.0).toFloat() * height
            val endX = ((endKp["x"] as? Double) ?: 0.0).toFloat() * width
            val endY = ((endKp["y"] as? Double) ?: 0.0).toFloat() * height
            
            val startScore = (startKp["score"] as? Double) ?: 0.0
            val endScore = (endKp["score"] as? Double) ?: 0.0

            // Only draw if both keypoints have reasonable confidence
            if (startScore > 0.3 && endScore > 0.3) {
                linePaint.color = (conn["color"] as? Int) ?: Color.WHITE
                linePaint.strokeWidth = ((conn["strokeWidth"] as? Double) ?: 3.0).toFloat()
                canvas.drawLine(startX, startY, endX, endY, linePaint)
            }
        }

        // Draw keypoints
        val pointPaint = Paint().apply {
            style = Paint.Style.FILL
            isAntiAlias = true
        }

        for (kp in keypoints) {
            val x = ((kp["x"] as? Double) ?: 0.0).toFloat() * width
            val y = ((kp["y"] as? Double) ?: 0.0).toFloat() * height
            val score = (kp["score"] as? Double) ?: 0.0

            if (score > 0.3) { // Only draw if minimum confidence
                pointPaint.color = if (score >= confThreshold) highConfColor else lowConfColor
                canvas.drawCircle(x, y, radius, pointPaint)
            }
        }

        return bitmap
    }

    /**
     * Convert bitmap to YUV420 format for MediaCodec
     */
    private fun bitmapToYUV420(bitmap: Bitmap): ByteArray {
        val width = bitmap.width
        val height = bitmap.height
        val yuvSize = width * height * 3 / 2
        val yuv = ByteArray(yuvSize)

        val argb = IntArray(width * height)
        bitmap.getPixels(argb, 0, width, 0, 0, width, height)

        var yIndex = 0
        var uvIndex = width * height
        var index = 0

        for (j in 0 until height) {
            for (i in 0 until width) {
                val R = (argb[index] and 0xff0000) shr 16
                val G = (argb[index] and 0xff00) shr 8
                val B = (argb[index] and 0xff)

                val Y = ((66 * R + 129 * G + 25 * B + 128) shr 8) + 16
                val U = ((-38 * R - 74 * G + 112 * B + 128) shr 8) + 128
                val V = ((112 * R - 94 * G - 18 * B + 128) shr 8) + 128

                yuv[yIndex++] = Y.coerceIn(0, 255).toByte()

                if (j % 2 == 0 && i % 2 == 0) {
                    yuv[uvIndex++] = U.coerceIn(0, 255).toByte()
                    yuv[uvIndex++] = V.coerceIn(0, 255).toByte()
                }

                index++
            }
        }

        return yuv
    }

    /**
     * Get maximum supported video dimensions
     */
    fun getMaxDimensions(): Map<String, Int> {
        return mapOf(
            "maxWidth" to 1920,
            "maxHeight" to 1080
        )
    }

    /**
     * Check if video encoding is available
     */
    fun isAvailable(): Boolean {
        return try {
            MediaCodec.createEncoderByType(MIME_TYPE) != null
        } catch (e: Exception) {
            false
        }
    }
}

