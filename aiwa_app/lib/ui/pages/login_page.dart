import 'package:flutter/material.dart';
import 'package:aiwa_app/theme/spacing.dart';
import 'package:aiwa_app/theme/typography.dart';
import 'package:aiwa_app/services/auth/auth_state.dart';

/// 登录页面
///
/// 基于 Figma 设计和现有主题实现
/// 功能：
/// - 用户登录
/// - 表单验证
/// - 错误提示
/// - 跳转注册页面
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// 表单验证 - 邮箱
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return '请输入邮箱';
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return '请输入正确的邮箱';
    }

    return null;
  }

  /// 表单验证 - 密码
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return '请输入密码';
    }

    if (value.length < 8) {
      return '密码至少 8 位';
    }

    return null;
  }

  /// 处理登录
  Future<void> _handleLogin() async {
    // 验证表单
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authState = AuthState();
      final success = await authState.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      if (success) {
        // 登录成功，跳转到首页
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        // 显示错误信息
        _showErrorSnackBar(authState.errorMessage ?? '登录失败');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('发生错误：$e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// 显示错误提示
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        margin: AppSpacing.pageInsets,
      ),
    );
  }

  /// 跳转到注册页面
  void _navigateToRegister() {
    Navigator.pushNamed(context, '/register');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: AppSpacing.pageInsets,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo
                    Icon(
                      Icons.fitness_center,
                      size: 80,
                      color: theme.colorScheme.primary,
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // 标题
                    Text(
                      '欢迎回来',
                      style: theme.textTheme.displaySmall?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: AppTypography.extraBold,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: AppSpacing.sm),

                    // 副标题
                    Text(
                      '登录后继续训练',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: AppSpacing.xxxl),

                    // 邮箱输入框
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: '邮箱',
                        hintText: '请输入邮箱',
                        prefixIcon: Icon(
                          Icons.email_outlined,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: _validateEmail,
                      enabled: !_isLoading,
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // 密码输入框
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: '密码',
                        hintText: '请输入密码',
                        prefixIcon: Icon(
                          Icons.lock_outlined,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                      ),
                      obscureText: !_isPasswordVisible,
                      textInputAction: TextInputAction.done,
                      validator: _validatePassword,
                      enabled: !_isLoading,
                      onFieldSubmitted: (_) => _handleLogin(),
                    ),

                    const SizedBox(height: AppSpacing.xxl),

                    // 登录按钮
                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      child: _isLoading
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  theme.colorScheme.onPrimary,
                                ),
                              ),
                            )
                          : const Text('登录'),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // 分隔线
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                          ),
                          child: Text(
                            '或',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // 注册按钮
                    OutlinedButton(
                      onPressed: _isLoading ? null : _navigateToRegister,
                      child: const Text('注册'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
