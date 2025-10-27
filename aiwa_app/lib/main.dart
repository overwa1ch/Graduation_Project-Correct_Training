import 'package:flutter/material.dart';
import 'package:aiwa_app/theme/theme.dart';
import 'package:aiwa_app/ui/pages/welcome_page.dart';
import 'package:aiwa_app/ui/pages/home_page.dart';
import 'package:aiwa_app/ui/pages/camera_page.dart';
import 'package:aiwa_app/ui/pages/settings_page.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AIWA',
      
      // 🎨 应用深色主题（固定 #212121 背景）
      theme: createDarkTheme(),
      
      // 🔀 路由配置
      initialRoute: '/welcome',
      onGenerateRoute: (settings) {
        // 自定义路由生成器，禁用页面切换动画
        Widget page;
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
            page = const WelcomePage();
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
        return MaterialPageRoute(
          builder: (context) => const WelcomePage(),
        );
      },
    );
  }
}
