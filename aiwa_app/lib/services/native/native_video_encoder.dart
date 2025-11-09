// lib/services/native_video_encoder.dart
//
// Native video encoder using platform channels
// - Android: MediaCodec + MediaMuxer
// - iOS: AVFoundation (AVAssetWriter)

import 'dart:async';
import 'package:flutter/services.dart';

/// Exception thrown when native video encoding fails
class NativeVideoEncodingException implements Exception {
  final String code;
  final String message;
  final String? details;

  NativeVideoEncodingException({
    required this.code,
    required this.message,
    this.details,
  });

  @override
  String toString() => 'NativeVideoEncodingException($code): $message${details != null ? '\nDetails: $details' : ''}';
}

/// Native video encoder for creating overlay videos with keypoints
class NativeVideoEncoder {
  /// MethodChannel for video encoding
  static const MethodChannel _channel = MethodChannel('com.example.aiwa/video_encoder');

  /// Encode overlay video with keypoints drawn on frames
  /// 
  /// Parameters:
  /// - [frameImages]: List of JPEG frame images (byte arrays)
  /// - [keypointsPerFrame]: List of keypoints for each frame
  ///   Each frame's keypoints is a list of maps with keys: 'name', 'x', 'y', 'score'
  /// - [connections]: List of skeleton connections
  ///   Each connection is a map with keys: 'start', 'end', 'color', 'strokeWidth'
  /// - [keypointProperties]: Visual properties for keypoints
  ///   Map with keys: 'radius', 'highConfidenceColor', 'lowConfidenceColor', 'confidenceThreshold'
  /// - [outputPath]: Absolute path for the output video file
  /// - [fps]: Frames per second for the output video
  /// - [width]: Video width in pixels
  /// - [height]: Video height in pixels
  /// 
  /// Returns: Absolute path to the created video file
  /// 
  /// Throws:
  /// - [NativeVideoEncodingException] if encoding fails
  static Future<String> encodeOverlayVideo({
    required List<Uint8List> frameImages,
    required List<List<Map<String, dynamic>>> keypointsPerFrame,
    required List<Map<String, dynamic>> connections,
    required Map<String, dynamic> keypointProperties,
    required String outputPath,
    required int fps,
    required int width,
    required int height,
  }) async {
    if (frameImages.isEmpty) {
      throw NativeVideoEncodingException(
        code: 'INVALID_INPUT',
        message: 'Frame images list cannot be empty',
      );
    }

    if (frameImages.length != keypointsPerFrame.length) {
      throw NativeVideoEncodingException(
        code: 'INVALID_INPUT',
        message: 'Frame images and keypoints lists must have the same length',
        details: 'Frames: ${frameImages.length}, Keypoints: ${keypointsPerFrame.length}',
      );
    }

    if (fps <= 0 || fps > 120) {
      throw NativeVideoEncodingException(
        code: 'INVALID_INPUT',
        message: 'FPS must be between 1 and 120',
        details: 'Provided FPS: $fps',
      );
    }

    if (width <= 0 || height <= 0) {
      throw NativeVideoEncodingException(
        code: 'INVALID_INPUT',
        message: 'Width and height must be positive',
        details: 'Provided: ${width}x$height',
      );
    }

    try {
      final result = await _channel.invokeMethod<String>('encodeOverlayVideo', {
        'frameImages': frameImages,
        'keypointsPerFrame': keypointsPerFrame,
        'connections': connections,
        'keypointProperties': keypointProperties,
        'outputPath': outputPath,
        'fps': fps,
        'width': width,
        'height': height,
      });

      if (result == null || result.isEmpty) {
        throw NativeVideoEncodingException(
          code: 'ENCODING_FAILED',
          message: 'Native encoder returned null or empty path',
        );
      }

      return result;
    } on PlatformException catch (e) {
      throw NativeVideoEncodingException(
        code: e.code,
        message: e.message ?? 'Failed to encode video',
        details: e.details?.toString(),
      );
    } catch (e) {
      throw NativeVideoEncodingException(
        code: 'ENCODING_FAILED',
        message: 'Failed to encode video',
        details: e.toString(),
      );
    }
  }

  /// Check if native video encoding is available on this platform
  /// 
  /// Returns true for Android and iOS, false otherwise
  static Future<bool> isAvailable() async {
    try {
      final result = await _channel.invokeMethod<bool>('isAvailable');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Get maximum supported video dimensions for this device
  /// 
  /// Returns a map with keys: 'maxWidth', 'maxHeight'
  static Future<Map<String, int>> getMaxDimensions() async {
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('getMaxDimensions');
      if (result != null) {
        return {
          'maxWidth': result['maxWidth'] as int? ?? 1920,
          'maxHeight': result['maxHeight'] as int? ?? 1080,
        };
      }
    } catch (e) {
      // Return default if query fails
    }
    return {'maxWidth': 1920, 'maxHeight': 1080};
  }
}

