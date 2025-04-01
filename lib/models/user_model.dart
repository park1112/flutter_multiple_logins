import 'package:cloud_firestore/cloud_firestore.dart';

enum LoginType { naver, facebook, phone, unknown, google }

class UserModel {
  final String uid;
  final String? name;
  final String? email;
  final String? phoneNumber;
  final String? photoURL;
  final LoginType loginType;
  final DateTime lastLogin;

  UserModel({
    required this.uid,
    this.name,
    this.email,
    this.phoneNumber,
    this.photoURL,
    required this.loginType,
    required this.lastLogin,
  });

  // 파이어스토어에서 데이터 로드
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      name: data['name'],
      email: data['email'],
      phoneNumber: data['phoneNumber'],
      photoURL: data['photoURL'],
      loginType: _stringToLoginType(data['loginType']),
      lastLogin: (data['lastLogin'] as Timestamp).toDate(),
    );
  }

  // Map으로 변환 (Firestore에 저장용)
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'photoURL': photoURL,
      'loginType': loginType.toString().split('.').last,
      'lastLogin': FieldValue.serverTimestamp(),
    };
  }

  // JSON으로 변환 (SharedPreferences 저장용)
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'photoURL': photoURL,
      'loginType': loginType.toString().split('.').last,
      'lastLogin': lastLogin.toIso8601String(),
    };
  }

  // JSON에서 객체 생성 (SharedPreferences에서 로드)
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'],
      name: json['name'],
      email: json['email'],
      phoneNumber: json['phoneNumber'],
      photoURL: json['photoURL'],
      loginType: _stringToLoginType(json['loginType']),
      lastLogin: DateTime.parse(json['lastLogin']),
    );
  }

  // 문자열 LoginType으로 변환
  static LoginType _stringToLoginType(String? type) {
    switch (type) {
      case 'naver':
        return LoginType.naver;
      case 'facebook':
        return LoginType.facebook;
      case 'phone':
        return LoginType.phone;
      case 'google':
        return LoginType.google;
      default:
        return LoginType.unknown;
    }
  }

  // 복사 및 업데이트
  UserModel copyWith({
    String? name,
    String? photoURL,
  }) {
    return UserModel(
      uid: this.uid,
      name: name ?? this.name,
      email: this.email,
      phoneNumber: this.phoneNumber,
      photoURL: photoURL ?? this.photoURL,
      loginType: this.loginType,
      lastLogin: DateTime.now(),
    );
  }
}
