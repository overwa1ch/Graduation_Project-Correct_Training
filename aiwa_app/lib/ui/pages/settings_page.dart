import 'package:flutter/material.dart';
import 'package:aiwa_app/theme/spacing.dart';
import 'package:aiwa_app/theme/colors.dart';
import 'package:aiwa_app/ui/app_shell.dart';
import 'package:aiwa_app/services/config_sync.dart';
import 'package:aiwa_app/services/session_manager.dart';

/// SettingsPage
/// 
/// 设置页面：按照 Figma 设计稿实现
/// 包含用户卡片、分析阈值、分析引擎、数据管理、登出按钮
/// 
/// ⚠️ 本版本实现配置双向同步：Settings 表单 ↔ app_runtime.json

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // 配置加载状态
  bool _isLoading = true;
  bool _isSaving = false;
  
  // 表单字段
  int _thresholdMode = 0;                    // 0=Relaxed, 1=Strict
  int _engineMode = 0;                       // 0=MLKit, 1=MoveNet, 2=MediaPipe, 3=Auto
  bool _cloudBackupEnabled = false;          // privacy.upload: video+keypoints
  bool _confirmVideoUpload = true;           // privacy.confirmVideoUpload
  
  // 文本字段控制器
  final _strideController = TextEditingController(text: '2');
  final _targetFpsController = TextEditingController(text: '30');
  final _resolutionController = TextEditingController(text: '1280x720');
  final _cleanupDaysController = TextEditingController(text: '7');
  
  // 日志级别：0=info, 1=debug, 2=warning, 3=error
  int _logLevel = 0;
  
  // 校验错误
  String? _strideError;
  String? _targetFpsError;
  String? _resolutionError;
  String? _cleanupDaysError;
  
  // 变更检测
  bool _hasChanges = false;
  Map<String, dynamic>? _originalConfig;

  @override
  void dispose() {
    _strideController.dispose();
    _targetFpsController.dispose();
    _resolutionController.dispose();
    _cleanupDaysController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  /// 加载配置
  Future<void> _loadConfig() async {
    try {
      setState(() => _isLoading = true);
      
      final cfg = await readAppRuntimeConfig();
      _originalConfig = Map<String, dynamic>.from(cfg);
      
      debugPrint('[Settings] Loaded config: $cfg');
      
      // 映射 strictness
      final strictness = cfg['strictness'] as String?;
      _thresholdMode = (strictness == 'strict') ? 1 : 0;
      
      // 映射 engine
      final engine = cfg['engine'] as String?;
      _engineMode = _engineToIndex(engine ?? 'MoveNet');
      
      // 映射 stride
      final stride = cfg['stride'] as int? ?? 2;
      _strideController.text = stride.toString();
      
      // 映射 targetFps
      final targetFps = cfg['targetFps'] as int? ?? 30;
      _targetFpsController.text = targetFps.toString();
      
      // 映射 resolution
      final resolution = cfg['resolution'] as String? ?? '1280x720';
      _resolutionController.text = resolution;
      
      // 映射 privacy
      final privacy = cfg['privacy'] as Map<String, dynamic>?;
      final upload = privacy?['upload'] as String?;
      _cloudBackupEnabled = (upload == 'video+keypoints');
      _confirmVideoUpload = privacy?['confirmVideoUpload'] as bool? ?? true;
      
      // 映射 cleanup.days
      final cleanup = cfg['cleanup'] as Map<String, dynamic>?;
      final days = cleanup?['days'] as int? ?? 7;
      _cleanupDaysController.text = days.toString();
      
      // 映射 logs.level
      final logs = cfg['logs'] as Map<String, dynamic>?;
      final level = logs?['level'] as String? ?? 'info';
      _logLevel = _logLevelToIndex(level);
      
      setState(() {
        _isLoading = false;
        _hasChanges = false;
      });
    } catch (e) {
      debugPrint('[Settings] Failed to load config: $e');
      setState(() => _isLoading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load settings: $e'),
            backgroundColor: AppColors.surfaceSecondary,
          ),
        );
      }
    }
  }

  /// 保存配置
  Future<void> _saveConfig() async {
    if (_isSaving) return;
    
    // 轻量校验
    if (!_validateAll()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请修正表单错误后再保存'),
          backgroundColor: AppColors.surfaceSecondary,
        ),
      );
      return;
    }
    
    try {
      setState(() => _isSaving = true);
      
      // 构建表单数据
      final formData = <String, dynamic>{
        'engine': _indexToEngine(_engineMode),
        'strictness': _thresholdMode == 1 ? 'strict' : 'relaxed',
        'stride': int.parse(_strideController.text),
        'targetFps': int.parse(_targetFpsController.text),
        'resolution': _resolutionController.text.trim(),
        'privacy': {
          'upload': _cloudBackupEnabled ? 'video+keypoints' : 'keypoints-only',
          'confirmVideoUpload': _confirmVideoUpload,
        },
        'cleanup': {
          'days': int.parse(_cleanupDaysController.text),
        },
        'logs': {
          'level': _indexToLogLevel(_logLevel),
        },
      };
      
      debugPrint('[Settings] Saving config: $formData');
      
      // 写入配置
      await writeAppRuntimeConfig(formData);
      
      // 更新原始配置
      _originalConfig = Map<String, dynamic>.from(formData);
      
      setState(() {
        _isSaving = false;
        _hasChanges = false;
      });
      
      debugPrint('[Settings] Config saved to: configs/app_runtime.json');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('已保存，下次分析生效'),
            backgroundColor: AppColors.brandPrimaryVariant,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('[Settings] Failed to save config: $e');
      setState(() => _isSaving = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存失败: $e'),
            backgroundColor: AppColors.surfaceSecondary,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// 恢复默认配置
  void _resetToDefaults() {
    setState(() {
      _thresholdMode = 1; // strict
      _engineMode = 1; // MoveNet
      _strideController.text = '2';
      _targetFpsController.text = '30';
      _resolutionController.text = '1280x720';
      _cloudBackupEnabled = false;
      _confirmVideoUpload = true;
      _cleanupDaysController.text = '7';
      _logLevel = 0; // info
      _hasChanges = true;
      
      // 清除错误
      _strideError = null;
      _targetFpsError = null;
      _resolutionError = null;
      _cleanupDaysError = null;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('已恢复默认值，请点击保存以应用'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// 检测变更
  void _detectChanges() {
    if (_originalConfig == null) return;
    
    final hasChanges = 
        _thresholdMode != (_originalConfig!['strictness'] == 'strict' ? 1 : 0) ||
        _engineMode != _engineToIndex(_originalConfig!['engine'] as String? ?? 'MoveNet') ||
        _strideController.text != (_originalConfig!['stride']?.toString() ?? '2') ||
        _targetFpsController.text != (_originalConfig!['targetFps']?.toString() ?? '30') ||
        _resolutionController.text != (_originalConfig!['resolution'] ?? '1280x720') ||
        _cloudBackupEnabled != ((_originalConfig!['privacy'] as Map?)?['upload'] == 'video+keypoints') ||
        _confirmVideoUpload != ((_originalConfig!['privacy'] as Map?)?['confirmVideoUpload'] ?? true) ||
        _cleanupDaysController.text != ((_originalConfig!['cleanup'] as Map?)?['days']?.toString() ?? '7') ||
        _logLevel != _logLevelToIndex((_originalConfig!['logs'] as Map?)?['level'] as String? ?? 'info');
    
    if (hasChanges != _hasChanges) {
      setState(() => _hasChanges = hasChanges);
    }
  }

  /// 全量校验
  bool _validateAll() {
    _validateStride(_strideController.text);
    _validateTargetFps(_targetFpsController.text);
    _validateResolution(_resolutionController.text);
    _validateCleanupDays(_cleanupDaysController.text);
    
    return _strideError == null &&
           _targetFpsError == null &&
           _resolutionError == null &&
           _cleanupDaysError == null;
  }

  /// 校验 stride
  void _validateStride(String value) {
    setState(() {
      if (value.isEmpty) {
        _strideError = '步长不能为空';
      } else {
        final num = int.tryParse(value);
        if (num == null) {
          _strideError = '必须是整数';
        } else if (num < 1) {
          _strideError = '步长必须 ≥ 1';
        } else {
          _strideError = null;
        }
      }
    });
  }

  /// 校验 targetFps
  void _validateTargetFps(String value) {
    setState(() {
      if (value.isEmpty) {
        _targetFpsError = '帧率不能为空';
      } else {
        final num = int.tryParse(value);
        if (num == null) {
          _targetFpsError = '必须是整数';
        } else if (num < 1) {
          _targetFpsError = '帧率必须 ≥ 1';
        } else {
          _targetFpsError = null;
        }
      }
    });
  }

  /// 校验 resolution
  void _validateResolution(String value) {
    setState(() {
      if (value.isEmpty) {
        _resolutionError = '分辨率不能为空';
      } else {
        final pattern = RegExp(r'^\d{3,4}x\d{3,4}$');
        if (!pattern.hasMatch(value)) {
          _resolutionError = '格式: 1280x720';
        } else {
          _resolutionError = null;
        }
      }
    });
  }

  /// 校验 cleanup days
  void _validateCleanupDays(String value) {
    setState(() {
      if (value.isEmpty) {
        _cleanupDaysError = '天数不能为空';
      } else {
        final num = int.tryParse(value);
        if (num == null) {
          _cleanupDaysError = '必须是整数';
        } else if (num < 0) {
          _cleanupDaysError = '天数必须 ≥ 0';
        } else {
          _cleanupDaysError = null;
        }
      }
    });
  }

  /// 清理历史会话
  Future<void> _cleanupSessions() async {
    try {
      await SessionManager.cleanupExpired(days: 7);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Local data cleaned up successfully!'),
            backgroundColor: AppColors.brandPrimaryVariant,
          ),
        );
      }
    } catch (e) {
      debugPrint('[Settings] Failed to cleanup sessions: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cleanup: $e'),
            backgroundColor: AppColors.surfaceSecondary,
          ),
        );
      }
    }
  }

  /// 引擎名称转索引
  int _engineToIndex(String engine) {
    switch (engine) {
      case 'MLKit':
        return 0;
      case 'MoveNet':
        return 1;
      case 'MediaPipe':
        return 2;
      case 'Auto':
        return 3;
      default:
        return 1; // 默认 MoveNet
    }
  }

  /// 索引转引擎名称
  String _indexToEngine(int index) {
    switch (index) {
      case 0:
        return 'MLKit';
      case 1:
        return 'MoveNet';
      case 2:
        return 'MediaPipe';
      case 3:
        return 'Auto';
      default:
        return 'MoveNet';
    }
  }

  /// 日志级别转索引
  int _logLevelToIndex(String level) {
    switch (level.toLowerCase()) {
      case 'info':
        return 0;
      case 'debug':
        return 1;
      case 'warning':
        return 2;
      case 'error':
        return 3;
      default:
        return 0;
    }
  }

  /// 索引转日志级别
  String _indexToLogLevel(int index) {
    switch (index) {
      case 0:
        return 'info';
      case 1:
        return 'debug';
      case 2:
        return 'warning';
      case 3:
        return 'error';
      default:
        return 'info';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppShell(
      title: 'Settings',
      currentNavIndex: 2,
      child: Container(
        color: AppColors.surfacePrimary,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: PageContainer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: AppSpacing.md),
                      
                      // 用户信息卡片
                      _buildUserCard(context),
                      
                      SizedBox(height: AppSpacing.xl),
                      
                      // Analysis Threshold
                      _buildAnalysisThreshold(theme),
                      
                      SizedBox(height: AppSpacing.xl),
                      
                      // Analysis Engine
                      _buildAnalysisEngine(theme),
                      
                      SizedBox(height: AppSpacing.xl),
                      
                      // Performance Settings
                      _buildPerformanceSettings(theme),
                      
                      SizedBox(height: AppSpacing.xl),
                      
                      // Data Management
                      _buildDataManagement(theme),
                      
                      SizedBox(height: AppSpacing.xl),
                      
                      // Advanced Settings
                      _buildAdvancedSettings(theme),
                      
                      SizedBox(height: AppSpacing.xl),
                      
                      // 按钮组
                      Row(
                        children: [
                          // 恢复默认按钮
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _isSaving ? null : _resetToDefaults,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.textInvert,
                                side: BorderSide(color: AppColors.neutralLight),
                                padding: EdgeInsets.symmetric(
                                  vertical: AppSpacing.lg,
                                ),
                              ),
                              child: const Text('恢复默认'),
                            ),
                          ),
                          
                          SizedBox(width: AppSpacing.md),
                          
                          // 保存按钮
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: (_isSaving || !_hasChanges) ? null : _saveConfig,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.brandPrimaryVariant,
                                foregroundColor: AppColors.textInvert,
                                padding: EdgeInsets.symmetric(
                                  vertical: AppSpacing.lg,
                                ),
                              ),
                              child: _isSaving
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.textPrimary),
                                      ),
                                    )
                                  : const Text('保存设置'),
                            ),
                          ),
                        ],
                      ),
                      
                      SizedBox(height: AppSpacing.xxl),
                      
                      // 登出按钮
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pushReplacementNamed(
                              context, 
                              '/welcome',
                              arguments: {'noAnimation': true},
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textInvert,
                            side: BorderSide(color: AppColors.brandPrimaryVariant),
                            padding: EdgeInsets.symmetric(
                              vertical: AppSpacing.lg,
                            ),
                          ),
                          child: const Text('退出登录'),
                        ),
                      ),
                
                      SizedBox(height: AppSpacing.xxl),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
  
  /// 构建 Analysis Threshold 板块
  Widget _buildAnalysisThreshold(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: AppRadius.cardRadius,
      ),
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Analysis Threshold',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          
          SizedBox(height: AppSpacing.lg),
          
          // Relaxed / Strict 按钮
          Row(
            children: [
              Expanded(
                child: _buildToggleButton(
                  label: 'Relaxed',
                  isSelected: _thresholdMode == 0,
                  onTap: () {
                    setState(() {
                      _thresholdMode = 0;
                      _detectChanges();
                    });
                  },
                ),
              ),
              SizedBox(width: AppSpacing.lg),
              Expanded(
                child: _buildToggleButton(
                  label: 'Strict',
                  isSelected: _thresholdMode == 1,
                  onTap: () {
                    setState(() {
                      _thresholdMode = 1;
                      _detectChanges();
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  /// 构建 Analysis Engine 板块
  Widget _buildAnalysisEngine(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: AppRadius.cardRadius,
      ),
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Analysis Engine',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          
          SizedBox(height: AppSpacing.md),
          
          // MLKit 选项
          _buildRadioOption(
            label: 'MLKit',
            isSelected: _engineMode == 0,
            onTap: () {
              setState(() {
                _engineMode = 0;
                _detectChanges();
              });
            },
          ),
          
          SizedBox(height: AppSpacing.sm),
          
          // MoveNet 选项
          _buildRadioOption(
            label: 'MoveNet',
            isSelected: _engineMode == 1,
            onTap: () {
              setState(() {
                _engineMode = 1;
                _detectChanges();
              });
            },
          ),
          
          SizedBox(height: AppSpacing.sm),
          
          // MediaPipe 选项
          _buildRadioOption(
            label: 'MediaPipe',
            isSelected: _engineMode == 2,
            onTap: () {
              setState(() {
                _engineMode = 2;
                _detectChanges();
              });
            },
          ),
          
          SizedBox(height: AppSpacing.sm),
          
          // Auto 选项
          _buildRadioOption(
            label: 'Auto',
            isSelected: _engineMode == 3,
            onTap: () {
              setState(() {
                _engineMode = 3;
                _detectChanges();
              });
            },
          ),
        ],
      ),
    );
  }
  
  /// 构建 Performance Settings 板块
  Widget _buildPerformanceSettings(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: AppRadius.cardRadius,
      ),
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Performance Settings',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          
          SizedBox(height: AppSpacing.lg),
          
          // Stride（步长）
          TextField(
            controller: _strideController,
            keyboardType: TextInputType.number,
            style: TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              labelText: 'Stride (步长)',
              helperText: '推理时跳帧数，必须 ≥ 1',
              errorText: _strideError,
              border: OutlineInputBorder(),
              labelStyle: TextStyle(color: AppColors.textPrimary),
            ),
            onChanged: (value) {
              _validateStride(value);
              _detectChanges();
            },
          ),
          
          SizedBox(height: AppSpacing.lg),
          
          // Target FPS（目标帧率）
          TextField(
            controller: _targetFpsController,
            keyboardType: TextInputType.number,
            style: TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              labelText: 'Target FPS (目标帧率)',
              helperText: '推理目标帧率，必须 ≥ 1',
              errorText: _targetFpsError,
              border: OutlineInputBorder(),
              labelStyle: TextStyle(color: AppColors.textPrimary),
            ),
            onChanged: (value) {
              _validateTargetFps(value);
              _detectChanges();
            },
          ),
          
          SizedBox(height: AppSpacing.lg),
          
          // Resolution（分辨率）
          TextField(
            controller: _resolutionController,
            style: TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              labelText: 'Resolution (分辨率)',
              helperText: '格式: 1280x720',
              errorText: _resolutionError,
              border: OutlineInputBorder(),
              labelStyle: TextStyle(color: AppColors.textPrimary),
            ),
            onChanged: (value) {
              _validateResolution(value);
              _detectChanges();
            },
          ),
        ],
      ),
    );
  }
  
  /// 构建 Data Management 板块
  Widget _buildDataManagement(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: AppRadius.cardRadius,
      ),
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Data Management',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          
          SizedBox(height: AppSpacing.lg),
          
          // Cloud Backup & Sync 开关
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Upload Video (上传视频)',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppColors.textPrimary,
                  ),
                ),
              ),
              Switch(
                value: _cloudBackupEnabled,
                onChanged: (value) {
                  setState(() {
                    _cloudBackupEnabled = value;
                    _detectChanges();
                  });
                },
              ),
            ],
          ),
          
          SizedBox(height: AppSpacing.md),
          
          // Confirm Video Upload 开关
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Confirm Before Upload (上传前确认)',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Switch(
                value: _confirmVideoUpload,
                onChanged: (value) {
                  setState(() {
                    _confirmVideoUpload = value;
                    _detectChanges();
                  });
                },
              ),
            ],
          ),
          
          SizedBox(height: AppSpacing.lg),
          
          // Cleanup Days (清理天数)
          TextField(
            controller: _cleanupDaysController,
            keyboardType: TextInputType.number,
            style: TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              labelText: 'Cleanup Days (清理天数)',
              helperText: '保留最近 N 天的会话，必须 ≥ 0',
              errorText: _cleanupDaysError,
              border: OutlineInputBorder(),
              labelStyle: TextStyle(color: AppColors.textPrimary),
            ),
            onChanged: (value) {
              _validateCleanupDays(value);
              _detectChanges();
            },
          ),
          
          SizedBox(height: AppSpacing.lg),
          
          // Clear Local Data 按钮
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _cleanupSessions,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandPrimaryVariant,
                foregroundColor: AppColors.textInvert,
                padding: EdgeInsets.symmetric(
                  vertical: AppSpacing.md,
                ),
              ),
              child: const Text('Clear Local Data'),
            ),
          ),
        ],
      ),
    );
  }
  
  /// 构建 Advanced Settings 板块
  Widget _buildAdvancedSettings(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: AppRadius.cardRadius,
      ),
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Advanced Settings',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          
          SizedBox(height: AppSpacing.lg),
          
          Text(
            'Log Level (日志级别)',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          
          SizedBox(height: AppSpacing.md),
          
          // Info
          _buildRadioOption(
            label: 'Info',
            isSelected: _logLevel == 0,
            onTap: () {
              setState(() {
                _logLevel = 0;
                _detectChanges();
              });
            },
          ),
          
          SizedBox(height: AppSpacing.sm),
          
          // Debug
          _buildRadioOption(
            label: 'Debug',
            isSelected: _logLevel == 1,
            onTap: () {
              setState(() {
                _logLevel = 1;
                _detectChanges();
              });
            },
          ),
          
          SizedBox(height: AppSpacing.sm),
          
          // Warning
          _buildRadioOption(
            label: 'Warning',
            isSelected: _logLevel == 2,
            onTap: () {
              setState(() {
                _logLevel = 2;
                _detectChanges();
              });
            },
          ),
          
          SizedBox(height: AppSpacing.sm),
          
          // Error
          _buildRadioOption(
            label: 'Error',
            isSelected: _logLevel == 3,
            onTap: () {
              setState(() {
                _logLevel = 3;
                _detectChanges();
              });
            },
          ),
        ],
      ),
    );
  }
  
  /// 构建切换按钮（Relaxed/Strict）
  Widget _buildToggleButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.buttonRadius,
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brandPrimaryVariant : Colors.transparent,
          borderRadius: AppRadius.buttonRadius,
          border: Border.all(
            color: isSelected ? AppColors.brandPrimaryVariant : AppColors.neutralLight,
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? AppColors.textInvert : AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
  
  /// 构建单选选项（ML Kit/MoveNet）
  Widget _buildRadioOption({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? AppColors.brandPrimaryVariant : AppColors.textPrimary,
                width: 2,
              ),
            ),
            child: isSelected
                ? Center(
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.brandPrimaryVariant,
                      ),
                    ),
                  )
                : null,
          ),
          SizedBox(width: AppSpacing.md),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建用户信息卡片
  Widget _buildUserCard(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            // 头像
            CircleAvatar(
              radius: 32,
              backgroundColor: theme.colorScheme.primary,
              child: Icon(
                Icons.person,
                size: 36,
                color: theme.colorScheme.onPrimary,
              ),
            ),
            SizedBox(width: AppSpacing.lg),
            
            // 用户信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '训练者',
                    style: theme.textTheme.titleLarge,
                  ),
                  SizedBox(height: AppSpacing.xs),
                  Text(
                    'user@example.com',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            
            // 编辑按钮
            IconButton(
              onPressed: () {
                // 编辑个人信息（占位）
              },
              icon: const Icon(Icons.edit),
              // ✅ 样式来自 theme
            ),
          ],
        ),
      ),
    );
  }
}



