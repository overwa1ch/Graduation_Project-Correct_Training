import 'package:flutter/foundation.dart';
import 'package:aiwa_app/services/auth_service.dart';

/// 认证状态管理
/// 
/// 使用 ChangeNotifier 管理全局认证状态
/// 可以在整个应用中监听认证状态的变化
/// 
/// ⚠️ 单例模式：确保整个应用共享同一个认证状态实例
class AuthState extends ChangeNotifier {
  static AuthState? _instance;
  final AuthService _authService;
  
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _userEmail;
  String? _errorMessage;

  // 私有构造函数
  AuthState._internal({AuthService? authService})
      : _authService = authService ?? AuthService();

  /// 获取单例实例
  factory AuthState({AuthService? authService}) {
    _instance ??= AuthState._internal(authService: authService);
    return _instance!;
  }

  // ========== Getters ==========

  /// 是否已认证
  bool get isAuthenticated => _isAuthenticated;

  /// 是否正在加载
  bool get isLoading => _isLoading;

  /// 当前用户邮箱
  String? get userEmail => _userEmail;

  /// 错误消息
  String? get errorMessage => _errorMessage;

  // ========== 公共方法 ==========

  /// 初始化（检查本地存储的登录状态）
  Future<void> initialize() async {
    try {
      _setLoading(true);
      
      await _authService.initialize();
      final isLoggedIn = await _authService.isLoggedIn();
      
      if (isLoggedIn) {
        _userEmail = await _authService.getCurrentUserEmail();
        _isAuthenticated = true;
        debugPrint('[AuthState] User is logged in: $_userEmail');
      } else {
        _isAuthenticated = false;
        debugPrint('[AuthState] User is not logged in');
      }
    } catch (e) {
      debugPrint('[AuthState] Initialize error: $e');
      _isAuthenticated = false;
    } finally {
      _setLoading(false);
    }
  }

  /// 用户注册
  Future<bool> register({
    required String email,
    required String password,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final result = await _authService.register(
        email: email,
        password: password,
      );

      if (result.isSuccess) {
        _isAuthenticated = true;
        _userEmail = result.email;
        debugPrint('[AuthState] Registration successful: $email');
        notifyListeners();
        return true;
      } else {
        _setError(result.error ?? 'Registration failed');
        return false;
      }
    } catch (e) {
      debugPrint('[AuthState] Registration error: $e');
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 用户登录
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final result = await _authService.login(
        email: email,
        password: password,
      );

      if (result.isSuccess) {
        _isAuthenticated = true;
        _userEmail = result.email;
        debugPrint('[AuthState] Login successful: $email');
        notifyListeners();
        return true;
      } else {
        _setError(result.error ?? 'Login failed');
        return false;
      }
    } catch (e) {
      debugPrint('[AuthState] Login error: $e');
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 刷新 Token
  Future<bool> refreshToken() async {
    try {
      debugPrint('[AuthState] Refreshing token');
      final success = await _authService.refreshAccessToken();
      
      if (!success) {
        // Token 刷新失败，登出用户
        await logout();
      }
      
      return success;
    } catch (e) {
      debugPrint('[AuthState] Refresh token error: $e');
      await logout();
      return false;
    }
  }

  /// 用户登出
  Future<void> logout() async {
    try {
      _setLoading(true);
      
      await _authService.logout();
      
      _isAuthenticated = false;
      _userEmail = null;
      _clearError();
      
      debugPrint('[AuthState] Logout successful');
      notifyListeners();
    } catch (e) {
      debugPrint('[AuthState] Logout error: $e');
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  /// 清除错误消息
  void clearError() {
    _clearError();
  }

  // ========== 私有方法 ==========

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _authService.dispose();
    super.dispose();
  }
}

