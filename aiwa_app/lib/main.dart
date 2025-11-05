import 'package:flutter/material.dart';
import 'package:aiwa_app/theme/theme.dart';
import 'package:aiwa_app/ui/pages/welcome_page.dart';
import 'package:aiwa_app/ui/pages/home_page.dart';
import 'package:aiwa_app/ui/pages/camera_page.dart';
import 'package:aiwa_app/ui/pages/settings_page.dart';
import 'package:aiwa_app/ui/pages/login_page.dart';
import 'package:aiwa_app/ui/pages/register_page.dart';
import 'package:aiwa_app/services/auth_state.dart';

// 测试阶段可关闭登录拦截
const bool kDisableAuthForTesting = true;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (!kDisableAuthForTesting) {
    // 初始化认证状态
    final authState = AuthState();
    await authState.initialize();
    runApp(MyApp(authState: authState));
  } else {
    // 测试时无需初始化认证
    runApp(MyApp(authState: AuthState()));
  }
}

class MyApp extends StatefulWidget {
  final AuthState authState;
  
  const MyApp({super.key, required this.authState});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // 监听认证状态变化
    widget.authState.addListener(_onAuthStateChanged);
  }

  @override
  void dispose() {
    widget.authState.removeListener(_onAuthStateChanged);
    super.dispose();
  }

  void _onAuthStateChanged() {
    // 认证状态改变时重建 widget
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AIWA',
      
      // 🎨 应用深色主题（固定 #212121 背景）
      theme: createDarkTheme(),
      
      // 🔀 路由配置（添加认证守卫）
      initialRoute: kDisableAuthForTesting
          ? '/home'
          : (widget.authState.isAuthenticated ? '/home' : '/login'),
      onGenerateRoute: (settings) {
        // 自定义路由生成器，带认证检查
        Widget page;
        
        if (kDisableAuthForTesting) {
          // 测试环境：所有页面直接放行
          switch (settings.name) {
            case '/welcome':
              page = const WelcomePage();
              break;
            case '/home':
              page = const HomePage();
              break;
            case '/camera':
              page = const CameraPage();
              break;
            case '/settings':
              page = const SettingsPage();
              break;
            case '/login':
              page = const LoginPage();
              break;
            case '/register':
              page = const RegisterPage();
              break;
            default:
              page = const HomePage();
          }
        } else {
          // 认证路由（无需登录）
          if (settings.name == '/login') {
            page = const LoginPage();
          } else if (settings.name == '/register') {
            page = const RegisterPage();
          } 
          // 应用路由（需要登录）
          else if (widget.authState.isAuthenticated) {
            switch (settings.name) {
              case '/welcome':
                page = const WelcomePage();
                break;
              case '/home':
                page = const HomePage();
                break;
              case '/camera':
                page = const CameraPage();
                break;
              case '/settings':
                page = const SettingsPage();
                break;
              default:
                page = const HomePage();
            }
          } 
          // 未登录时重定向到登录页
          else {
            page = const LoginPage();
          }
        }
        
        // 检查是否需要禁用动画
        final arguments = settings.arguments as Map<String, dynamic>?;
        final noAnimation = arguments != null && arguments['noAnimation'] == true;
        
        return PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          settings: settings,
          transitionDuration: noAnimation ? Duration.zero : const Duration(milliseconds: 250),
          transitionsBuilder: noAnimation
              ? (context, animation, secondaryAnimation, child) => child
              : (context, animation, secondaryAnimation, child) {
                  // 默认淡入淡出动画
                  return FadeTransition(
                    opacity: animation,
                    child: child,
                  );
                },
        );
      },
      
      // 未知路由处理
      onUnknownRoute: (settings) {
        if (kDisableAuthForTesting) {
          return MaterialPageRoute(
            builder: (context) => const HomePage(),
          );
        } else {
          return MaterialPageRoute(
            builder: (context) => widget.authState.isAuthenticated 
                ? const HomePage() 
                : const LoginPage(),
          );
        }
      },
    );
  }
}
