// session_manager.dart
// Version: v1.1
// Purpose: 会话目录管理服务（使用应用可写目录）
//
// 职责：
// 1. 创建唯一会话目录（格式: <appSupport>/aiwa/offline_out/yyyyMMdd_HHmmss_<rand>）
// 2. 清理过期会话（根据 cleanup.days 配置）
// 3. 列出所有会话
//
// 使用示例：
// ```dart
// // 创建新会话
// final sessionRoot = await SessionManager.createSessionRoot();
// // => "/data/user/0/com.example.app/files/aiwa/offline_out/20251028_143052_a7f3"
//
// // 清理 7 天前的会话
// await SessionManager.cleanupExpired(days: 7);
// ```

import 'dart:io';
import 'dart:math';
import 'package:path_provider/path_provider.dart';

/// 会话管理器（静态类）
class SessionManager {
  /// 获取会话根目录基路径（跨平台可写）
  static Future<String> _getSessionBasePath() async {
    final appSupport = await getApplicationSupportDirectory();
    return '${appSupport.path}/aiwa/offline_out';
  }

  /// 创建新会话目录
  ///
  /// 返回: 会话根路径（例如: "<appSupport>/aiwa/offline_out/20251028_143052_a7f3"）
  ///
  /// 行为:
  /// - 格式: <appSupport>/aiwa/offline_out/yyyyMMdd_HHmmss_<rand>
  /// - 自动创建目录
  /// - 若目录已存在，自动重试（最多 10 次）
  static Future<String> createSessionRoot() async {
    // 获取可写基路径
    final basePath = await _getSessionBasePath();
    
    // 确保父目录存在
    await Directory(basePath).create(recursive: true);

    // 增加重试次数以增强并发安全性
    for (var attempt = 0; attempt < 10; attempt++) {
      final sessionId = _generateSessionId();
      final sessionRoot = '$basePath/$sessionId';
      final dir = Directory(sessionRoot);

      try {
        await dir.create();
        print('[SessionManager] Created session: $sessionRoot');
        return sessionRoot;
      } on FileSystemException catch (_) {
        // 并发竞争：目录已存在，重试
        if (await dir.exists()) {
          await Future<void>.delayed(const Duration(milliseconds: 5));
          continue;
        }
        rethrow;
      }
    }

    throw StateError('Failed to create unique session directory after 10 attempts');
  }

  /// 清理过期会话
  ///
  /// 参数:
  /// - [days]: 保留天数（默认 7 天）
  ///
  /// 行为:
  /// - 删除修改时间超过 N 天的会话目录
  /// - 跳过非会话目录（不符合命名规则）
  /// - 失败时记录日志但不抛错
  static Future<void> cleanupExpired({int days = 7}) async {
    if (days < 0) {
      throw ArgumentError('days must be >= 0');
    }
    
    final basePath = await _getSessionBasePath();
    final rootDir = Directory(basePath);
    if (!await rootDir.exists()) {
      print('[SessionManager] No sessions to clean up');
      return;
    }

    // days == 0: 移除所有会话
    if (days == 0) {
      int deletedAll = 0;
      try {
        await for (final entity in rootDir.list()) {
          if (entity is! Directory) continue;
          
          // 使用 path.split 而不是 uri.pathSegments 来获取目录名
          final name = entity.path.replaceAll('\\', '/').split('/').last;
          
          if (!_isSessionDirName(name)) continue;
          try {
            await entity.delete(recursive: true);
            deletedAll++;
            print('[SessionManager] Deleted session: $name');
          } catch (e) {
            print('[SessionManager] Failed to delete $name: $e');
          }
        }
        print('[SessionManager] Cleanup complete: deleted $deletedAll sessions (days=0)');
      } catch (e) {
        print('[SessionManager] Cleanup error: $e');
      }
      return;
    }

    final cutoffTime = DateTime.now().subtract(Duration(days: days));
    int deletedCount = 0;

    try {
      await for (final entity in rootDir.list()) {
        if (entity is! Directory) continue;

        // 使用 path.split 而不是 uri.pathSegments 来获取目录名
        final name = entity.path.replaceAll('\\', '/').split('/').last;
        
        if (!_isSessionDirName(name)) continue;

        // 检查修改时间
        final stat = await entity.stat();
        if (stat.modified.isBefore(cutoffTime)) {
          try {
            await entity.delete(recursive: true);
            deletedCount++;
            print('[SessionManager] Deleted expired session: $name');
          } catch (e) {
            print('[SessionManager] Failed to delete $name: $e');
          }
        }
      }

      print('[SessionManager] Cleanup complete: deleted $deletedCount sessions older than $days days');
    } catch (e) {
      print('[SessionManager] Cleanup error: $e');
    }
  }

  /// 列出所有会话目录
  ///
  /// 返回: 会话路径列表（按修改时间倒序）
  static Future<List<String>> listSessions() async {
    final basePath = await _getSessionBasePath();
    final rootDir = Directory(basePath);
    if (!await rootDir.exists()) {
      return [];
    }

    final sessions = <String>[];

    try {
      await for (final entity in rootDir.list()) {
        if (entity is! Directory) continue;
        
        // 使用 path.split 而不是 uri.pathSegments 来获取目录名（更可靠）
        final name = entity.path.replaceAll('\\', '/').split('/').last;
        
        if (_isSessionDirName(name)) {
          // 使用规范化的路径（正斜杠）
          sessions.add(entity.path.replaceAll('\\', '/'));
        }
      }

      // 按目录修改时间倒序排序（缺失文件时更健壮）
      sessions.sort((a, b) {
        DateTime modA;
        DateTime modB;
        try {
          modA = Directory(a).statSync().modified;
        } catch (_) {
          modA = DateTime.fromMillisecondsSinceEpoch(0);
        }
        try {
          modB = Directory(b).statSync().modified;
        } catch (_) {
          modB = DateTime.fromMillisecondsSinceEpoch(0);
        }
        return modB.compareTo(modA);
      });
    } catch (e) {
      print('[SessionManager] List sessions error: $e');
    }

    return sessions;
  }

  // ============================================================================
  // 私有辅助函数
  // ============================================================================

  /// 生成唯一会话 ID（格式: yyyyMMdd_HHmmss_<rand>）
  static String _generateSessionId() {
    final now = DateTime.now();
    final dateStr = now.toIso8601String().substring(0, 10).replaceAll('-', '');
    final timeStr = '${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}'
        '${now.second.toString().padLeft(2, '0')}';
    final rand = Random().nextInt(0xFFFF).toRadixString(16).padLeft(4, '0');
    return '${dateStr}_${timeStr}_$rand';
  }

  /// 检查是否是会话目录名（格式: yyyyMMdd_HHmmss_xxxx）
  static bool _isSessionDirName(String name) {
    // 匹配格式: 8位数字_6位数字_4位十六进制
    final pattern = RegExp(r'^\d{8}_\d{6}_[0-9a-fA-F]{4}$');
    return pattern.hasMatch(name);
  }
}

