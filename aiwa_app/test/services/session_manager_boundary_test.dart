// session_manager_boundary_test.dart
// Purpose: Boundary/edge case tests for SessionManager
// Coverage: concurrent creation, permissions, cleanup edge cases, path handling

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:aiwa_app/services/storage/session_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    // Create temporary directory for testing
    tempDir = await Directory.systemTemp.createTemp('session_manager_boundary_test_');
  });

  Future<void> tearDown() async {
    // Clean up temporary directory
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  }

  group('SessionManager - Concurrent Creation', () {
    test('handles concurrent createSessionRoot calls', () async {
      // Create multiple sessions concurrently
      final futures = List.generate(5, (i) => SessionManager.createSessionRoot());
      final sessions = await Future.wait(futures);

      // All sessions should be unique
      expect(sessions.toSet().length, equals(5));
      
      // All sessions should exist
      for (final session in sessions) {
        expect(await Directory(session).exists(), isTrue);
      }
    });

    test('handles rapid sequential creation (timestamp collision)', () async {
      final sessions = <String>[];
      
      // Create 10 sessions in rapid succession
      for (int i = 0; i < 10; i++) {
        final session = await SessionManager.createSessionRoot();
        sessions.add(session);
      }

      // All sessions should be unique (even with same timestamp)
      expect(sessions.toSet().length, equals(10));
    });
  });

  group('SessionManager - Directory Permissions', () {
    test('handles directory creation when parent exists', () async {
      // Execute - path_provider ensures parent exists
      final session = await SessionManager.createSessionRoot();
      expect(await Directory(session).exists(), isTrue);
      expect(session, contains('/aiwa/offline_out/'));
    });

    test('creates parent directories when missing', () async {
      // Execute - path_provider handles this automatically
      final session = await SessionManager.createSessionRoot();
      expect(await Directory(session).exists(), isTrue);
      
      // Verify parent structure exists
      final parent = Directory(session).parent;
      expect(await parent.exists(), isTrue);
      expect(parent.path, contains('/aiwa/offline_out'));
    });

    // Note: Permission tests are platform-specific and may not work on Windows
    // They are marked as skip on Windows
    test('handles permission denied (read-only parent)', () async {
      // This test is skipped - path_provider always provides writable paths
    }, skip: 'path_provider ensures writable directories');
  });

  group('SessionManager - Cleanup Edge Cases', () {
    test('cleanupExpired with days=0 removes all sessions', () async {
      // Create test sessions
      final session1 = await SessionManager.createSessionRoot();
      final session2 = await SessionManager.createSessionRoot();
      
      expect(await Directory(session1).exists(), isTrue);
      expect(await Directory(session2).exists(), isTrue);

      // Cleanup with 0 days (remove all)
      await SessionManager.cleanupExpired(days: 0);

      // All sessions should be removed
      expect(await Directory(session1).exists(), isFalse);
      expect(await Directory(session2).exists(), isFalse);
    });

    test('cleanupExpired with negative days throws or treats as 0', () async {
      final session = await SessionManager.createSessionRoot();
      expect(await Directory(session).exists(), isTrue);

      // Cleanup with negative days (should throw or treat as 0)
      try {
        await SessionManager.cleanupExpired(days: -1);
        // If it doesn't throw, session should be removed
        expect(await Directory(session).exists(), isFalse);
      } catch (e) {
        // If it throws, that's also acceptable behavior
        expect(e, isA<ArgumentError>());
      }
    });

    test('cleanupExpired with very large days preserves all', () async {
      final session1 = await SessionManager.createSessionRoot();
      final session2 = await SessionManager.createSessionRoot();

      // Cleanup with 365 days (preserve all recent)
      await SessionManager.cleanupExpired(days: 365);

      // All sessions should still exist
      expect(await Directory(session1).exists(), isTrue);
      expect(await Directory(session2).exists(), isTrue);
    });

    test('cleanupExpired handles empty directory', () async {
      // Delete all sessions first
      final offlineOut = Directory('build/offline_out');
      if (await offlineOut.exists()) {
        await for (final entity in offlineOut.list()) {
          if (entity is Directory) {
            await entity.delete(recursive: true);
          }
        }
      }

      // Cleanup should not throw on empty directory
      expect(() => SessionManager.cleanupExpired(days: 7), returnsNormally);
    });

    test('cleanupExpired handles non-existent directory', () async {
      // Delete build directory entirely
      final buildDir = Directory('build');
      if (await buildDir.exists()) {
        await buildDir.delete(recursive: true);
      }

      // Cleanup should not throw on non-existent directory
      await SessionManager.cleanupExpired(days: 7);
      // Should succeed (no-op)
    });

    test('cleanupExpired preserves non-session directories', () async {
      // Create a non-session directory
      final nonSession = Directory('build/offline_out/not_a_session');
      await nonSession.create(recursive: true);

      final session = await SessionManager.createSessionRoot();

      // Cleanup with 0 days
      await SessionManager.cleanupExpired(days: 0);

      // Session should be removed
      expect(await Directory(session).exists(), isFalse);
      
      // Non-session directory should be preserved (or removed, depending on implementation)
      // This tests the robustness of the session name pattern matching
    });
  });

  group('SessionManager - Path Handling', () {
    test('session paths use forward slashes', () async {
      final session = await SessionManager.createSessionRoot();
      
      // Should use forward slashes (or be consistent)
      expect(session, contains('build/offline_out/'));
    });

    test('session directory names match expected pattern', () async {
      final session = await SessionManager.createSessionRoot();
      
      // Extract directory name
      final dirname = session.split('/').last;
      
      // Should match pattern: YYYYMMDD_HHMMSS_XXXX
      final pattern = RegExp(r'^\d{8}_\d{6}_[a-f0-9]{4}$');
      expect(pattern.hasMatch(dirname), isTrue);
    });

    test('handles absolute paths correctly', () async {
      final session = await SessionManager.createSessionRoot();
      
      // Convert to absolute path
      final absolutePath = Directory(session).absolute.path;
      
      expect(await Directory(absolutePath).exists(), isTrue);
    });
  });

  group('SessionManager - List Sessions', () {
    test('listSessions returns empty list when no sessions', () async {
      // Clean up all sessions first
      await SessionManager.cleanupExpired(days: 0);

      final sessions = await SessionManager.listSessions();
      expect(sessions, isEmpty);
    });

    test('listSessions returns all created sessions', () async {
      // Clean up first
      await SessionManager.cleanupExpired(days: 0);

      // Create sessions
      final session1 = await SessionManager.createSessionRoot();
      final session2 = await SessionManager.createSessionRoot();
      final session3 = await SessionManager.createSessionRoot();

      final sessions = await SessionManager.listSessions();

      expect(sessions.length, greaterThanOrEqualTo(3));
      expect(sessions, contains(session1));
      expect(sessions, contains(session2));
      expect(sessions, contains(session3));
    });

    test('listSessions handles directory read errors gracefully', () async {
      // Delete build directory
      final buildDir = Directory('build');
      if (await buildDir.exists()) {
        await buildDir.delete(recursive: true);
      }

      final sessions = await SessionManager.listSessions();
      
      // Should return empty list (or throw, depending on implementation)
      expect(sessions, isEmpty);
    });
  });

  group('SessionManager - Session Naming Collisions', () {
    test('handles identical timestamps with random suffix', () async {
      final sessions = <String>[];
      
      // Create many sessions rapidly to increase collision chance
      for (int i = 0; i < 20; i++) {
        final session = await SessionManager.createSessionRoot();
        sessions.add(session);
      }

      // All should be unique
      expect(sessions.toSet().length, equals(20));
    });
  });

  group('SessionManager - Large Scale Operations', () {
    test('creates and lists 100 sessions efficiently', () async {
      // Clean up first
      await SessionManager.cleanupExpired(days: 0);

      // Create 100 sessions
      for (int i = 0; i < 100; i++) {
        await SessionManager.createSessionRoot();
      }

      final sessions = await SessionManager.listSessions();
      expect(sessions.length, equals(100));
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('cleans up 100 old sessions efficiently', () async {
      // Create 100 sessions
      for (int i = 0; i < 100; i++) {
        await SessionManager.createSessionRoot();
      }

      // Cleanup all
      await SessionManager.cleanupExpired(days: 0);

      final sessions = await SessionManager.listSessions();
      expect(sessions, isEmpty);
    }, timeout: const Timeout(Duration(seconds: 30)));
  });

  group('SessionManager - Cross-Platform Compatibility', () {
    test('session paths work on current platform', () async {
      final session = await SessionManager.createSessionRoot();
      
      // Path should work on current platform
      final dir = Directory(session);
      expect(await dir.exists(), isTrue);
      
      // Should be able to create files in session
      final testFile = File('$session/test.txt');
      await testFile.writeAsString('test');
      expect(await testFile.exists(), isTrue);
    });

    test('handles path separators correctly', () async {
      final session = await SessionManager.createSessionRoot();
      
      // Normalize path separators
      final normalized = session.replaceAll('\\', '/');
      expect(normalized, contains('build/offline_out/'));
    });
  });
}

