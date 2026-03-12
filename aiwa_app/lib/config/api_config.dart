/// API Configuration
/// 
/// 配置后端 API 的基础 URL
/// 支持本地开发、模拟器和生产环境

class ApiConfig {
  ApiConfig._();

  /// 基础 URL（需与 core-api 的 PORT 一致）
  /// 
  /// 开发环境选项：
  /// - 真机 USB 调试: http://127.0.0.1:3002（需先执行 adb reverse tcp:3002 tcp:3002）
  /// - 本地/模拟器: http://localhost:3002 或 http://10.0.2.2:3002
  /// - 真机 WiFi: http://<电脑局域网IP>:3002
  /// 
  /// 生产环境：配置为云端地址
  static const String baseUrl = 'http://127.0.0.1:3002';
  
  /// API 版本前缀
  static const String apiVersion = '/v1';
  
  /// 认证端点
  static const String authPrefix = '$apiVersion/auth';
  
  /// 完整的认证端点
  static String get registerUrl => '$baseUrl$authPrefix/register';
  static String get loginUrl => '$baseUrl$authPrefix/login';
  static String get refreshUrl => '$baseUrl$authPrefix/refresh';
  
  /// 请求超时时间（秒）
  /// 真机/弱网环境适当放宽，避免局域网首次连接慢导致超时
  static const int timeoutSeconds = 60;
  
  /// 获取电脑 IP 的命令（用于真机测试）
  /// Windows: ipconfig | findstr IPv4
  /// Mac/Linux: ifconfig | grep inet
  static const String ipConfigHint = '''
真机测试时，需要使用电脑的局域网 IP：
Windows: ipconfig | findstr IPv4
Mac/Linux: ifconfig | grep inet

然后将 baseUrl 改为: http://<电脑IP>:3002
''';
}

