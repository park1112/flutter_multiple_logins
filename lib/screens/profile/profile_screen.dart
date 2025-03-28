import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/theme.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/user_controller.dart';
import '../../models/user_model.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../utils/custom_loading.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthController _authController = Get.find<AuthController>();
  final UserController _userController = Get.put(UserController());

  final TextEditingController _nameController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _initUserData();
  }

  void _initUserData() {
    final user = _authController.userModel.value;
    if (user != null && user.name != null) {
      _nameController.text = user.name!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('프로필'),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.close : Icons.edit),
            onPressed: () {
              setState(() {
                if (_isEditing) {
                  // 편집 취소
                  _initUserData();
                }
                _isEditing = !_isEditing;
              });
            },
          ),
        ],
      ),
      body: Obx(() {
        final isLoading = _userController.isLoading.value;

        if (isLoading) {
          return const Center(child: CustomLoading());
        }

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildProfileImage(),
                  const SizedBox(height: 30),
                  _buildProfileInfo(),
                  const SizedBox(height: 30),
                  _buildActionButtons(),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildProfileImage() {
    final user = _authController.userModel.value;
    final selectedImage = _userController.selectedImage.value;

    return Column(
      children: [
        GestureDetector(
          onTap: _isEditing ? _userController.pickImage : null,
          child: Stack(
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                backgroundImage: selectedImage != null
                    ? FileImage(selectedImage)
                    : (user?.photoURL != null
                        ? CachedNetworkImageProvider(user!.photoURL!)
                            as ImageProvider
                        : null),
                child: (selectedImage == null && user?.photoURL == null)
                    ? const Icon(
                        Icons.person,
                        size: 60,
                        color: AppTheme.primaryColor,
                      )
                    : null,
              ),
              if (_isEditing)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        if (_isEditing)
          TextButton(
            onPressed: _userController.selectedImage.value != null
                ? () => _userController.selectedImage.value = null
                : null,
            child: const Text('이미지 선택 취소'),
          ),
      ],
    );
  }

  Widget _buildProfileInfo() {
    final user = _authController.userModel.value;

    if (user == null) {
      return const Center(
        child: Text('사용자 정보를 불러올 수 없습니다.'),
      );
    }

    return Column(
      children: [
        if (_isEditing)
          NameTextField(controller: _nameController)
        else
          _buildInfoItem('이름', user.name ?? '이름 정보 없음'),
        _buildInfoItem(
          '로그인 방식',
          _getLoginTypeString(user.loginType),
        ),
        if (user.email != null && user.email!.isNotEmpty)
          _buildInfoItem('이메일', user.email!),
        if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty)
          _buildInfoItem('전화번호', user.phoneNumber!),
        _buildInfoItem(
          '마지막 로그인',
          '${user.lastLogin.year}-${user.lastLogin.month.toString().padLeft(2, '0')}-${user.lastLogin.day.toString().padLeft(2, '0')} ${user.lastLogin.hour.toString().padLeft(2, '0')}:${user.lastLogin.minute.toString().padLeft(2, '0')}',
        ),
      ],
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Divider(color: Colors.grey.shade300),
        ],
      ),
    );
  }

  String _getLoginTypeString(LoginType type) {
    switch (type) {
      case LoginType.naver:
        return '네이버';
      case LoginType.facebook:
        return '페이스북';
      case LoginType.phone:
        return '전화번호';
      default:
        return '알 수 없음';
    }
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        if (_isEditing)
          CustomButton(
            text: '프로필 저장',
            onPressed: _saveProfile,
            icon: Icons.save,
          )
        else ...[
          CustomButton(
            text: '로그아웃',
            onPressed: _logout,
            backgroundColor: Colors.grey.shade700,
            icon: Icons.logout,
          ),
          const SizedBox(height: 15),
          CustomButton(
            text: '계정 삭제',
            onPressed: _showDeleteConfirmation,
            backgroundColor: AppTheme.errorColor,
            icon: Icons.delete,
          ),
        ],
      ],
    );
  }

  void _saveProfile() async {
    if (_formKey.currentState?.validate() ?? false) {
      await _userController.updateProfile(
        name: _nameController.text.trim(),
      );

      setState(() {
        _isEditing = false;
      });
    }
  }

  void _logout() async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('정말 로그아웃하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('확인'),
          ),
        ],
      ),
    );

    if (result == true) {
      await _authController.signOut();
    }
  }

  void _showDeleteConfirmation() async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('계정 삭제'),
        content: const Text(
          '계정을 삭제하면 모든 데이터가 영구적으로 삭제됩니다. 정말 삭제하시겠습니까?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (result == true) {
      await _authController.deleteAccount();
    }
  }
}
