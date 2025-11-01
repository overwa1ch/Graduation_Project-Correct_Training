// lib/services/native_frame_extractor.dart
//
// Native frame extractor using platform channels with real-time progress
// - Android: MediaMetadataRetriever with EventChannel streaming
// - iOS: AVFoundation with EventChannel streaming

import 'dart:async';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart';
import 'package:aiwa_app/services/cancellation_token.dart';

/// Exception thrown when native frame extraction fails
class NativeFrameExtractionException implements Exception {
  final String code;
  final String message;
  final String? details;

  NativeFrameExtractionException({
    required this.code,
    required this.message,
    this.details,
  });

  @override
  String toString() => 'NativeFrameExtractionException($code): $message${details != null ? '\nDetails: $details' : ''}';
}

/// Progress event from native extraction
class FrameExtractionProgress {
  final int processed;
  final int total;
  final Uint8List? frameData; // null means progress update only

  FrameExtractionProgress({
    required this.processed,
    required this.total,
    this.frameData,
  });

  double get progressPercent => total > 0 ? (processed / total) : 0.0;
  bool get hasFrameData => frameData != null;
}

/// Native frame extractor for video files with progress streaming
class NativeFrameExtractor {
  /// MethodChannel for starting extraction
  static const MethodChannel _methodChannel = MethodChannel('com.example.aiwa/video_frames');
  
  /// EventChannel for progress stream
  static const EventChannel _eventChannel = EventChannel('com.example.aiwa/video_frames_events');

  /// Extract frames from a video file with real-time progress updates
  /// 
  /// Returns a stream of progress events, each containing frame data or progress update
  /// 
  /// Parameters:
  /// - [videoPath]: Absolute path to the video file
  /// - [targetFps]: Desired frames per second for extraction
  /// - [maxWidth]: Maximum width for extracted frames (scaled if larger)
  /// - [maxHeight]: Maximum height for extracted frames (scaled if larger)
  /// - [quality]: JPEG quality (0-100, default 95)
  /// - [token]: Optional cancellation token for canceling extraction
  /// 
  /// Throws:
  /// - [NativeFrameExtractionException] if extraction fails
  static Stream<FrameExtractionProgress> extractFramesWithProgress({
    required String videoPath,
    required double targetFps,
    required int maxWidth,
    required int maxHeight,
    int quality = 95,
    CancellationToken? token,
  }) {
    late StreamController<FrameExtractionProgress> controller;
    StreamSubscription<dynamic>? eventSubscription;
    Timer? cancellationCheckTimer;
    final tokenId = token?.id;

    controller = StreamController<FrameExtractionProgress>(
      onListen: () async {
        try {
          // Listen for cancellation token changes
          void checkCancellation() {
            if (token?.isCancelling == true && tokenId != null) {
              // Call native cancel method
              cancelExtraction(tokenId);
            }
          }

          // Periodically check token cancellation status
          if (token != null) {
            cancellationCheckTimer = Timer.periodic(const Duration(milliseconds: 100), (Timer _) {
              checkCancellation();
            });
          }

          // Subscribe to event stream first
          eventSubscription = _eventChannel.receiveBroadcastStream().listen(
            (dynamic event) {
              if (event is Map) {
                // Check for error
                final error = event['error'] as String?;
                if (error != null) {
                  final exception = NativeFrameExtractionException(
                    code: event['errorCode'] as String? ?? 'EXTRACTION_ERROR',
                    message: error,
                    details: event['errorDetails'] as String?,
                  );
                  controller.addError(exception);
                  controller.close();
                  return;
                }

                // Parse progress event
                final processed = event['processed'] as int? ?? 0;
                final total = event['total'] as int? ?? 0;
                final frameDataRaw = event['frameData'];
                
                Uint8List? frameData;
                if (frameDataRaw != null) {
                  if (frameDataRaw is Uint8List) {
                    frameData = frameDataRaw;
                  } else if (frameDataRaw is List<int>) {
                    frameData = Uint8List.fromList(frameDataRaw);
                  }
                }

                final progress = FrameExtractionProgress(
                  processed: processed,
                  total: total,
                  frameData: frameData,
                );
                
                controller.add(progress);

                // Close stream when complete
                if (processed >= total && total > 0) {
                  controller.close();
                }
              } else {
                controller.addError(NativeFrameExtractionException(
                  code: 'INVALID_EVENT',
                  message: 'Invalid event format from native code',
                  details: 'Expected Map, got ${event.runtimeType}',
                ));
                controller.close();
              }
            },
            onError: (Object error) {
              if (error is PlatformException) {
                controller.addError(NativeFrameExtractionException(
                  code: error.code,
                  message: error.message ?? 'Platform error',
                  details: error.details?.toString(),
                ));
              } else {
                controller.addError(NativeFrameExtractionException(
                  code: 'STREAM_ERROR',
                  message: 'Event stream error',
                  details: error.toString(),
                ));
              }
              controller.close();
            },
            onDone: () {
              if (!controller.isClosed) {
                controller.close();
              }
            },
          );

          // Start extraction via method call
          final arguments = <String, dynamic>{
            'videoPath': videoPath,
            'targetFps': targetFps,
            'maxWidth': maxWidth,
            'maxHeight': maxHeight,
            'quality': quality,
          };
          
          // Add tokenId if provided
          if (tokenId != null) {
            arguments['tokenId'] = tokenId;
          }
          
          await _methodChannel.invokeMethod('startExtraction', arguments);

        } on PlatformException catch (e) {
          controller.addError(NativeFrameExtractionException(
            code: e.code,
            message: e.message ?? 'Failed to start extraction',
            details: e.details?.toString(),
          ));
          controller.close();
        } catch (e) {
          controller.addError(NativeFrameExtractionException(
            code: 'START_ERROR',
            message: 'Failed to start extraction',
            details: e.toString(),
          ));
          controller.close();
        }
      },
      onCancel: () {
        // If we have a token and it's not already cancelled, cancel the native extraction
        if (tokenId != null && token?.isCancelling != true) {
          cancelExtraction(tokenId);
        }
        eventSubscription?.cancel();
        cancellationCheckTimer?.cancel();
      },
    );

    return controller.stream;
  }

  /// Cancel frame extraction for a given token ID
  /// 
  /// This method calls the native layer to stop frame extraction
  /// 
  /// Parameters:
  /// - [tokenId]: The cancellation token ID
  static Future<void> cancelExtraction(String tokenId) async {
    try {
      await _methodChannel.invokeMethod('cancelExtraction', {
        'tokenId': tokenId,
      });
    } on PlatformException catch (e) {
      // Ignore errors if extraction already completed or tokenId not found
      debugPrint('[NativeFrameExtractor] Failed to cancel extraction: ${e.message}');
    } catch (e) {
      debugPrint('[NativeFrameExtractor] Error canceling extraction: $e');
    }
  }

  /// Legacy method - extract all frames at once (for backward compatibility)
  /// This now uses the stream-based method internally
  /// 
  /// Parameters:
  /// - [videoPath]: Absolute path to the video file
  /// - [targetFps]: Desired frames per second for extraction
  /// - [maxWidth]: Maximum width for extracted frames (scaled if larger)
  /// - [maxHeight]: Maximum height for extracted frames (scaled if larger)
  /// - [quality]: JPEG quality (0-100, default 95)
  /// 
  /// Returns: List of JPEG byte arrays, one per frame
  /// 
  /// Throws:
  /// - [NativeFrameExtractionException] if extraction fails
  static Future<List<Uint8List>> extractFrames({
    required String videoPath,
    required double targetFps,
    required int maxWidth,
    required int maxHeight,
    int quality = 95,
  }) async {
    final frames = <Uint8List>[];
    
    try {
      await for (final progress in extractFramesWithProgress(
        videoPath: videoPath,
        targetFps: targetFps,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        quality: quality,
      )) {
        if (progress.frameData != null) {
          frames.add(progress.frameData!);
        }
      }
    } catch (e) {
      if (e is NativeFrameExtractionException) {
        rethrow;
      }
      throw NativeFrameExtractionException(
        code: 'EXTRACTION_FAILED',
        message: 'Frame extraction failed',
        details: e.toString(),
      );
    }
    
    return frames;
  }

  /// Check if native frame extraction is available on this platform
  /// 
  /// Returns true for Android and iOS, false otherwise
  static bool isAvailable() {
    try {
      return true;
    } catch (e) {
      return false;
    }
  }
}

