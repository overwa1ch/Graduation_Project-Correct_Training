// analysis_history.dart
// Version: v1.0
// Purpose: 管理分析历史记录的持久化存储
//
// 职责：
// 1. 保存分析记录（AnalysisRecord）到本地 JSON 文件
// 2. 加载所有历史记录（按时间倒序）
// 3. 更新记录（编辑显示名称和备注）
// 4. 删除记录（可选：同时删除会话文件）
//
// 数据存储:
// - 位置: <appSupport>/aiwa/analysis_history.json
// - 格式: JSON 数组，每项包含 id、result、sessionRoot、timestamp、displayName、notes、thumbnailPath
//
// 使用示例：
// ```dart
// // 保存新记录
// await AnalysisHistoryService().saveRecord(
//   result: lite,
//   sessionRoot: '/path/to/session',
// );
//
// // 加载所有记录
// final records = await AnalysisHistoryService().loadAllRecords();
//
// // 更新记录
// await AnalysisHistoryService().updateRecord(
//   id: 'xxx',
//   displayName: 'My Workout',
//   notes: 'Great session!',
// );
//
// // 删除记录
// await AnalysisHistoryService().deleteRecord(id: 'xxx', deleteSessionFiles: true);
// ```

import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:aiwa_app/adapters/result_adapter.dart';

// ============================================================================
// 数据模型
// ============================================================================

/// 分析历史记录
///
/// 存储单次分析的完整信息，包括结果数据、会话路径、用户自定义信息等
class AnalysisRecord {
  /// 唯一标识符（基于时间戳生成）
  final String id;

  /// 分析结果数据
  final AnalysisResultLite result;

  /// 会话根目录路径
  final String sessionRoot;

  /// 创建时间
  final DateTime timestamp;

  /// 用户可编辑的显示名称（默认自动生成）
  String displayName;

  /// 用户备注（可选）
  String? notes;

  /// 缩略图路径（相对于 sessionRoot，来自 result.evidencePath）
  final String? thumbnailPath;

  AnalysisRecord({
    required this.id,
    required this.result,
    required this.sessionRoot,
    required this.timestamp,
    required this.displayName,
    this.notes,
    this.thumbnailPath,
  });

  /// 从 JSON 反序列化
  factory AnalysisRecord.fromJson(Map<String, dynamic> json) {
    // 解析嵌套的 result 对象
    final resultJson = json['result'] as Map<String, dynamic>;
    final result = AnalysisResultLite(
      posture: resultJson['posture'] as int?,
      stability: resultJson['stability'] as int?,
      rhythm: resultJson['rhythm'] as int?,
      total: resultJson['total'] as int?,
      reps: resultJson['reps'] as int? ?? 0,
      evidencePath: resultJson['evidencePath'] as String?,
      lowConfidence: resultJson['lowConfidence'] as bool?,
      coverage: (resultJson['coverage'] as num?)?.toDouble(),
      templateName: resultJson['templateName'] as String?,
      strictness: resultJson['strictness'] as String?,
      engine: resultJson['engine'] as String?,
      fps: resultJson['fps'] as int?,
    );

    return AnalysisRecord(
      id: json['id'] as String,
      result: result,
      sessionRoot: json['sessionRoot'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      displayName: json['displayName'] as String,
      notes: json['notes'] as String?,
      thumbnailPath: json['thumbnailPath'] as String?,
    );
  }

  /// 序列化为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'result': {
        'posture': result.posture,
        'stability': result.stability,
        'rhythm': result.rhythm,
        'total': result.total,
        'reps': result.reps,
        'evidencePath': result.evidencePath,
        'lowConfidence': result.lowConfidence,
        'coverage': result.coverage,
        'templateName': result.templateName,
        'strictness': result.strictness,
        'engine': result.engine,
        'fps': result.fps,
      },
      'sessionRoot': sessionRoot,
      'timestamp': timestamp.toIso8601String(),
      'displayName': displayName,
      'notes': notes,
      'thumbnailPath': thumbnailPath,
    };
  }
}

// ============================================================================
// 历史记录服务
// ============================================================================

/// 分析历史记录服务（单例模式）
class AnalysisHistoryService {
  /// 获取历史记录文件路径
  Future<String> _getHistoryFilePath() async {
    final appSupport = await getApplicationSupportDirectory();
    final dir = Directory('${appSupport.path}/aiwa');
    
    // 确保目录存在
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    
    return '${dir.path}/analysis_history.json';
  }

  /// 保存新的分析记录
  ///
  /// 参数:
  /// - [result]: 分析结果轻量模型
  /// - [sessionRoot]: 会话根目录路径
  ///
  /// 行为:
  /// - 自动生成唯一 ID（基于时间戳）
  /// - 自动生成默认显示名称（格式: "{templateName} #{count}"）
  /// - 提取缩略图路径（来自 result.evidencePath）
  /// - 追加到历史记录文件
  Future<void> saveRecord({
    required AnalysisResultLite result,
    required String sessionRoot,
  }) async {
    try {
      // 加载现有记录
      final records = await loadAllRecords();

      // 生成唯一 ID（时间戳 + 随机数）
      final id = '${DateTime.now().millisecondsSinceEpoch}';

      // 自动生成显示名称
      final templateName = result.templateName ?? 'Exercise';
      final count = records.where((r) => 
        r.result.templateName == result.templateName
      ).length + 1;
      final displayName = '$templateName #$count';

      // 创建新记录
      final record = AnalysisRecord(
        id: id,
        result: result,
        sessionRoot: sessionRoot,
        timestamp: DateTime.now(),
        displayName: displayName,
        notes: null,
        thumbnailPath: result.evidencePath,
      );

      // 追加到列表
      records.add(record);

      // 持久化
      await _saveRecords(records);

      print('[AnalysisHistory] Saved record: $displayName (id: $id)');
    } catch (e) {
      print('[AnalysisHistory] Failed to save record: $e');
      rethrow;
    }
  }

  /// 加载所有历史记录
  ///
  /// 返回: 记录列表（按时间倒序排序）
  ///
  /// 行为:
  /// - 若文件不存在，返回空列表
  /// - 若解析失败，记录错误并返回空列表
  Future<List<AnalysisRecord>> loadAllRecords() async {
    try {
      final filePath = await _getHistoryFilePath();
      final file = File(filePath);

      // 文件不存在，返回空列表
      if (!await file.exists()) {
        return [];
      }

      // 读取并解析 JSON
      final content = await file.readAsString(encoding: utf8);
      final List<dynamic> jsonList = jsonDecode(content) as List<dynamic>;

      // 反序列化
      final records = jsonList
          .map((json) => AnalysisRecord.fromJson(json as Map<String, dynamic>))
          .toList();

      // 按时间倒序排序
      records.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      return records;
    } catch (e) {
      print('[AnalysisHistory] Failed to load records: $e');
      return [];
    }
  }

  /// 更新记录（编辑显示名称和备注）
  ///
  /// 参数:
  /// - [id]: 记录 ID
  /// - [displayName]: 新的显示名称（可选）
  /// - [notes]: 新的备注（可选）
  ///
  /// 行为:
  /// - 查找并更新指定记录
  /// - 若 ID 不存在，抛出异常
  Future<void> updateRecord({
    required String id,
    String? displayName,
    String? notes,
  }) async {
    try {
      final records = await loadAllRecords();

      // 查找记录
      final index = records.indexWhere((r) => r.id == id);
      if (index == -1) {
        throw ArgumentError('Record not found: $id');
      }

      // 更新字段
      if (displayName != null) {
        records[index].displayName = displayName;
      }
      if (notes != null) {
        records[index].notes = notes;
      }

      // 持久化
      await _saveRecords(records);

      print('[AnalysisHistory] Updated record: $id');
    } catch (e) {
      print('[AnalysisHistory] Failed to update record: $e');
      rethrow;
    }
  }

  /// 删除记录
  ///
  /// 参数:
  /// - [id]: 记录 ID
  /// - [deleteSessionFiles]: 是否同时删除会话目录（默认: false）
  ///
  /// 行为:
  /// - 从历史记录中移除
  /// - 若 deleteSessionFiles=true，同时删除会话目录及其文件
  /// - 若 ID 不存在，抛出异常
  Future<void> deleteRecord({
    required String id,
    bool deleteSessionFiles = false,
  }) async {
    try {
      final records = await loadAllRecords();

      // 查找记录
      final index = records.indexWhere((r) => r.id == id);
      if (index == -1) {
        throw ArgumentError('Record not found: $id');
      }

      final record = records[index];

      // 删除会话文件（可选）
      if (deleteSessionFiles) {
        final sessionDir = Directory(record.sessionRoot);
        if (await sessionDir.exists()) {
          await sessionDir.delete(recursive: true);
          print('[AnalysisHistory] Deleted session directory: ${record.sessionRoot}');
        }
      }

      // 从列表中移除
      records.removeAt(index);

      // 持久化
      await _saveRecords(records);

      print('[AnalysisHistory] Deleted record: $id');
    } catch (e) {
      print('[AnalysisHistory] Failed to delete record: $e');
      rethrow;
    }
  }

  /// 清空所有历史记录
  ///
  /// 行为:
  /// - 删除 analysis_history.json 文件
  /// - 用于"清除所有数据"功能
  Future<void> clearAllRecords() async {
    try {
      final filePath = await _getHistoryFilePath();
      final file = File(filePath);
      
      if (await file.exists()) {
        await file.delete();
        print('[AnalysisHistory] Cleared all records');
      }
    } catch (e) {
      print('[AnalysisHistory] Failed to clear records: $e');
      rethrow;
    }
  }

  /// 私有：持久化记录列表
  Future<void> _saveRecords(List<AnalysisRecord> records) async {
    final filePath = await _getHistoryFilePath();
    final file = File(filePath);

    // 序列化为 JSON
    final jsonList = records.map((r) => r.toJson()).toList();
    final content = jsonEncode(jsonList);

    // 写入文件
    await file.writeAsString(content, encoding: utf8);
  }
}

