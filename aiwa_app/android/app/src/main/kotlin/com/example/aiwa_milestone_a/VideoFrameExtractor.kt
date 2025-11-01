package com.example.aiwa_milestone_a

import android.content.Context
import android.graphics.Bitmap
import android.media.MediaMetadataRetriever
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.FileNotFoundException
import kotlin.math.roundToInt

object VideoFrameExtractor {
    /**
     * Extract frames with progress callback (streaming mode)
     * 
     * @param context Android context
     * @param tokenId Cancellation token ID (empty string if not provided)
     * @param videoPath Absolute path to the video file
     * @param targetFps Desired frames per second for extraction
     * @param maxWidth Maximum width for extracted frames (scaled if larger)
     * @param maxHeight Maximum height for extracted frames (scaled if larger)
     * @param quality JPEG quality (0-100)
     * @param isCancelled Lambda function that returns true if extraction should be cancelled
     * @param onProgress Callback(processed, total, frameData) - frameData is null for progress-only updates
     */
    fun extractFramesWithProgress(
        context: Context,
        tokenId: String = "",
        videoPath: String,
        targetFps: Double,
        maxWidth: Int,
        maxHeight: Int,
        quality: Int,
        isCancelled: () -> Boolean = { false },
        onProgress: (Int, Int, ByteArray?) -> Unit
    ) {
        // Validate file exists
        val videoFile = File(videoPath)
        if (!videoFile.exists()) {
            throw FileNotFoundException("Video file not found: $videoPath")
        }

        android.util.Log.d("VideoFrameExtractor", "Starting extraction: $videoPath")
        val retriever = MediaMetadataRetriever()
        
        try {
            // Initialize retriever
            android.util.Log.d("VideoFrameExtractor", "Setting data source")
            retriever.setDataSource(videoPath)

            // Get video duration
            val durationStr = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)
                ?: throw IllegalArgumentException("Cannot get video duration")
            val durationMs = durationStr.toLong()
            val durationUs = durationMs * 1000

            // Calculate frame interval
            val frameIntervalUs = (1_000_000.0 / targetFps).roundToInt().toLong()
            val totalFrames = (durationUs / frameIntervalUs).toInt()

            android.util.Log.d("VideoFrameExtractor", "Video: ${durationMs}ms, Target FPS: $targetFps, Total frames: $totalFrames")

            // Extract frames with progress updates
            for (i in 0 until totalFrames) {
                // Check for cancellation before processing each frame
                if (isCancelled()) {
                    android.util.Log.d("VideoFrameExtractor", "Extraction cancelled at frame $i/$totalFrames")
                    return
                }
                
                val timeUs = i * frameIntervalUs
                
                // Log every 50 frames
                if (i % 50 == 0) {
                    android.util.Log.d("VideoFrameExtractor", "Progress: $i/$totalFrames frames")
                }
                
                // Get frame
                val bitmap = retriever.getFrameAtTime(
                    timeUs,
                    MediaMetadataRetriever.OPTION_CLOSEST
                )

                if (bitmap != null) {
                    // Scale bitmap
                    val scaledBitmap = scaleBitmap(bitmap, maxWidth, maxHeight)
                    
                    // Convert to JPEG
                    val outputStream = ByteArrayOutputStream()
                    scaledBitmap.compress(Bitmap.CompressFormat.JPEG, quality, outputStream)
                    val jpegData = outputStream.toByteArray()
                    
                    // Send frame data + progress
                    onProgress(i + 1, totalFrames, jpegData)
                    
                    // Recycle bitmaps to free memory
                    if (scaledBitmap != bitmap) {
                        scaledBitmap.recycle()
                    }
                    bitmap.recycle()
                } else {
                    // Progress update without frame data
                    onProgress(i + 1, totalFrames, null)
                }
            }

            android.util.Log.d("VideoFrameExtractor", "Extraction complete: $totalFrames frames")

        } catch (e: OutOfMemoryError) {
            android.util.Log.e("VideoFrameExtractor", "Out of memory: ${e.message}")
            throw OutOfMemoryError("Out of memory while extracting frames: ${e.message}")
        } catch (e: IllegalArgumentException) {
            android.util.Log.e("VideoFrameExtractor", "Invalid argument: ${e.message}")
            throw IllegalArgumentException("Invalid video file or arguments: ${e.message}")
        } catch (e: Exception) {
            android.util.Log.e("VideoFrameExtractor", "Extraction failed: ${e.message}")
            throw Exception("Failed to extract frames: ${e.message}", e)
        } finally {
            try {
                retriever.release()
                android.util.Log.d("VideoFrameExtractor", "MediaMetadataRetriever released")
            } catch (e: Exception) {
                // Ignore release errors
            }
        }
    }

    /**
     * Extract frames from a video file using MediaMetadataRetriever (legacy method)
     * 
     * @param context Android context
     * @param videoPath Absolute path to the video file
     * @param targetFps Desired frames per second for extraction
     * @param maxWidth Maximum width for extracted frames (scaled if larger)
     * @param maxHeight Maximum height for extracted frames (scaled if larger)
     * @param quality JPEG quality (0-100)
     * @return List of JPEG byte arrays
     */
    fun extractFrames(
        context: Context,
        videoPath: String,
        targetFps: Double,
        maxWidth: Int,
        maxHeight: Int,
        quality: Int
    ): List<ByteArray> {
        val frames = mutableListOf<ByteArray>()
        
        extractFramesWithProgress(
            context = context,
            tokenId = "", // No token for legacy method
            videoPath = videoPath,
            targetFps = targetFps,
            maxWidth = maxWidth,
            maxHeight = maxHeight,
            quality = quality,
            isCancelled = { false }, // No cancellation for legacy method
            onProgress = { processed, total, frameData ->
                if (frameData != null) {
                    frames.add(frameData)
                }
            }
        )
        
        return frames
    }

    /**
     * Extract frames from a video file using MediaMetadataRetriever (old implementation, kept for reference)
     */
    private fun extractFramesOld(
        context: Context,
        videoPath: String,
        targetFps: Double,
        maxWidth: Int,
        maxHeight: Int,
        quality: Int
    ): List<ByteArray> {
        // Validate file exists
        val videoFile = File(videoPath)
        if (!videoFile.exists()) {
            throw FileNotFoundException("Video file not found: $videoPath")
        }

        val retriever = MediaMetadataRetriever()
        val frames = mutableListOf<ByteArray>()

        try {
            // Initialize retriever with video file
            retriever.setDataSource(videoPath)

            // Get video duration in microseconds
            val durationStr = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)
                ?: throw IllegalArgumentException("Cannot get video duration")
            val durationMs = durationStr.toLong()
            val durationUs = durationMs * 1000

            // Calculate frame interval in microseconds
            val frameIntervalUs = (1_000_000.0 / targetFps).roundToInt().toLong()
            
            // Calculate total number of frames
            val totalFrames = (durationUs / frameIntervalUs).toInt()

            // Extract frames at specified intervals
            for (i in 0 until totalFrames) {
                val timeUs = i * frameIntervalUs
                
                // Get frame at specified time
                val bitmap = retriever.getFrameAtTime(
                    timeUs,
                    MediaMetadataRetriever.OPTION_CLOSEST
                )

                if (bitmap != null) {
                    // Scale bitmap if needed
                    val scaledBitmap = scaleBitmap(bitmap, maxWidth, maxHeight)
                    
                    // Convert to JPEG
                    val outputStream = ByteArrayOutputStream()
                    scaledBitmap.compress(Bitmap.CompressFormat.JPEG, quality, outputStream)
                    val jpegData = outputStream.toByteArray()
                    
                    frames.add(jpegData)
                    
                    // Recycle bitmaps to free memory
                    if (scaledBitmap != bitmap) {
                        scaledBitmap.recycle()
                    }
                    bitmap.recycle()
                } else {
                    // If frame extraction fails, add empty placeholder or skip
                    // For now, we skip empty frames
                }
            }

            return frames

        } catch (e: OutOfMemoryError) {
            throw OutOfMemoryError("Out of memory while extracting frames: ${e.message}")
        } catch (e: IllegalArgumentException) {
            throw IllegalArgumentException("Invalid video file or arguments: ${e.message}")
        } catch (e: Exception) {
            throw Exception("Failed to extract frames: ${e.message}", e)
        } finally {
            // Always release retriever resources
            try {
                retriever.release()
            } catch (e: Exception) {
                // Ignore release errors
            }
        }
    }

    /**
     * Scale a bitmap to fit within max dimensions while maintaining aspect ratio
     */
    private fun scaleBitmap(original: Bitmap, maxWidth: Int, maxHeight: Int): Bitmap {
        val originalWidth = original.width
        val originalHeight = original.height

        // If already smaller than max, return original
        if (originalWidth <= maxWidth && originalHeight <= maxHeight) {
            return original
        }

        // Calculate scaling factor
        val widthScale = maxWidth.toFloat() / originalWidth
        val heightScale = maxHeight.toFloat() / originalHeight
        val scale = minOf(widthScale, heightScale)

        // Calculate new dimensions
        val newWidth = (originalWidth * scale).roundToInt()
        val newHeight = (originalHeight * scale).roundToInt()

        // Create scaled bitmap
        return Bitmap.createScaledBitmap(original, newWidth, newHeight, true)
    }
}

