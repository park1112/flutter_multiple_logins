import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../config/theme.dart';
import '../../controllers/auth_controller.dart';
import '../../models/user_model.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final BottomNavController _bottomNavController =
      Get.put(BottomNavController());
  final AuthController _authController = Get.find<AuthController>();

  final List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    // 페이지 초기화
    _pages.addAll([
      _buildHomePage(),
      const ProfileScreen(),
    ]);

    // 로그인 확인 메시지 표시
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showLoginSuccessMessage();
    });
  }

  void _showLoginSuccessMessage() {
    final UserModel? user = _authController.userModel.value;
    if (user != null) {
      String message = '로그인이 완료되었습니다.';

      if (user.name != null && user.name!.isNotEmpty) {
        message = '${user.name}님, 환영합니다!';
      } else if (user.email != null && user.email!.isNotEmpty) {
        message = '${user.email}님, 환영합니다!';
      } else if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty) {
        message = '${user.phoneNumber}님, 환영합니다!';
      }

      Get.snackbar(
        '로그인 성공',
        message,
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppTheme.successColor,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() => _pages[_bottomNavController.selectedIndex.value]),
      bottomNavigationBar: AppBottomNavBar(controller: _bottomNavController),
    );
  }

  Widget _buildHomePage() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('홈'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _authController.signOut(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeCard(),
              const SizedBox(height: 30),
              _buildFeatureSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Obx(() {
      final user = _authController.userModel.value;

      String userName = '사용자';
      if (user?.name != null && user!.name!.isNotEmpty) {
        userName = user.name!;
      }

      String loginMethod = '로그인됨';
      if (user != null) {
        switch (user.loginType) {
          case LoginType.naver:
            loginMethod = '네이버 계정으로 로그인됨';
            break;
          case LoginType.facebook:
            loginMethod = '페이스북 계정으로 로그인됨';
            break;
          case LoginType.phone:
            loginMethod = '전화번호로 로그인됨';
            break;
          case LoginType.google:
            loginMethod = '구글 계정으로 로그인됨';
            break;
          default:
            loginMethod = '로그인됨';
        }
      }

      return Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                    backgroundImage: user?.photoURL != null
                        ? NetworkImage(user!.photoURL!)
                        : null,
                    child: user?.photoURL == null
                        ? const Icon(
                            Icons.person,
                            size: 30,
                            color: AppTheme.primaryColor,
                          )
                        : null,
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '안녕하세요, $userName님!',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          loginMethod,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                '오늘도 좋은 하루 되세요!',
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildFeatureSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '앱 기능',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 15),
        _buildFeatureCard(
          Icons.login,
          '다중 로그인',
          '네이버, 페이스북, 전화번호를 통한 간편 로그인을 지원합니다.',
        ),
        _buildFeatureCard(
          Icons.person,
          '프로필 관리',
          '사용자 정보를 쉽게 관리하고 업데이트할 수 있습니다.',
        ),
        _buildFeatureCard(
          Icons.security,
          '안전한 인증',
          '사용자 정보는 안전하게 보호되며, 자동 로그인을 지원합니다.',
        ),
        _buildFeatureCard(
          Icons.dashboard_customize,
          '재사용 가능한 템플릿',
          '모든 앱에 쉽게 통합할 수 있는 로그인 템플릿입니다.',
        ),
      ],
    );
  }

  Widget _buildFeatureCard(IconData icon, String title, String description) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: AppTheme.primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
