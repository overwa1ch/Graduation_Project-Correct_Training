import 'package:flutter/material.dart';
import 'package:aiwa_app/theme/theme.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AIWA',
      // 🎨 应用 Figma 设计语言
      theme: createLightTheme(),
      darkTheme: createDarkTheme(),
      themeMode: ThemeMode.system, // 跟随系统设置（可改为 ThemeMode.light 或 ThemeMode.dark）
      home: const _CounterPage(),
    );
  }
}

class _CounterPage extends StatefulWidget {
  const _CounterPage();
  @override
  State<_CounterPage> createState() => _CounterPageState();
}

class _CounterPageState extends State<_CounterPage> {
  int _counter = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Counter')),
      body: Center(child: Text('$_counter')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => setState(() => _counter++),
        child: const Icon(Icons.add),
      ),
    );
  }
}
