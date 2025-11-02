/// API Configuration
/// 
/// 配置后端 API 的基础 URL
/// 支持本地开发、模拟器和生产环境

class ApiConfig {
  ApiConfig._();

  /// 基础 URL
  /// 
  /// 开发环境选项：
  /// - 本地开发: http://localhost:8080
  /// - Android 模拟器: http://10.0.2.2:8080
  /// - iOS 模拟器: http://localhost:8080
  /// - 真机: http://<电脑IP>:8080
  /// 
  /// 生产环境：配置为云端地址
  static const String baseUrl = 'http://localhost:8080';
  
  /// API 版本前缀
  static const String apiVersion = '/v1';
  
  /// 认证端点
  static const String authPrefix = '$apiVersion/auth';
  
  /// 完整的认证端点
  static String get registerUrl => '$baseUrl$authPrefix/register';
  static String get loginUrl => '$baseUrl$authPrefix/login';
  static String get refreshUrl => '$baseUrl$authPrefix/refresh';
  
  /// 请求超时时间（秒）
  static const int timeoutSeconds = 30;
  
  /// 获取电脑 IP 的命令（用于真机测试）
  /// Windows: ipconfig | findstr IPv4
  /// Mac/Linux: ifconfig | grep inet
  static const String ipConfigHint = '''
真机测试时，需要使用电脑的局域网 IP：
Windows: ipconfig | findstr IPv4
Mac/Linux: ifconfig | grep inet

然后将 baseUrl 改为: http://<电脑IP>:8080
''';
}

