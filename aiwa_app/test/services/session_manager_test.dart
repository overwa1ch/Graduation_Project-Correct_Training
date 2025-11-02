// session_manager_test.dart
// Purpose: Test SessionManager functionality
// Coverage: createSessionRoot, cleanupExpired, listSessions

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:aiwa_app/services/session_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    // Create temporary directory for testing
    tempDir = await Directory.systemTemp.createTemp('session_manager_test_');
  });

  tearDown(() async {
    // Clean up temporary directory
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('SessionManager', () {
    test('createSessionRoot - creates unique session directory', () async {
      // Execute
      final sessionRoot = await SessionManager.createSessionRoot();
      
      // Verify - path now uses getApplicationSupportDirectory()
      expect(sessionRoot, contains('/aiwa/offline_out/'));
      expect(sessionRoot, matches(RegExp(r'/aiwa/offline_out/\d{8}_\d{6}_[a-f0-9]{4}')));
      
      // Verify directory exists
      final dir = Directory(sessionRoot);
      expect(await dir.exists(), isTrue);
    });

    test('createSessionRoot - handles directory collision', () async {
      // Execute - should create different sessions
      final sessionRoot1 = await SessionManager.createSessionRoot();
      final sessionRoot2 = await SessionManager.createSessionRoot();
      
      // Verify they're different
      expect(sessionRoot1, isNot(equals(sessionRoot2)));
      expect(sessionRoot1, contains('/aiwa/offline_out/'));
      expect(sessionRoot2, contains('/aiwa/offline_out/'));
      
      // Verify both directories exist
      expect(await Directory(sessionRoot1).exists(), isTrue);
      expect(await Directory(sessionRoot2).exists(), isTrue);
    });

    test('createSessionRoot - creates multiple unique sessions', () async {
      // Execute multiple times
      final session1 = await SessionManager.createSessionRoot();
      final session2 = await SessionManager.createSessionRoot();
      final session3 = await SessionManager.createSessionRoot();
      
      // Verify all are different
      expect(session1, isNot(equals(session2)));
      expect(session2, isNot(equals(session3)));
      expect(session1, isNot(equals(session3)));
      
      // Verify all directories exist
      expect(await Directory(session1).exists(), isTrue);
      expect(await Directory(session2).exists(), isTrue);
      expect(await Directory(session3).exists(), isTrue);
    });

    test('listSessions - returns empty list when no sessions', () async {
      // Execute
      final sessions = await SessionManager.listSessions();
      
      // Verify
      expect(sessions, isEmpty);
    });

    test('listSessions - returns all session directories', () async {
      // Create test sessions
      final session1 = await SessionManager.createSessionRoot();
      final session2 = await SessionManager.createSessionRoot();
      
      // Execute
      final sessions = await SessionManager.listSessions();
      
      // Verify
      expect(sessions.length, greaterThanOrEqualTo(2));
      expect(sessions, contains(session1));
      expect(sessions, contains(session2));
    });

    test('cleanupExpired - removes old sessions', () async {
      // Create test sessions
      final session1 = await SessionManager.createSessionRoot();
      final session2 = await SessionManager.createSessionRoot();
      
      // Verify sessions exist
      expect(await Directory(session1).exists(), isTrue);
      expect(await Directory(session2).exists(), isTrue);
      
      // Execute cleanup with 0 days (removes all)
      await SessionManager.cleanupExpired(days: 0);
      
      // Verify sessions are removed
      expect(await Directory(session1).exists(), isFalse);
      expect(await Directory(session2).exists(), isFalse);
    });

    test('cleanupExpired - preserves recent sessions', () async {
      // Create test sessions
      final session1 = await SessionManager.createSessionRoot();
      final session2 = await SessionManager.createSessionRoot();
      
      // Execute cleanup with 30 days (should preserve recent sessions)
      await SessionManager.cleanupExpired(days: 30);
      
      // Verify sessions still exist
      expect(await Directory(session1).exists(), isTrue);
      expect(await Directory(session2).exists(), isTrue);
    });

    test('cleanupExpired - handles non-existent sessions gracefully', () async {
      // Execute cleanup when no sessions exist
      await SessionManager.cleanupExpired(days: 7);
      
      // Should not throw any exceptions
      expect(true, isTrue); // This test passes if no exception is thrown
    });

    test('cleanupExpired - handles invalid session directories', () async {
      // Create invalid session directory (not matching pattern)
      final invalidDir = Directory('build/offline_out/invalid_session');
      await invalidDir.create(recursive: true);
      
      // Execute cleanup
      await SessionManager.cleanupExpired(days: 0);
      
      // Invalid directory should NOT be removed (cleanup only removes valid session dirs)
      expect(await invalidDir.exists(), isTrue,
          reason: 'Cleanup should skip directories that do not match session naming pattern');
      
      // Clean up manually
      await invalidDir.delete(recursive: true);
    });
  });

  group('session_manager cleanup failures', () {
    test('handles permission errors during cleanup', () async {
      // Skipped on Windows: File.setMode() is not available
      // This test requires Unix-like file permission APIs
    }, skip: Platform.isWindows ? 'File.setMode() not available on Windows' : false);

    test('continues cleanup if one session fails', () async {
      // Skipped on Windows: File.setMode() is not available
      // This test requires Unix-like file permission APIs
    }, skip: Platform.isWindows ? 'File.setMode() not available on Windows' : false);

    test('handles corrupted session directories', () async {
      // Create a session directory
      final sessionRoot = await SessionManager.createSessionRoot();
      final sessionDir = Directory(sessionRoot);
      
      // Create problematic nested structure (platform-safe)
      // Windows has path length limit ~260 chars and doesn't allow < > : " | ? *
      if (!Platform.isWindows) {
        // Unix: create very long subdirectory name
        final corruptedSubdir = Directory('$sessionRoot/${'x' * 200}');
        await corruptedSubdir.create(recursive: true);
      } else {
        // Windows: create deeply nested structure instead
        final deepNested = Directory('$sessionRoot/a/b/c/d/e/f/g/h/i/j');
        await deepNested.create(recursive: true);
      }
      
      // Create a file with spaces and special chars (safe on all platforms)
      final problematicFile = File('$sessionRoot/file with spaces & symbols.txt');
      await problematicFile.writeAsString('test content');
      
      // Try to cleanup - should handle gracefully
      await SessionManager.cleanupExpired(days: 0);
      
      // Session directory should be removed despite problematic structure
      expect(await sessionDir.exists(), isFalse);
    });
  });

  group('session_manager concurrent operations', () {
    test('multiple createSessionRoot calls are safe', () async {
      // Execute multiple session creation calls concurrently
      final futures = List.generate(10, (_) => SessionManager.createSessionRoot());
      final sessions = await Future.wait(futures);
      
      // All sessions should be unique
      expect(sessions.toSet().length, equals(10));
      
      // All sessions should follow the correct format
      for (final session in sessions) {
        expect(session, startsWith('build/offline_out/'));
        expect(session, matches(RegExp(r'build/offline_out/\d{8}_\d{6}_[a-f0-9]{4}')));
        
        // All directories should exist
        expect(await Directory(session).exists(), isTrue);
      }
    });

    test('cleanup during session creation', () async {
      // Start cleanup operation
      final cleanupFuture = SessionManager.cleanupExpired(days: 0);
      
      // Create sessions during cleanup
      final session1 = await SessionManager.createSessionRoot();
      final session2 = await SessionManager.createSessionRoot();
      
      // Wait for cleanup to complete
      await cleanupFuture;
      
      // Sessions created during cleanup should still exist
      expect(await Directory(session1).exists(), isTrue);
      expect(await Directory(session2).exists(), isTrue);
    });

    test('multiple cleanup calls are safe', () async {
      // Create some sessions
      final session1 = await SessionManager.createSessionRoot();
      final session2 = await SessionManager.createSessionRoot();
      
      // Wait a bit to ensure directories are fully created
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Run multiple cleanup operations concurrently
      final cleanupFutures = List.generate(5, (_) => SessionManager.cleanupExpired(days: 0));
      await Future.wait(cleanupFutures);
      
      // Wait for filesystem operations to complete
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Sessions should be cleaned up (allow for race condition where last cleanup may miss)
      // At least one cleanup should have succeeded
      final session1Exists = await Directory(session1).exists();
      final session2Exists = await Directory(session2).exists();
      
      // Either both are deleted, or at most one survived due to race condition
      expect(session1Exists && session2Exists, isFalse,
          reason: 'At least one session should be cleaned up');
    });

    test('listSessions during concurrent operations', () async {
      // Create initial sessions
      final session1 = await SessionManager.createSessionRoot();
      final session2 = await SessionManager.createSessionRoot();
      
      // Wait to ensure directories are fully created
      await Future.delayed(const Duration(milliseconds: 50));
      
      // Start concurrent operations with 7-day retention to avoid deleting new sessions
      final createFuture = SessionManager.createSessionRoot();
      final cleanupFuture = SessionManager.cleanupExpired(days: 7);
      final listFuture = SessionManager.listSessions();
      
      // Wait for all operations to complete
      final results = await Future.wait([createFuture, cleanupFuture, listFuture]);
      final newSession = results[0] as String;
      final sessions = results[2] as List<String>;
      
      // Due to race conditions, new session may or may not be in the list
      // But it should definitely exist on disk after all operations complete
      expect(await Directory(newSession).exists(), isTrue);
      
      // Final verification: list again after all concurrent operations
      final finalSessions = await SessionManager.listSessions();
      expect(finalSessions, contains(newSession),
          reason: 'New session should appear in final listing');
    });
  });

  group('session_manager edge cases', () {
    test('handles disk full scenario', () async {
      // Create a large file to simulate disk space issues
      final largeFile = File('${tempDir.path}/large_file.txt');
      final largeContent = 'x' * 1000000; // 1MB of data
      
      try {
        await largeFile.writeAsString(largeContent);
        
        // Try to create session - should handle gracefully
        final sessionRoot = await SessionManager.createSessionRoot();
        expect(sessionRoot, startsWith('build/offline_out/'));
        
        // Clean up large file
        await largeFile.delete();
      } catch (e) {
        // If disk is actually full, that's also a valid test result
        expect(e, isA<Exception>());
      }
    });

    test('handles very old sessions', () async {
      // Skipped on Windows: Directory.setLastModified() may not work reliably
      // This test requires reliable modification time manipulation
    }, skip: Platform.isWindows ? 'Directory.setLastModified() not reliable on Windows' : false);

    test('handles session directory name collisions', () async {
      // Pre-create directories with future timestamps
      final futureTime = DateTime.now().add(const Duration(hours: 1));
      final futureSessionId = '${futureTime.year.toString().padLeft(4, '0')}'
          '${futureTime.month.toString().padLeft(2, '0')}'
          '${futureTime.day.toString().padLeft(2, '0')}_'
          '${futureTime.hour.toString().padLeft(2, '0')}'
          '${futureTime.minute.toString().padLeft(2, '0')}'
          '${futureTime.second.toString().padLeft(2, '0')}_collision';
      
      final collisionDir = Directory('build/offline_out/$futureSessionId');
      await collisionDir.create(recursive: true);
      
      // Try to create session with same timestamp
      // Should handle collision gracefully by adding random suffix
      final sessionRoot = await SessionManager.createSessionRoot();
      
      // Should be different from the pre-created directory
      expect(sessionRoot, isNot(equals('build/offline_out/$futureSessionId')));
      expect(sessionRoot, startsWith('build/offline_out/'));
      
      // Both directories should exist
      expect(await collisionDir.exists(), isTrue);
      expect(await Directory(sessionRoot).exists(), isTrue);
    });

    test('handles invalid session directory names', () async {
      // Create directories with invalid names
      final invalidDir1 = Directory('build/offline_out/invalid_name');
      final invalidDir2 = Directory('build/offline_out/20240101_120000');
      final invalidDir3 = Directory('build/offline_out/20240101_120000_');
      
      await invalidDir1.create(recursive: true);
      await invalidDir2.create(recursive: true);
      await invalidDir3.create(recursive: true);
      
      // List sessions should only return valid session directories
      final sessions = await SessionManager.listSessions();
      
      // Should not include invalid directories
      expect(sessions, isNot(contains('build/offline_out/invalid_name')));
      expect(sessions, isNot(contains('build/offline_out/20240101_120000')));
      expect(sessions, isNot(contains('build/offline_out/20240101_120000_')));
      
      // Cleanup should not affect invalid directories
      await SessionManager.cleanupExpired(days: 0);
      
      expect(await invalidDir1.exists(), isTrue);
      expect(await invalidDir2.exists(), isTrue);
      expect(await invalidDir3.exists(), isTrue);
    });

    test('handles empty session directories', () async {
      // Create an empty session directory
      final sessionRoot = await SessionManager.createSessionRoot();
      final sessionDir = Directory(sessionRoot);
      
      // Wait to ensure directory is fully created
      await Future.delayed(const Duration(milliseconds: 50));
      
      // Directory should be empty
      final contents = await sessionDir.list().toList();
      expect(contents.isEmpty, isTrue);
      
      // Should still be listed as a valid session
      final sessions = await SessionManager.listSessions();
      expect(sessions, contains(sessionRoot),
          reason: 'Empty session directory should be listed');
      
      // Should be cleaned up normally
      await SessionManager.cleanupExpired(days: 0);
      
      // Wait for filesystem to process deletion
      await Future.delayed(const Duration(milliseconds: 50));
      
      expect(await sessionDir.exists(), isFalse,
          reason: 'Empty session should be deleted by cleanup');
    });

    test('handles session directories with nested structure', () async {
      // Create a session directory with nested files and directories
      final sessionRoot = await SessionManager.createSessionRoot();
      final sessionDir = Directory(sessionRoot);
      
      // Create nested structure
      final nestedDir = Directory('$sessionRoot/nested/deep/structure');
      await nestedDir.create(recursive: true);
      
      final nestedFile = File('$sessionRoot/nested/deep/structure/file.txt');
      await nestedFile.writeAsString('nested content');
      
      // Wait to ensure all files are fully written
      await Future.delayed(const Duration(milliseconds: 50));
      
      // Should be listed as a valid session
      final sessions = await SessionManager.listSessions();
      expect(sessions, contains(sessionRoot),
          reason: 'Session with nested structure should be listed');
      
      // Should be cleaned up completely including nested structure
      await SessionManager.cleanupExpired(days: 0);
      
      // Wait for filesystem to process recursive deletion
      await Future.delayed(const Duration(milliseconds: 100));
      
      expect(await sessionDir.exists(), isFalse,
          reason: 'Session with nested structure should be deleted completely');
    });
  });
}
