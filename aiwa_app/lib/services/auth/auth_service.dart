import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aiwa_app/services/auth/api_client.dart';
import 'package:aiwa_app/config/api_config.dart';

/// 认证服务
/// 
/// 处理用户认证相关的业务逻辑：
/// - 注册
/// - 登录
/// - Token 刷新
/// - 登出
/// - 认证状态管理
class AuthService {
  final ApiClient _apiClient;
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userEmailKey = 'user_email';

  AuthService({
    ApiClient? apiClient,
    Future<bool> Function()? on401,
  }) : _apiClient = apiClient ?? ApiClient(on401: on401);

  /// 用户注册
  /// 
  /// 参数：
  /// - email: 用户邮箱
  /// - password: 密码（至少 8 位）
  /// 
  /// 返回：成功返回 true，失败抛出异常
  Future<AuthResult> register({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('[AuthService] Registering user: $email');

      final response = await _apiClient.post(
        ApiConfig.authPrefix + '/register',
        body: {
          'email': email,
          'password': password,
        },
      );

      if (response.isSuccess) {
        final data = response.data as Map<String, dynamic>;
        final accessToken = data['token'] as String;
        final refreshToken = data['refresh_token'] as String;

        // 保存 Token
        await _saveTokens(
          accessToken: accessToken,
          refreshToken: refreshToken,
          email: email,
        );

        debugPrint('[AuthService] Registration successful');
        return AuthResult.success(email: email);
      } else {
        debugPrint('[AuthService] Registration failed: ${response.error}');
        return AuthResult.failure(error: response.error!.message);
      }
    } catch (e) {
      debugPrint('[AuthService] Registration exception: $e');
      return AuthResult.failure(error: e.toString());
    }
  }

  /// 用户登录
  /// 
  /// 参数：
  /// - email: 用户邮箱
  /// - password: 密码
  /// 
  /// 返回：成功返回 true，失败抛出异常
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('[AuthService] Logging in user: $email');

      final response = await _apiClient.post(
        ApiConfig.authPrefix + '/login',
        body: {
          'email': email,
          'password': password,
        },
      );

      if (response.isSuccess) {
        final data = response.data as Map<String, dynamic>;
        final accessToken = data['token'] as String;
        final refreshToken = data['refresh_token'] as String;

        // 保存 Token
        await _saveTokens(
          accessToken: accessToken,
          refreshToken: refreshToken,
          email: email,
        );

        debugPrint('[AuthService] Login successful');
        return AuthResult.success(email: email);
      } else {
        debugPrint('[AuthService] Login failed: ${response.error}');
        return AuthResult.failure(error: response.error!.message);
      }
    } catch (e) {
      debugPrint('[AuthService] Login exception: $e');
      return AuthResult.failure(error: e.toString());
    }
  }

  /// 刷新访问令牌
  /// 
  /// 使用 refresh_token 获取新的 access_token
  Future<bool> refreshAccessToken() async {
    try {
      final refreshToken = await _getRefreshToken();
      if (refreshToken == null) {
        debugPrint('[AuthService] No refresh token available');
        return false;
      }

      debugPrint('[AuthService] Refreshing access token');

      final response = await _apiClient.post(
        ApiConfig.authPrefix + '/refresh',
        body: {
          'refresh_token': refreshToken,
        },
      );

      if (response.isSuccess) {
        final data = response.data as Map<String, dynamic>;
        final newAccessToken = data['token'] as String;

        // 更新访问令牌
        await _saveAccessToken(newAccessToken);
        _apiClient.setAccessToken(newAccessToken);

        debugPrint('[AuthService] Token refreshed successfully');
        return true;
      } else {
        debugPrint('[AuthService] Token refresh failed: ${response.error}');
        return false;
      }
    } catch (e) {
      debugPrint('[AuthService] Token refresh exception: $e');
      return false;
    }
  }

  /// 登出
  /// 
  /// 清除本地存储的所有认证信息
  Future<void> logout() async {
    try {
      debugPrint('[AuthService] Logging out');

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_accessTokenKey);
      await prefs.remove(_refreshTokenKey);
      await prefs.remove(_userEmailKey);

      _apiClient.setAccessToken(null);

      debugPrint('[AuthService] Logout successful');
    } catch (e) {
      debugPrint('[AuthService] Logout exception: $e');
      rethrow;
    }
  }

  /// 检查是否已登录
  /// 
  /// 返回：已登录返回 true，否则返回 false
  Future<bool> isLoggedIn() async {
    try {
      final accessToken = await _getAccessToken();
      return accessToken != null;
    } catch (e) {
      debugPrint('[AuthService] Check login status exception: $e');
      return false;
    }
  }

  /// 获取当前用户邮箱
  Future<String?> getCurrentUserEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_userEmailKey);
    } catch (e) {
      debugPrint('[AuthService] Get user email exception: $e');
      return null;
    }
  }

  /// 初始化（从本地存储恢复 Token）
  Future<void> initialize() async {
    try {
      final accessToken = await _getAccessToken();
      if (accessToken != null) {
        _apiClient.setAccessToken(accessToken);
        debugPrint('[AuthService] Initialized with existing token');
      } else {
        debugPrint('[AuthService] Initialized without token');
      }
    } catch (e) {
      debugPrint('[AuthService] Initialize exception: $e');
    }
  }

  // ========== 私有方法 ==========

  /// 保存 Token
  Future<void> _saveTokens({
    required String accessToken,
    required String refreshToken,
    required String email,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, accessToken);
    await prefs.setString(_refreshTokenKey, refreshToken);
    await prefs.setString(_userEmailKey, email);

    // 同时设置到 API 客户端
    _apiClient.setAccessToken(accessToken);
  }

  /// 保存访问令牌
  Future<void> _saveAccessToken(String accessToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, accessToken);
  }

  /// 获取访问令牌
  Future<String?> _getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }

  /// 获取刷新令牌
  Future<String?> _getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  /// 释放资源
  void dispose() {
    _apiClient.dispose();
  }
}

/// 认证结果
class AuthResult {
  final bool isSuccess;
  final String? email;
  final String? error;

  AuthResult._({
    required this.isSuccess,
    this.email,
    this.error,
  });

  factory AuthResult.success({required String email}) {
    return AuthResult._(
      isSuccess: true,
      email: email,
    );
  }

  factory AuthResult.failure({required String error}) {
    return AuthResult._(
      isSuccess: false,
      error: error,
    );
  }
}

