# Testing Guide: Native Frame Extraction

## Prerequisites
- Android or iOS physical device (emulator may have performance differences)
- Flutter development environment configured
- Video file for testing (~30 seconds recommended)

---

## Quick Test

### 1. Build and Install

```bash
cd aiwa_app

# For Android
flutter build apk --release
flutter install

# For iOS
flutter build ios --release
# Deploy via Xcode
```

### 2. Record or Import Test Video

1. Launch the app
2. Navigate to Camera page
3. Choose one:
   - **Record New Video** (green button) → Record ~30 seconds of movement
   - **Import Videos** (gray button) → Select existing video from gallery

### 3. Monitor Analysis Progress

Watch the progress bar during analysis phases:
- **Phase 1 (0-20%)**: Native frame extraction
  - Expected time: **5-10 seconds** for 30s video
  - Look for log: `[VideoAnalysis] Extracting N frames using native platform API`
- **Phase 2 (20-90%)**: ML Kit pose detection
- **Phase 3 (90-100%)**: Analysis pipeline

### 4. Verify Outputs

After analysis completes, check:

```
[sessionRoot]/
├── frames/
│   ├── frame_000001.jpg
│   ├── frame_000002.jpg
│   └── ... (should have ~450 frames for 30s video)
├── neutral_keypoints.json
├── result.json
├── angles.csv
└── logs/
    └── perf.json
```

### 5. Check History Card

- Navigate to Home page
- Verify new green card appears with:
  - Score
  - Date/time
  - Exercise type
- Tap card → verify ResultPopupPage displays correctly

---

## Performance Benchmarks

### Expected Frame Extraction Times

| Video Length | Frame Count (stride=2) | Expected Time | Acceptable Range |
|--------------|------------------------|---------------|------------------|
| 10s | 150 | 2-4s | 1-6s |
| 30s | 450 | 5-10s | 3-15s |
| 60s | 900 | 10-20s | 6-30s |

**Performance Factors**:
- Device CPU/GPU capability
- Video resolution (higher = slightly slower)
- Device temperature (thermal throttling)
- Background processes

---

## Debug Logs to Watch

### Success Flow

```
[VideoAnalysis] Starting video analysis: /path/to/video.mp4
[VideoAnalysis] Probing video: /path/to/video.mp4
[VideoAnalysis] Video: 1080x1920, 30.0fps, 30000ms
[VideoAnalysis] Extracting 450 frames at 15.0fps using native platform API
[VideoAnalysis] Native extraction returned 450 frames
[VideoAnalysis] Successfully saved 450/450 frames
[VideoAnalysis] Completed pose detection for 450 frames
[VideoAnalysis] Quality: 95% usable
[VideoAnalysis] Pipeline complete
[VideoAnalysis] Outputs saved
[VideoAnalysis] Analysis complete
```

### Error Indicators

```
[VideoAnalysis] Native frame extraction error: ...
[VideoAnalysis] Frame extraction failed: ...
ERROR: FILE_NOT_FOUND
ERROR: INVALID_VIDEO
ERROR: OUT_OF_MEMORY
```

---

## Platform-Specific Testing

### Android Testing

**Device Requirements**:
- Android 5.0+ (API Level 21+)
- ~500MB free RAM
- Hardware video decoder support

**Test Steps**:
1. Enable USB debugging
2. Connect device
3. Run: `flutter run --release`
4. Record/import video
5. Check logcat for native logs:
   ```bash
   adb logcat | grep VideoFrameExtractor
   ```

**Expected Android Logs**:
```
VideoFrameExtractor: Extracting frames from /path/to/video.mp4
VideoFrameExtractor: Target FPS: 15.0, Total frames: 450
VideoFrameExtractor: Frame extraction complete, 450 frames extracted
```

### iOS Testing

**Device Requirements**:
- iOS 11.0+
- ~500MB free RAM
- VideoToolbox support

**Test Steps**:
1. Configure signing in Xcode
2. Build and deploy to device
3. Record/import video
4. Check Xcode console for native logs

**Expected iOS Logs**:
```
VideoFrameExtractor: Extracting frames from file:///...
VideoFrameExtractor: Duration: 30.0s, Target FPS: 15.0
VideoFrameExtractor: Frame extraction complete
```

---

## Common Issues & Solutions

### Issue 1: Extraction Takes > 15 Seconds

**Symptoms**: Frame extraction phase exceeds expected time

**Possible Causes**:
- Very high resolution video (4K+)
- Low-end device
- Device overheating
- Background processes consuming resources

**Solutions**:
1. Use lower resolution video (1080p or 720p)
2. Close background apps
3. Let device cool down
4. Reduce maxWidth/maxHeight in native_frame_extractor.dart

### Issue 2: Missing Frames

**Symptoms**: `Successfully saved X/Y frames` where X < Y

**Possible Causes**:
- Video seeking errors
- Corrupted video file
- Unsupported codec

**Solutions**:
1. Try different video file
2. Re-encode to H.264/AAC:
   ```bash
   ffmpeg -i input.mp4 -c:v libx264 -c:a aac output.mp4
   ```
3. Check device codec support

### Issue 3: Out of Memory (Android)

**Symptoms**: App crashes during extraction

**Possible Causes**:
- Video resolution too high
- Device low on RAM
- Memory leak

**Solutions**:
1. Use lower resolution video
2. Restart device
3. Check maxWidth/maxHeight settings
4. Reduce JPEG quality parameter

### Issue 4: Platform Exception

**Symptoms**: `PlatformException` or `MissingPluginException`

**Possible Causes**:
- MethodChannel not registered
- Native code compilation error
- Flutter hot restart issue

**Solutions**:
1. Stop app completely and rebuild
2. Run: `flutter clean && flutter pub get`
3. Check native code compilation logs
4. Verify MethodChannel names match

---

## Performance Tuning

### Adjustable Parameters

In `native_frame_extractor.dart` call:

```dart
NativeFrameExtractor.extractFrames(
  videoPath: videoPath,
  targetFps: 15.0,      // ⬅️ Adjust frame rate
  maxWidth: 720,        // ⬅️ Lower = faster
  maxHeight: 1280,      // ⬅️ Lower = faster
  quality: 95,          // ⬅️ Lower = faster (min 70 recommended)
)
```

**Tuning Guide**:
- If extraction > 15s: Reduce maxWidth to 480 or 640
- If frames blurry: Increase quality to 98
- If too many frames: Increase stride to 3 (10fps)

---

## Comparison Tests

### Before/After Performance Test

Test the same 30s video with both implementations (if you have old branch):

| Metric | video_thumbnail | Native | Improvement |
|--------|----------------|--------|-------------|
| Extraction Time | 15-25s | 5-10s | 2-3× faster |
| Memory Peak | ~200MB | ~150MB | 25% less |
| CPU Usage | High | Medium | More efficient |
| Compilation Warnings | Many | None | ✅ Clean |

---

## Test Scenarios

### 1. Basic Functionality

- [  ] 30s video extracts successfully
- [ ] Frame count matches expected (450 for 30s at 15fps)
- [ ] All frames are valid JPEG files
- [ ] Analysis completes end-to-end
- [ ] History card saves correctly

### 2. Edge Cases

- [ ] 5s video (very short)
- [ ] 90s video (longer)
- [ ] Portrait orientation video
- [ ] Landscape orientation video
- [ ] Low resolution video (480p)
- [ ] High resolution video (1080p or 4K)

### 3. Error Handling

- [ ] Missing video file
- [ ] Corrupted video file
- [ ] Unsupported format (if applicable)
- [ ] Device low on storage
- [ ] App backgrounded during extraction

### 4. Stress Testing

- [ ] Extract 3 videos back-to-back
- [ ] Extract while device is hot
- [ ] Extract with low battery
- [ ] Extract with other apps running

---

## Validation Checklist

### Output Quality

- [ ] Frames are clear and not pixelated
- [ ] Aspect ratio preserved correctly
- [ ] No artifacts or corruption
- [ ] Brightness/contrast looks normal

### Consistency

- [ ] Frame timestamps are sequential
- [ ] No duplicate frames
- [ ] No skipped frames (within tolerance)
- [ ] Frame numbering is correct (000001 to NNNNNN)

### Integration

- [ ] ML Kit pose detection works on extracted frames
- [ ] Analysis pipeline processes frames correctly
- [ ] Result popup displays accurate data
- [ ] Session files saved to correct location

---

## Reporting Results

If you encounter issues, please report:

1. **Device Info**:
   - Model and OS version
   - Available RAM
   - Storage space

2. **Video Info**:
   - Duration
   - Resolution
   - Codec (H.264, H.265, etc.)
   - File size

3. **Error Details**:
   - Full error message
   - Debug logs
   - Extraction time
   - Frame count achieved

4. **Steps to Reproduce**:
   - Exact steps taken
   - Expected behavior
   - Actual behavior

---

## Success Criteria

The native frame extraction is considered successful if:

1. ✅ 30s video extracts in 5-10 seconds
2. ✅ All expected frames are extracted
3. ✅ No compilation warnings
4. ✅ No memory leaks
5. ✅ Works on both Android and iOS
6. ✅ Error messages are clear and actionable
7. ✅ Integration with ML Kit is seamless

---

## Next Steps After Testing

Once testing is complete and successful:

1. Update app version in `pubspec.yaml`
2. Create release notes documenting performance improvements
3. Archive old video_thumbnail documentation
4. Update user-facing documentation if needed
5. Consider A/B testing with real users
6. Monitor crash reports and performance metrics

---

## Additional Resources

- [Android MediaMetadataRetriever Documentation](https://developer.android.com/reference/android/media/MediaMetadataRetriever)
- [iOS AVFoundation Documentation](https://developer.apple.com/documentation/avfoundation)
- [Flutter Platform Channels Guide](https://docs.flutter.dev/development/platform-integration/platform-channels)

---

**Happy Testing!** 🚀

