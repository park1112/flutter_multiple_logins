import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart'; // 새로 만든 옵션 파일 import

import 'config/constants.dart';
import 'config/theme.dart';
import 'controllers/auth_controller.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 상태바 색상 설정
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Firebase 초기화
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.web,
  );

  // GetX 컨트롤러 초기화
  Get.put(AuthController());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: '다중 로그인 템플릿',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      home: const SplashWrapper(),
    );
  }
}

class SplashWrapper extends StatefulWidget {
  const SplashWrapper({super.key});

  @override
  State<SplashWrapper> createState() => _SplashWrapperState();
}

class _SplashWrapperState extends State<SplashWrapper> {
  final AuthController _authController = Get.find<AuthController>();
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // 첫 실행 여부 확인
      SharedPreferences prefs = await SharedPreferences.getInstance();
      bool isFirstRun = prefs.getBool(AppConstants.keyIsFirstRun) ?? true;

      // 로그인 상태 확인
      bool isLoggedIn = _authController.firebaseUser.value != null;

      setState(() {
        _initialized = true;
      });

      // 화면 이동
      if (isLoggedIn) {
        Get.off(() => const HomeScreen());
      } else if (isFirstRun) {
        Get.off(() => const SplashScreen());
      } else {
        Get.off(() => const LoginScreen());
      }
    } catch (e) {
      print('App initialization error: $e');

      // 오류 발생 시 로그인 화면으로 이동
      setState(() {
        _initialized = true;
      });
      Get.off(() => const LoginScreen());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: !_initialized
            ? const CircularProgressIndicator()
            : const Text('앱을 초기화하는 중입니다...'),
      ),
    );
  }
}
