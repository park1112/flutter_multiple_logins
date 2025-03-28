import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../config/constants.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../screens/auth/login_screen.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/home/home_screen.dart';

class AuthController extends GetxController {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  Rx<User?> firebaseUser = Rx<User?>(null);
  Rx<UserModel?> userModel = Rx<UserModel?>(null);

  RxBool isLoading = false.obs;
  RxString verificationId = ''.obs;
  RxInt? resendToken;

  @override
  void onInit() {
    super.onInit();

    // Firebase 인증 상태 리스너
    firebaseUser.bindStream(_authService.authStateChanges);

    // 사용자 상태 감지 및 화면 이동
    ever(firebaseUser, _setInitialScreen);
  }

  // 초기 화면 설정
  _setInitialScreen(User? user) async {
    if (user == null) {
      // 첫 실행 확인
      SharedPreferences prefs = await SharedPreferences.getInstance();
      bool isFirstRun = prefs.getBool(AppConstants.keyIsFirstRun) ?? true;

      if (isFirstRun) {
        Get.offAll(() => SplashScreen());
      } else {
        Get.offAll(() => LoginScreen());
      }
    } else {
      // 사용자 정보 로드
      _loadUserData(user.uid);

      // 홈 화면으로 이동
      Get.offAll(() => HomeScreen());
    }
  }

  // Firestore에서 사용자 정보 로드
  Future<void> _loadUserData(String uid) async {
    try {
      UserModel? userData = await _firestoreService.getUser(uid);
      if (userData != null) {
        userModel.value = userData;

        // SharedPreferences에 사용자 정보 저장 (오프라인 접근용)
        _saveUserToPrefs(userData);
      }
    } catch (e) {
      print('Error loading user data: $e');

      // 오류 발생 시 SharedPreferences에서 로드 시도
      _loadUserFromPrefs();
    }
  }

  // SharedPreferences에 사용자 정보 저장
  Future<void> _saveUserToPrefs(UserModel user) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          AppConstants.keyUserData, jsonEncode(user.toJson()));
    } catch (e) {
      print('Error saving user to prefs: $e');
    }
  }

  // SharedPreferences에서 사용자 정보 로드
  Future<void> _loadUserFromPrefs() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userData = prefs.getString(AppConstants.keyUserData);

      if (userData != null) {
        UserModel user = UserModel.fromJson(jsonDecode(userData));
        userModel.value = user;
      }
    } catch (e) {
      print('Error loading user from prefs: $e');
    }
  }

  // 네이버 로그인
  Future<void> signInWithNaver() async {
    try {
      isLoading.value = true;
      await _authService.signInWithNaver();
    } catch (e) {
      Get.snackbar('로그인 오류', '네이버 로그인에 실패했습니다: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // 페이스북 로그인
  Future<void> signInWithFacebook() async {
    try {
      isLoading.value = true;
      await _authService.signInWithFacebook();
    } catch (e) {
      Get.snackbar('로그인 오류', '페이스북 로그인에 실패했습니다: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // 전화번호 인증 요청
  Future<void> verifyPhoneNumber(String phoneNumber) async {
    try {
      isLoading.value = true;

      await _authService.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        onCodeSent: (String vId, int? token) {
          verificationId.value = vId;
          resendToken = RxInt(token ?? 0);
          isLoading.value = false;
          Get.snackbar('인증 코드 발송', '입력하신 전화번호로 인증 코드가 발송되었습니다.');
        },
        onVerificationCompleted: (String message) {
          isLoading.value = false;
          Get.snackbar('인증 완료', message);
        },
        onError: (String errorMessage) {
          isLoading.value = false;
          Get.snackbar('인증 오류', errorMessage);
        },
      );
    } catch (e) {
      isLoading.value = false;
      Get.snackbar('오류', '전화번호 인증 요청 중 오류가 발생했습니다.');
    }
  }

  // 인증 코드 확인
  Future<void> verifyPhoneCode(String smsCode) async {
    if (verificationId.value.isEmpty) {
      Get.snackbar('오류', '인증 ID가 없습니다. 전화번호 인증을 다시 시도해주세요.');
      return;
    }

    try {
      isLoading.value = true;

      await _authService.verifyPhoneCode(
        verificationId: verificationId.value,
        smsCode: smsCode,
      );

      Get.snackbar('인증 성공', '전화번호 인증에 성공했습니다.');
    } catch (e) {
      Get.snackbar('인증 오류', '인증 코드가 올바르지 않습니다.');
    } finally {
      isLoading.value = false;
    }
  }

  // 로그아웃
  Future<void> signOut() async {
    try {
      isLoading.value = true;
      await _authService.signOut();
      userModel.value = null;

      // SharedPreferences 사용자 데이터 삭제
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.keyUserData);

      Get.snackbar('로그아웃', '로그아웃되었습니다.');
    } catch (e) {
      Get.snackbar('오류', '로그아웃 중 오류가 발생했습니다: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // 계정 삭제
  Future<void> deleteAccount() async {
    try {
      isLoading.value = true;
      await _authService.deleteAccount();
      userModel.value = null;

      // SharedPreferences 사용자 데이터 삭제
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.keyUserData);

      Get.snackbar('계정 삭제', '계정이 삭제되었습니다.');
    } catch (e) {
      Get.snackbar('오류', '계정 삭제 중 오류가 발생했습니다: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // 첫 실행 완료 설정
  Future<void> setFirstRunComplete() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.keyIsFirstRun, false);
    } catch (e) {
      print('Error setting first run complete: $e');
    }
  }
}
