import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter_naver_login/flutter_naver_login.dart';
import '../models/user_model.dart';
import 'firestore_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();

  // 현재 사용자
  User? get currentUser => _auth.currentUser;

  // 인증 상태 감지
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // 네이버 로그인
  Future<UserCredential?> signInWithNaver() async {
    try {
      if (kIsWeb) {
        throw '웹에서는 네이버 로그인을 지원하지 않습니다.';
      }

      if (!(Platform.isAndroid || Platform.isIOS)) {
        throw '모바일 플랫폼에서만 네이버 로그인이 가능합니다.';
      }

      // 네이버 로그인 SDK 사용하여 로그인
      NaverLoginResult result = await FlutterNaverLogin.logIn();

      if (result.status == NaverLoginStatus.loggedIn) {
        // 액세스 토큰 가져오기
        final NaverAccessToken token =
            await FlutterNaverLogin.currentAccessToken;

        // 커스텀 토큰 생성을 위한 Firebase Function 호출 (서버 측 구현 필요)
        // 여기서는 서버에 HTTP 요청을 보내는 코드가 필요함
        // 이 예시에서는 직접 Firebase Function URL을 호출한다고 가정

        // 실제 구현에서는 Firebase Function에서 받은 커스텀 토큰을 사용
        // 이 예시에서는 테스트용 더미 코드를 넣겠습니다

        // 네이버 사용자 프로필 정보 가져오기
        NaverAccountResult account = await FlutterNaverLogin.currentAccount();

        // Firebase 사용자 생성 또는 업데이트
        UserCredential userCredential = await _createOrUpdateNaverUser(account);

        return userCredential;
      }
      return null;
    } catch (e) {
      print('Naver sign in error: $e');
      rethrow;
    }
  }

  // 네이버 사용자 생성 또는 업데이트 (Firebase Custom Auth 구현 예시)
  Future<UserCredential> _createOrUpdateNaverUser(
      NaverAccountResult account) async {
    // 실제 구현에서는 Firebase Function을 통해 받은 커스텀 토큰으로 로그인
    // 이 예시에서는 실제 통합 구현이 불가능하므로 이메일/비밀번호 로그인으로 대체

    try {
      // 이메일로 기존 사용자 확인 (실제 구현에서는 네이버 ID로 매칭)
      UserCredential? userCredential;
      try {
        userCredential = await _auth.signInWithEmailAndPassword(
          email: '${account.email}',
          password: 'naver_auth_' + account.id, // 실제 구현에서는 이렇게 하지 않음
        );
      } catch (e) {
        // 사용자가 없으면 새로 생성
        userCredential = await _auth.createUserWithEmailAndPassword(
          email: '${account.email}',
          password: 'naver_auth_' + account.id, // 실제 구현에서는 이렇게 하지 않음
        );
      }

      // 사용자 정보 업데이트
      await userCredential.user?.updateDisplayName(account.name);
      await userCredential.user?.updatePhotoURL(account.profileImage);

      // Firestore에 사용자 정보 저장
      if (userCredential.user != null) {
        await _firestoreService.createOrUpdateUser(
          UserModel(
            uid: userCredential.user!.uid,
            name: account.name,
            email: account.email,
            photoURL: account.profileImage,
            loginType: LoginType.naver,
            lastLogin: DateTime.now(),
          ),
        );
      }

      return userCredential;
    } catch (e) {
      print('Create/Update Naver user error: $e');
      rethrow;
    }
  }

  // 페이스북 로그인
  Future<UserCredential?> signInWithFacebook() async {
    try {
      if (kIsWeb) {
        // 웹용 페이스북 로그인
        FacebookAuth instance = FacebookAuth.instance;
        final LoginResult result = await instance.login();

        if (result.status == LoginStatus.success) {
          // 액세스 토큰 얻기
          final AccessToken accessToken = result.accessToken!;

          // Facebook 인증 정보 생성
          final OAuthCredential credential =
              FacebookAuthProvider.credential(accessToken.tokenString);

          // Firebase에 로그인
          final UserCredential userCredential =
              await _auth.signInWithCredential(credential);

          // 페이스북에서 추가 사용자 정보 가져오기
          final userData = await FacebookAuth.instance.getUserData();

          // Firestore에 사용자 정보 저장
          if (userCredential.user != null) {
            await _firestoreService.createOrUpdateUser(
              UserModel(
                uid: userCredential.user!.uid,
                name: userCredential.user!.displayName,
                email: userCredential.user!.email,
                photoURL: userCredential.user!.photoURL,
                loginType: LoginType.facebook,
                lastLogin: DateTime.now(),
              ),
            );
          }

          return userCredential;
        }

        return null;
      } else if (Platform.isAndroid || Platform.isIOS) {
        // 모바일용 페이스북 로그인
        final LoginResult result = await FacebookAuth.instance.login();

        if (result.status == LoginStatus.success) {
          // 액세스 토큰 얻기
          final AccessToken accessToken = result.accessToken!;

          // Facebook 인증 정보 생성
          final OAuthCredential credential =
              FacebookAuthProvider.credential(accessToken.tokenString);

          // Firebase에 로그인
          final UserCredential userCredential =
              await _auth.signInWithCredential(credential);

          // 페이스북에서 추가 사용자 정보 가져오기
          final userData = await FacebookAuth.instance.getUserData();

          // Firestore에 사용자 정보 저장
          if (userCredential.user != null) {
            await _firestoreService.createOrUpdateUser(
              UserModel(
                uid: userCredential.user!.uid,
                name: userCredential.user!.displayName,
                email: userCredential.user!.email,
                photoURL: userCredential.user!.photoURL,
                loginType: LoginType.facebook,
                lastLogin: DateTime.now(),
              ),
            );
          }

          return userCredential;
        }

        return null;
      } else {
        throw '지원하지 않는 플랫폼입니다.';
      }
    } catch (e) {
      print('Facebook sign in error: $e');
      rethrow;
    }
  }

  // 전화번호 로그인 - 인증 코드 요청
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String, int?) onCodeSent,
    required Function(String) onVerificationCompleted,
    required Function(String) onError,
  }) async {
    try {
      if (kIsWeb) {
        // 웹용 reCAPTCHA 설정
        await _auth.setSettings(
          appVerificationDisabledForTesting: false,
          phoneNumber: phoneNumber,
        );
      }

      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Android 자동 인증만 지원
          if (!kIsWeb && Platform.isAndroid) {
            await _auth.signInWithCredential(credential);
            onVerificationCompleted('인증이 자동으로 완료되었습니다.');
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          onError(e.message ?? '전화번호 인증에 실패했습니다.');
        },
        codeSent: (String verificationId, int? resendToken) {
          onCodeSent(verificationId, resendToken);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          // 자동 코드 검색 시간 초과
        },
      );
    } catch (e) {
      onError('전화번호 인증 요청 중 오류가 발생했습니다: $e');
    }
  }

  // 전화번호 로그인 - 인증 코드 확인
  Future<UserCredential?> verifyPhoneCode({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      // 인증 정보 생성
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      // Firebase에 로그인
      UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      // Firestore에 사용자 정보 저장
      if (userCredential.user != null) {
        await _firestoreService.createOrUpdateUser(
          UserModel(
            uid: userCredential.user!.uid,
            phoneNumber: userCredential.user!.phoneNumber,
            loginType: LoginType.phone,
            lastLogin: DateTime.now(),
          ),
        );
      }

      return userCredential;
    } catch (e) {
      print('Phone verification error: $e');
      rethrow;
    }
  }

  // 로그아웃
  Future<void> signOut() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        // 현재 사용자의 로그인 타입 확인
        UserModel? userModel = await _firestoreService.getUser(user.uid);

        if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
          try {
            if (userModel?.loginType == LoginType.naver) {
              await FlutterNaverLogin.logOut();
            }
          } catch (e) {
            print('Naver logout error: $e');
            // 네이버 로그아웃 실패해도 계속 진행
          }
        }

        // 페이스북 로그아웃
        if (userModel?.loginType == LoginType.facebook) {
          await FacebookAuth.instance.logOut();
        }
      }

      // Firebase 로그아웃
      await _auth.signOut();
    } catch (e) {
      print('Sign out error: $e');
      rethrow;
    }
  }

  // 계정 삭제
  Future<void> deleteAccount() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        // Firestore에서 사용자 정보 삭제
        await _firestoreService.deleteUser(user.uid);

        // Firebase 인증에서 계정 삭제
        await user.delete();
      }
    } catch (e) {
      print('Delete account error: $e');
      rethrow;
    }
  }
}
