import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../config/constants.dart';
import '../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // 사용자 생성 또는 업데이트
  // FirestoreService의 createOrUpdateUser 메서드 수정
  Future<void> createOrUpdateUser(UserModel user) async {
    try {
      // 인증 상태 확인
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception("인증되지 않은 사용자입니다.");
      }

      // 현재 시간 생성 (서버 타임스탬프 대신 사용)
      final DateTime now = DateTime.now();

      // 기존 사용자 데이터 확인
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(user.uid).get();

      Map<String, dynamic> updateData = {};

      // 기존 사용자가 있는 경우 필드별로 업데이트
      if (doc.exists) {
        Map<String, dynamic> existingData = doc.data() as Map<String, dynamic>;

        // 기존 이름이 있고 새 데이터에 이름이 없으면 기존 이름 유지
        if (existingData['name'] != null && user.name == null) {
          updateData['name'] = existingData['name'];
        } else {
          updateData['name'] = user.name;
        }

        updateData['email'] = user.email ?? existingData['email'];
        updateData['phoneNumber'] =
            user.phoneNumber ?? existingData['phoneNumber'];
        updateData['photoURL'] = user.photoURL ?? existingData['photoURL'];
        updateData['loginType'] = user.loginType.toString().split('.').last;
        updateData['lastLogin'] =
            FieldValue.serverTimestamp(); // 서버 타임스탬프 사용 가능

        // 로그인 기록 업데이트
        List<Map<String, dynamic>> loginHistory = [];
        if (existingData['loginHistory'] != null) {
          loginHistory =
              List<Map<String, dynamic>>.from(existingData['loginHistory']);
        }

        // 새 로그인 기록 추가 (서버 타임스탬프 대신 현재 시간 사용)
        loginHistory.add({
          'timestamp': now.toIso8601String(), // Timestamp 대신 문자열로 저장
          'loginType': user.loginType.toString().split('.').last,
        });

        // 로그인 기록 최대 100개까지만 저장
        if (loginHistory.length > 100) {
          loginHistory = loginHistory.sublist(loginHistory.length - 100);
        }

        updateData['loginHistory'] = loginHistory;
      } else {
        // 새 사용자 생성
        updateData = {
          'name': user.name,
          'email': user.email,
          'phoneNumber': user.phoneNumber,
          'photoURL': user.photoURL,
          'loginType': user.loginType.toString().split('.').last,
          'lastLogin': FieldValue.serverTimestamp(), // 서버 타임스탬프 사용 가능
          'loginHistory': [
            {
              'timestamp': now.toIso8601String(), // Timestamp 대신 문자열로 저장
              'loginType': user.loginType.toString().split('.').last,
            }
          ],
        };
      }

      // Firestore에 데이터 저장
      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(updateData, SetOptions(merge: true));
    } catch (e) {
      print('Error creating/updating user: $e');
      rethrow;
    }
  }

  // 사용자 정보 업데이트
  Future<void> updateUserProfile({
    required String uid,
    String? name,
    String? photoURL,
  }) async {
    try {
      Map<String, dynamic> data = {};

      if (name != null) data['name'] = name;
      if (photoURL != null) data['photoURL'] = photoURL;

      // 업데이트 시간만 변경 (lastLogin은 변경하지 않음)
      data['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .update(data);
    } catch (e) {
      print('Error updating user profile: $e');
      rethrow;
    }
  }

  // 프로필 이미지 업로드
  Future<String> uploadProfileImage(String uid, File imageFile) async {
    try {
      // 이미지 저장 경로 지정
      String filePath = 'profile_images/$uid.jpg';

      // 파일 업로드
      await _storage.ref(filePath).putFile(imageFile);

      // 다운로드 URL 가져오기
      String downloadURL = await _storage.ref(filePath).getDownloadURL();

      // 사용자 프로필 업데이트
      await updateUserProfile(uid: uid, photoURL: downloadURL);

      return downloadURL;
    } catch (e) {
      print('Error uploading profile image: $e');
      rethrow;
    }
  }

// 사용자 삭제 - 개선된 예외 처리
  Future<void> deleteUser(String uid) async {
    try {
      // 1. 유효한 UID 검증
      if (uid.isEmpty) {
        throw Exception("유효하지 않은 사용자 ID입니다.");
      }

      // 2. 사용자 존재 여부 확인
      final docSnapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .get();

      if (!docSnapshot.exists) {
        throw Exception("해당 ID의 사용자가 존재하지 않습니다.");
      }

      // 3. 프로필 이미지 삭제 시도
      try {
        // 이미지 참조 가져오기
        final ref = _storage.ref('profile_images/$uid.jpg');

        // 이미지가 실제로 존재하는지 확인 (getMetadata 호출은 존재하지 않으면 예외 발생)
        try {
          await ref.getMetadata();
          // 이미지가 있으면 삭제
          await ref.delete();
          print('프로필 이미지가 성공적으로 삭제되었습니다.');
        } catch (metadataError) {
          // object-not-found 오류인 경우 정상적으로 처리 (이미지가 없는 경우)
          if (metadataError is FirebaseException &&
              metadataError.code == 'object-not-found') {
            print('삭제할 프로필 이미지가 없습니다.');
          } else {
            // 다른 유형의 오류는 로깅
            print('프로필 이미지 메타데이터 확인 중 오류: $metadataError');
          }
        }
      } catch (imageError) {
        // 이미지 삭제 중 발생한 모든 예외 처리
        print('프로필 이미지 삭제 중 오류: $imageError');
        // 이미지 삭제 실패해도 계속 진행
      }

      // 4. Firestore에서 사용자 정보 삭제
      try {
        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(uid)
            .delete();
        print('Firestore에서 사용자 데이터가 성공적으로 삭제되었습니다.');
      } catch (firestoreError) {
        // Firestore 관련 오류 처리
        if (firestoreError is FirebaseException) {
          if (firestoreError.code == 'not-found') {
            print('삭제할 사용자 문서가 이미 존재하지 않습니다.');
          } else if (firestoreError.code == 'permission-denied') {
            throw Exception("사용자 데이터 삭제 권한이 없습니다.");
          } else {
            throw Exception("Firestore 삭제 오류: ${firestoreError.message}");
          }
        } else {
          throw Exception("Firestore 삭제 중 오류: $firestoreError");
        }
      }

      // 5. 인증 시스템에서 사용자 삭제 (선택적, AuthService에서 처리할 수도 있음)
      try {
        User? currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null && currentUser.uid == uid) {
          await currentUser.delete();
          print('Firebase 인증에서 사용자가 성공적으로 삭제되었습니다.');
        }
      } catch (authError) {
        // 인증 관련 오류 처리
        print('Firebase 인증에서 사용자 삭제 중 오류: $authError');
        // 재인증이 필요한 경우
        if (authError is FirebaseAuthException &&
            authError.code == 'requires-recent-login') {
          throw Exception("계정 삭제를 위해 재로그인이 필요합니다.");
        }
      }
    } catch (e) {
      print('사용자 삭제 중 오류 발생: $e');
      rethrow; // 상위 호출자에게 예외 전달
    }
  }

  Future<UserModel?> getUser(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Get user error: $e');
      return null;
    }
  }
}
