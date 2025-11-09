// lib/services/keypoint_overlay_generator.dart
//
// Generate overlay video with keypoints drawn on frames

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import 'package:aiwa_app/services/native/native_video_encoder.dart';
import 'package:aiwa_app/services/visualization/keypoint_skeleton.dart';
import 'package:aiwa_core/pose/keypoint_names.dart';

/// Generator for creating keypoint overlay videos
class KeypointOverlayGenerator {
  /// Generate overlay video from session data
  /// 
  /// Parameters:
  /// - [sessionRoot]: Root directory of the analysis session
  /// - [outputFileName]: Output video filename (default: 'keypoints_overlay.mp4')
  /// 
  /// Returns: Absolute path to the generated video file
  /// 
  /// Throws:
  /// - [FileSystemException] if session data is missing
  /// - [NativeVideoEncodingException] if video encoding fails
  static Future<String> generateOverlayVideo({
    required String sessionRoot,
    String outputFileName = 'keypoints_overlay.mp4',
  }) async {
    debugPrint('[KeypointOverlayGenerator] Starting overlay video generation');
    debugPrint('[KeypointOverlayGenerator] Session root: $sessionRoot');

    final sessionDir = Directory(sessionRoot);
    if (!await sessionDir.exists()) {
      throw FileSystemException('Session directory not found', sessionRoot);
    }

    // 1. Load neutral keypoints JSON
    final keypointsFile = File(p.join(sessionRoot, 'neutral_keypoints.json'));
    if (!await keypointsFile.exists()) {
      throw FileSystemException('Keypoints file not found', keypointsFile.path);
    }

    final keypointsJson = jsonDecode(await keypointsFile.readAsString()) as Map<String, dynamic>;
    final frames = keypointsJson['frames'] as List<dynamic>;
    final videoInfo = keypointsJson['video'] as Map<String, dynamic>;
    final samplingInfo = keypointsJson['sampling'] as Map<String, dynamic>;

    final width = videoInfo['width'] as int;
    final height = videoInfo['height'] as int;
    final fps = (samplingInfo['effectiveFps'] as num).round();

    debugPrint('[KeypointOverlayGenerator] Video: ${width}x$height, $fps fps, ${frames.length} frames');

    // 2. Load frame images
    final framesDir = Directory(p.join(sessionRoot, 'frames'));
    if (!await framesDir.exists()) {
      throw FileSystemException('Frames directory not found', framesDir.path);
    }

    final frameFiles = await framesDir
        .list()
        .where((entity) => entity is File && entity.path.endsWith('.jpg'))
        .map((entity) => entity as File)
        .toList();

    frameFiles.sort((a, b) => a.path.compareTo(b.path));

    if (frameFiles.isEmpty) {
      throw FileSystemException('No frame images found', framesDir.path);
    }

    debugPrint('[KeypointOverlayGenerator] Found ${frameFiles.length} frame images');

    // 3. Match frames with keypoints
    final frameImages = <Uint8List>[];
    final keypointsPerFrame = <List<Map<String, dynamic>>>[];

    for (int i = 0; i < frameFiles.length; i++) {
      // Load frame image
      final frameData = await frameFiles[i].readAsBytes();
      frameImages.add(frameData);

      // Get corresponding keypoints
      if (i < frames.length) {
        final frameJson = frames[i] as Map<String, dynamic>;
        final keypoints = frameJson['keypoints'] as List<dynamic>;

        // Convert keypoints to format expected by encoder
        final keypointsList = keypoints.map((kp) {
          final kpMap = kp as Map<String, dynamic>;
          return {
            'name': normalizeNeutralKeypointName(kpMap['name'] as String),
            'x': (kpMap['x'] as num).toDouble(),
            'y': (kpMap['y'] as num).toDouble(),
            'score': (kpMap['score'] as num).toDouble(),
          };
        }).toList();

        keypointsPerFrame.add(keypointsList);
      } else {
        // No keypoints for this frame (shouldn't happen, but handle gracefully)
        keypointsPerFrame.add([]);
      }
    }

    // 4. Get skeleton connections and properties
    final engine = keypointsJson['engine'] as Map<String, dynamic>?;
    final engineName = (engine?['name'] as String?) ?? '';
    final isMoveNet = engineName.toLowerCase().contains('movenet')
        || (frames.isNotEmpty && (frames.first as Map<String, dynamic>)['keypoints'] is List && ((frames.first as Map<String, dynamic>)['keypoints'] as List).length == 17);

    final connections = isMoveNet
        ? KeypointSkeleton.getConnectionsForNativeMoveNet()
        : KeypointSkeleton.getConnectionsForNative();
    final keypointProperties = isMoveNet
        ? KeypointSkeleton.getKeypointPropertiesForNativeMoveNet()
        : KeypointSkeleton.getKeypointPropertiesForNative();

    // 5. Generate output path
    final outputPath = p.join(sessionRoot, outputFileName);

    debugPrint('[KeypointOverlayGenerator] Encoding video to: $outputPath');

    // 6. Encode overlay video
    try {
      final videoPath = await NativeVideoEncoder.encodeOverlayVideo(
        frameImages: frameImages,
        keypointsPerFrame: keypointsPerFrame,
        connections: connections,
        keypointProperties: keypointProperties,
        outputPath: outputPath,
        fps: fps,
        width: width,
        height: height,
      );

      debugPrint('[KeypointOverlayGenerator] Overlay video generated: $videoPath');
      
      // Verify file exists and has non-zero size
      final outputFile = File(videoPath);
      if (!await outputFile.exists()) {
        throw FileSystemException('Output video file not created', videoPath);
      }
      
      final fileSize = await outputFile.length();
      debugPrint('[KeypointOverlayGenerator] Output file size: ${(fileSize / 1024).round()} KB');
      
      if (fileSize == 0) {
        throw FileSystemException('Output video file is empty', videoPath);
      }

      return videoPath;
    } catch (e) {
      debugPrint('[KeypointOverlayGenerator] Failed to generate overlay video: $e');
      rethrow;
    }
  }

  /// Check if overlay video can be generated for a session
  /// 
  /// Returns true if all required files exist
  static Future<bool> canGenerateOverlay(String sessionRoot) async {
    try {
      final sessionDir = Directory(sessionRoot);
      if (!await sessionDir.exists()) {
        return false;
      }

      final keypointsFile = File(p.join(sessionRoot, 'neutral_keypoints.json'));
      if (!await keypointsFile.exists()) {
        return false;
      }

      final framesDir = Directory(p.join(sessionRoot, 'frames'));
      if (!await framesDir.exists()) {
        return false;
      }

      final framesList = await framesDir
          .list()
          .where((entity) => entity is File && entity.path.endsWith('.jpg'))
          .toList();

      return framesList.isNotEmpty;
    } catch (e) {
      debugPrint('[KeypointOverlayGenerator] Error checking overlay requirements: $e');
      return false;
    }
  }

  /// Get estimated overlay video size in bytes
  /// 
  /// Rough estimation: width * height * fps * 0.1 bytes per frame
  static Future<int> estimateVideoSize(String sessionRoot) async {
    try {
      final keypointsFile = File(p.join(sessionRoot, 'neutral_keypoints.json'));
      if (!await keypointsFile.exists()) {
        return 0;
      }

      final keypointsJson = jsonDecode(await keypointsFile.readAsString()) as Map<String, dynamic>;
      final frames = keypointsJson['frames'] as List<dynamic>;
      final videoInfo = keypointsJson['video'] as Map<String, dynamic>;
      final samplingInfo = keypointsJson['sampling'] as Map<String, dynamic>;

      final width = videoInfo['width'] as int;
      final height = videoInfo['height'] as int;
      final fps = (samplingInfo['effectiveFps'] as num).round();

      // Rough estimation: H.264 at reasonable quality
      final estimatedSize = (width * height * fps * frames.length * 0.25 / 8).round();
      
      return estimatedSize;
    } catch (e) {
      debugPrint('[KeypointOverlayGenerator] Error estimating video size: $e');
      return 0;
    }
  }
}

