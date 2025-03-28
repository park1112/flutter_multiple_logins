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
  Future<void> createOrUpdateUser(UserModel user) async {
    try {
      // 인증 상태 확인
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception("인증되지 않은 사용자입니다.");
      }

      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(user.toMap(), SetOptions(merge: true));
    } catch (e) {
      print('Error creating/updating user: $e');
      rethrow;
    }
  }

  // 사용자 정보 가져오기
  Future<UserModel?> getUser(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .get();

      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting user: $e');
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
      data['lastLogin'] = FieldValue.serverTimestamp();

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

  // 사용자 삭제
  Future<void> deleteUser(String uid) async {
    try {
      // 프로필 이미지 삭제
      try {
        await _storage.ref('profile_images/$uid.jpg').delete();
      } catch (e) {
        // 이미지가 없을 수도 있으므로 오류 무시
        print('No profile image to delete or error: $e');
      }

      // Firestore에서 사용자 정보 삭제
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .delete();
    } catch (e) {
      print('Error deleting user: $e');
      rethrow;
    }
  }
}
