import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

import 'package:aiwa_app/services/auth/auth_state.dart';
import 'package:aiwa_app/services/exercise/exercise_library_service.dart';
import 'package:aiwa_app/services/fit/fit_bootstrap.dart';
import 'package:aiwa_app/services/fit/fit_scope.dart';
import 'package:aiwa_app/services/fit/fit_service_hub.dart';
import 'package:aiwa_app/services/fit/fit_ui_state.dart';
import 'package:aiwa_app/services/notes/note_service.dart';
import 'package:aiwa_app/theme/theme.dart';
import 'package:aiwa_app/ui/main_tab_shell.dart';
import 'package:aiwa_app/ui/pages/camera_page.dart';
import 'package:aiwa_app/ui/pages/exercise_template_editor_page.dart';
import 'package:aiwa_app/ui/pages/fit_editor_page.dart';
import 'package:aiwa_app/ui/pages/insights_placeholder_page.dart';
import 'package:aiwa_app/ui/pages/library_page.dart';
import 'package:aiwa_app/ui/pages/login_page.dart';
import 'package:aiwa_app/ui/pages/note_editor_page.dart';
import 'package:aiwa_app/ui/pages/notes_manage_page.dart';
import 'package:aiwa_app/ui/pages/register_page.dart';
import 'package:aiwa_app/ui/pages/task_template_editor_page.dart';
import 'package:aiwa_app/ui/pages/welcome_page.dart';

const bool kDisableAuthForTesting = false;

Widget _buildPageForRoute(String? name) {
  switch (name) {
    case '/welcome':
      return const WelcomePage();
    case '/home':
      return const MainTabShell(initialIndex: 0);
    case '/plan':
      return const MainTabShell(initialIndex: 1);
    case '/library':
      return const MainTabShell(initialIndex: 2);
    case '/settings':
      return const MainTabShell(initialIndex: 3);
    case '/editor':
      return const FitEditorPage();
    case '/task_template_editor':
      return const TaskTemplateEditorPage();
    case '/camera':
      return const CameraPage();
    case '/library_standalone':
      return const LibraryPage();
    case '/exercise_library_entry':
      return const ExerciseTemplateEditorPage();
    case '/insights':
      return const InsightsPlaceholderPage();
    case '/note_editor':
      return const NoteEditorPage();
    case '/notes_manage':
      return const NotesManagePage();
    case '/login':
      return const LoginPage();
    case '/register':
      return const RegisterPage();
    default:
      return const MainTabShell(initialIndex: 0);
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AppBootstrapper());
}

class AppBootstrapper extends StatefulWidget {
  const AppBootstrapper({super.key});

  @override
  State<AppBootstrapper> createState() => _AppBootstrapperState();
}

class _AppBootstrapperState extends State<AppBootstrapper> {
  bool _initialized = false;
  late final FitServiceHub _fitHub;
  late final FitUiState _fitUiState;
  late final AuthState _authState;
  late final NoteService _noteService;
  late final ExerciseLibraryService _exerciseLibraryService;
  String _loadingText = '正在启动...';

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    try {
      setState(() => _loadingText = '准备环境...');
      await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();

      setState(() => _loadingText = '加载本地数据...');
      final appDir = await getApplicationDocumentsDirectory();
      _fitHub = await FitBootstrap.init(appDir);
      _fitUiState = FitUiState(_fitHub);

      setState(() => _loadingText = '加载笔记...');
      _noteService = NoteService();
      await _noteService.load();

      setState(() => _loadingText = '加载动作库...');
      _exerciseLibraryService = ExerciseLibraryService();
      await _exerciseLibraryService.load();

      setState(() => _loadingText = '检查登录状态...');
      _authState = AuthState();
      if (!kDisableAuthForTesting) {
        await _authState.initialize();
      }

      setState(() => _initialized = true);
    } catch (error) {
      setState(() => _loadingText = '启动失败：$error');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return MaterialApp(
        title: 'AIWA',
        theme: createDarkTheme(),
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 24),
                Text(_loadingText, style: const TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ),
      );
    }

    return MyApp(
      authState: _authState,
      fitHub: _fitHub,
      fitUiState: _fitUiState,
      noteService: _noteService,
      exerciseLibraryService: _exerciseLibraryService,
    );
  }
}

class MyApp extends StatefulWidget {
  const MyApp({
    super.key,
    required this.authState,
    required this.fitHub,
    required this.fitUiState,
    required this.noteService,
    required this.exerciseLibraryService,
  });

  final AuthState authState;
  final FitServiceHub fitHub;
  final FitUiState fitUiState;
  final NoteService noteService;
  final ExerciseLibraryService exerciseLibraryService;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    widget.authState.addListener(_onAuthStateChanged);
  }

  @override
  void dispose() {
    widget.authState.removeListener(_onAuthStateChanged);
    super.dispose();
  }

  void _onAuthStateChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<NoteService>.value(value: widget.noteService),
        ChangeNotifierProvider<ExerciseLibraryService>.value(
          value: widget.exerciseLibraryService,
        ),
      ],
      child: FitScope(
        hub: widget.fitHub,
        uiState: widget.fitUiState,
        child: MaterialApp(
          title: 'AIWA',
          theme: createDarkTheme(),
          localizationsDelegates:
              FlutterQuillLocalizations.localizationsDelegates,
          supportedLocales: FlutterQuillLocalizations.supportedLocales,
          initialRoute: kDisableAuthForTesting
              ? '/home'
              : (widget.authState.isAuthenticated ? '/home' : '/login'),
          onGenerateRoute: (settings) {
            Widget page;
            if (kDisableAuthForTesting) {
              page = _buildPageForRoute(settings.name);
            } else if (!widget.authState.isAuthenticated &&
                settings.name != '/login' &&
                settings.name != '/register') {
              page = const LoginPage();
            } else {
              page = _buildPageForRoute(settings.name);
            }

            final arguments = settings.arguments as Map<String, dynamic>?;
            final noAnimation =
                arguments != null && arguments['noAnimation'] == true;

            return PageRouteBuilder(
              settings: settings,
              pageBuilder: (context, animation, secondaryAnimation) => page,
              transitionDuration: noAnimation
                  ? Duration.zero
                  : const Duration(milliseconds: 250),
              transitionsBuilder: noAnimation
                  ? (context, animation, secondaryAnimation, child) => child
                  : (context, animation, secondaryAnimation, child) {
                      return FadeTransition(
                        opacity: animation,
                        child: child,
                      );
                    },
            );
          },
          onUnknownRoute: (settings) {
            if (kDisableAuthForTesting) {
              return MaterialPageRoute(
                builder: (context) => const MainTabShell(initialIndex: 0),
              );
            }
            return MaterialPageRoute(
              builder: (context) => widget.authState.isAuthenticated
                  ? const MainTabShell(initialIndex: 0)
                  : const LoginPage(),
            );
          },
        ),
      ),
    );
  }
}
