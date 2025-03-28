import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../config/theme.dart';
import '../../controllers/auth_controller.dart';
import '../../widgets/custom_button.dart';
import '../../utils/custom_loading.dart';
import 'phone_login_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final AuthController _authController = Get.find<AuthController>();
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Obx(() {
          return Stack(
            children: [
              _buildLoginContent(),
              if (_authController.isLoading.value)
                Container(
                  color: Colors.black.withOpacity(0.5),
                  child: const Center(
                    child: CustomLoading(),
                  ),
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildLoginContent() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: FadeTransition(
        opacity: _fadeInAnimation,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 30),
            // 앱 로고
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.lock_open,
                color: Colors.white,
                size: 60,
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              '로그인',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              '다양한 방법으로 간편하게 로그인하세요',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 50),
            // 소셜 로그인 버튼들
            SocialLoginButton(
              type: SocialButtonType.naver,
              onPressed: _handleNaverLogin,
              isLoading: _authController.isLoading.value,
            ),
            SocialLoginButton(
              type: SocialButtonType.facebook,
              onPressed: _handleFacebookLogin,
              isLoading: _authController.isLoading.value,
            ),
            SocialLoginButton(
              type: SocialButtonType.phone,
              onPressed: _handlePhoneLogin,
              isLoading: _authController.isLoading.value,
            ),
            const SizedBox(height: 20),
            // 앱 정보
            const Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Text(
                  '© 2023 Multi Login Template',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleNaverLogin() async {
    try {
      await _authController.signInWithNaver();
    } catch (e) {
      Get.snackbar('로그인 오류', '네이버 로그인 중 오류가 발생했습니다.');
    }
  }

  void _handleFacebookLogin() async {
    try {
      await _authController.signInWithFacebook();
    } catch (e) {
      Get.snackbar('로그인 오류', '페이스북 로그인 중 오류가 발생했습니다.');
    }
  }

  void _handlePhoneLogin() {
    Get.to(() => const PhoneLoginScreen());
  }
}
