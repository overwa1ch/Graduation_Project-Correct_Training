import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';

/// Configuration Sync Service
/// 
/// ⚠️ BOUNDARY RULE: This service handles ONLY business configuration data.
/// It does NOT handle theme/styling. Themes are handled by lib/theme/.
/// 
/// This service loads and saves:
/// - threshold_profile: "strict" | "relaxed" | "custom"
/// - engine: "mlkit" | "movenet"
/// - cloud_enabled: boolean
/// - other business logic toggles
/// 
/// UI components read this config to DECIDE what to display,
/// but colors/styles come from Theme or SemanticColors.

class ConfigSnapshot {
  final String thresholdProfile;  // "strict" | "relaxed" | "custom"
  final String engine;            // "mlkit" | "movenet"
  final bool cloudEnabled;
  final Map<String, dynamic> customThresholds;
  final Map<String, dynamic> rawData;

  const ConfigSnapshot({
    required this.thresholdProfile,
    required this.engine,
    required this.cloudEnabled,
    this.customThresholds = const {},
    this.rawData = const {},
  });

  factory ConfigSnapshot.fromJson(Map<String, dynamic> json) {
    return ConfigSnapshot(
      thresholdProfile: json['threshold_profile'] as String? ?? 'relaxed',
      engine: json['engine'] as String? ?? 'mlkit',
      cloudEnabled: json['cloud_enabled'] as bool? ?? false,
      customThresholds: json['custom_thresholds'] as Map<String, dynamic>? ?? {},
      rawData: json,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'threshold_profile': thresholdProfile,
      'engine': engine,
      'cloud_enabled': cloudEnabled,
      'custom_thresholds': customThresholds,
      ...rawData,
    };
  }

  ConfigSnapshot copyWith({
    String? thresholdProfile,
    String? engine,
    bool? cloudEnabled,
    Map<String, dynamic>? customThresholds,
  }) {
    return ConfigSnapshot(
      thresholdProfile: thresholdProfile ?? this.thresholdProfile,
      engine: engine ?? this.engine,
      cloudEnabled: cloudEnabled ?? this.cloudEnabled,
      customThresholds: customThresholds ?? this.customThresholds,
      rawData: rawData,
    );
  }

  @override
  String toString() {
    return 'ConfigSnapshot(profile: $thresholdProfile, engine: $engine, cloud: $cloudEnabled)';
  }
}

class ConfigSyncService {
  static const String _defaultConfigPath = 'assets/default_config.json';
  
  ConfigSnapshot? _currentConfig;
  
  /// Get current configuration snapshot
  ConfigSnapshot? get current => _currentConfig;
  
  /// Load configuration from assets (default) or file system
  /// Returns the loaded configuration snapshot
  Future<ConfigSnapshot> loadConfig({String? customPath}) async {
    try {
      String jsonString;
      
      if (customPath != null) {
        // Load from file system (for saved user configs)
        final file = File(customPath);
        if (await file.exists()) {
          jsonString = await file.readAsString();
        } else {
          // Fallback to default if custom path doesn't exist
          jsonString = await rootBundle.loadString(_defaultConfigPath);
        }
      } else {
        // Load from assets (default config)
        jsonString = await rootBundle.loadString(_defaultConfigPath);
      }
      
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      _currentConfig = ConfigSnapshot.fromJson(json);
      
      return _currentConfig!;
    } catch (e) {
      // If loading fails, return a safe default
      _currentConfig = const ConfigSnapshot(
        thresholdProfile: 'relaxed',
        engine: 'mlkit',
        cloudEnabled: false,
      );
      return _currentConfig!;
    }
  }
  
  /// Save configuration to file system
  /// Returns true if save was successful
  Future<bool> saveConfig(ConfigSnapshot config, String outputPath) async {
    try {
      final file = File(outputPath);
      final directory = file.parent;
      
      // Create directory if it doesn't exist
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      
      // Write config as pretty JSON
      final jsonString = const JsonEncoder.withIndent('  ').convert(config.toJson());
      await file.writeAsString(jsonString);
      
      _currentConfig = config;
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// Update specific fields in current config and optionally save
  Future<ConfigSnapshot> updateConfig({
    String? thresholdProfile,
    String? engine,
    bool? cloudEnabled,
    Map<String, dynamic>? customThresholds,
    bool saveToFile = false,
    String? savePath,
  }) async {
    if (_currentConfig == null) {
      await loadConfig();
    }
    
    final updatedConfig = _currentConfig!.copyWith(
      thresholdProfile: thresholdProfile,
      engine: engine,
      cloudEnabled: cloudEnabled,
      customThresholds: customThresholds,
    );
    
    if (saveToFile && savePath != null) {
      await saveConfig(updatedConfig, savePath);
    } else {
      _currentConfig = updatedConfig;
    }
    
    return updatedConfig;
  }
  
  /// Reset to default configuration
  Future<ConfigSnapshot> resetToDefault() async {
    return await loadConfig();
  }
}

