import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:aiwa_app/config/api_config.dart';

/// API 客户端
/// 
/// 封装所有 HTTP 请求，提供统一的错误处理和请求/响应拦截
class ApiClient {
  final http.Client _client;
  String? _accessToken;

  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  /// 设置访问令牌
  void setAccessToken(String? token) {
    _accessToken = token;
  }

  /// 获取当前访问令牌
  String? get accessToken => _accessToken;

  /// 构建请求头
  Map<String, String> _buildHeaders({Map<String, String>? additionalHeaders}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    // 添加访问令牌（如果存在）
    if (_accessToken != null) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }

    // 添加额外的请求头
    if (additionalHeaders != null) {
      headers.addAll(additionalHeaders);
    }

    return headers;
  }

  /// POST 请求
  Future<ApiResponse> post(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      final response = await _client
          .post(
            uri,
            headers: _buildHeaders(additionalHeaders: headers),
            body: body != null ? json.encode(body) : null,
          )
          .timeout(Duration(seconds: ApiConfig.timeoutSeconds));

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse.error(_handleException(e));
    }
  }

  /// GET 请求
  Future<ApiResponse> get(
    String endpoint, {
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
  }) async {
    try {
      var uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      if (queryParameters != null) {
        uri = uri.replace(queryParameters: queryParameters);
      }

      final response = await _client
          .get(
            uri,
            headers: _buildHeaders(additionalHeaders: headers),
          )
          .timeout(Duration(seconds: ApiConfig.timeoutSeconds));

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse.error(_handleException(e));
    }
  }

  /// 处理响应
  ApiResponse _handleResponse(http.Response response) {
    final statusCode = response.statusCode;
    final body = response.body;

    // 尝试解析 JSON
    dynamic data;
    try {
      data = json.decode(body);
    } catch (_) {
      data = body;
    }

    if (statusCode >= 200 && statusCode < 300) {
      // 成功响应
      return ApiResponse.success(data);
    } else {
      // 错误响应
      String errorMessage = 'Request failed with status: $statusCode';
      String? errorCode;

      if (data is Map<String, dynamic>) {
        if (data.containsKey('error')) {
          final error = data['error'];
          if (error is Map<String, dynamic>) {
            errorMessage = (error['message'] as String?) ?? errorMessage;
            errorCode = error['code'] as String?;
          } else if (error is String) {
            errorMessage = error;
          }
        } else if (data.containsKey('message')) {
          errorMessage = (data['message'] as String?) ?? errorMessage;
        }
      }

      return ApiResponse.error(
        ApiError(
          message: errorMessage,
          statusCode: statusCode,
          code: errorCode,
        ),
      );
    }
  }

  /// 处理异常
  ApiError _handleException(dynamic exception) {
    String message = 'An unexpected error occurred';

    if (exception is http.ClientException) {
      message = 'Network error: Unable to connect to server';
    } else if (exception.toString().contains('TimeoutException')) {
      message = 'Request timeout: Server took too long to respond';
    } else {
      message = exception.toString();
    }

    return ApiError(message: message);
  }

  /// 关闭客户端
  void dispose() {
    _client.close();
  }
}

/// API 响应包装类
class ApiResponse {
  final bool isSuccess;
  final dynamic data;
  final ApiError? error;

  ApiResponse._({
    required this.isSuccess,
    this.data,
    this.error,
  });

  factory ApiResponse.success(dynamic data) {
    return ApiResponse._(
      isSuccess: true,
      data: data,
    );
  }

  factory ApiResponse.error(ApiError error) {
    return ApiResponse._(
      isSuccess: false,
      error: error,
    );
  }
}

/// API 错误类
class ApiError {
  final String message;
  final int? statusCode;
  final String? code;

  ApiError({
    required this.message,
    this.statusCode,
    this.code,
  });

  @override
  String toString() {
    if (code != null) {
      return '$code: $message';
    }
    return message;
  }
}

