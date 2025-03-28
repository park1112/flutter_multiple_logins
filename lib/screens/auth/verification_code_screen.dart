// 필요한 패키지를 pubspec.yaml에 추가:
// pin_code_fields: ^8.0.1

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'dart:async';
import '../../config/theme.dart';
import '../../controllers/auth_controller.dart';
import '../../widgets/custom_button.dart';

class VerificationCodeScreen extends StatefulWidget {
  final String phoneNumber;

  const VerificationCodeScreen({
    Key? key,
    required this.phoneNumber,
  }) : super(key: key);

  @override
  State<VerificationCodeScreen> createState() => _VerificationCodeScreenState();
}

class _VerificationCodeScreenState extends State<VerificationCodeScreen> {
  final AuthController _authController = Get.find<AuthController>();
  final TextEditingController _smsCodeController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // 타이머 관련 변수
  Timer? _timer;
  int _remainingSeconds = 180; // 3분
  bool _isTimerRunning = true;

  // 오류 메시지 상태
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // 타이머 시작
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        _stopTimer();
        setState(() {
          _isTimerRunning = false;
        });
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  String get _formattedTime {
    int minutes = _remainingSeconds ~/ 60;
    int seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _smsCodeController.dispose();
    _stopTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('인증코드 입력', style: TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),

              // 안내 텍스트
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.message, color: AppTheme.primaryColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '인증번호가 발송되었습니다',
                            style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${widget.phoneNumber}로 발송된 6자리 인증코드를 입력해주세요',
                            style: TextStyle(
                              color: AppTheme.textSecondaryColor,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // 인증코드 입력 필드
              PinCodeTextField(
                appContext: context,
                length: 6,
                controller: _smsCodeController,
                keyboardType: TextInputType.number,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                animationType: AnimationType.fade,
                autoFocus: true,
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(12),
                  fieldHeight: 56,
                  fieldWidth: 48,
                  activeFillColor: Colors.white,
                  inactiveFillColor: Colors.white,
                  selectedFillColor: AppTheme.primaryColor.withOpacity(0.1),
                  activeColor: AppTheme.primaryColor,
                  inactiveColor: Colors.grey.shade300,
                  selectedColor: AppTheme.primaryColor,
                  errorBorderColor: Colors.red,
                  borderWidth: 1.5,
                ),
                enableActiveFill: true,
                cursorColor: AppTheme.primaryColor,
                animationDuration: const Duration(milliseconds: 300),
                textStyle: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
                onChanged: (value) {
                  // 오류 메시지 초기화
                  if (_errorMessage != null) {
                    setState(() {
                      _errorMessage = null;
                    });
                  }

                  // 6자리 입력 완료 시 자동 검증
                  if (value.length == 6) {
                    // 자동 검증은 선택 사항
                    // _verifyCode();
                  }
                },
                beforeTextPaste: (text) {
                  // 붙여넣기 숫자 검증
                  if (text == null) return false;
                  return RegExp(r'^[0-9]{6}$').hasMatch(text);
                },
                errorAnimationController: null, // 커스텀 오류 애니메이션이 필요한 경우 추가
                onCompleted: (value) {
                  // 입력 완료 시 처리 (필요한 경우)
                },
              ),

              // 오류 메시지 표시
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 14,
                    ),
                  ),
                ),

              const SizedBox(height: 24),

              // 타이머 표시
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _isTimerRunning
                      ? Colors.grey.shade100
                      : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.timer,
                      size: 18,
                      color:
                          _isTimerRunning ? AppTheme.primaryColor : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isTimerRunning ? _formattedTime : '인증 시간이 만료되었습니다',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _isTimerRunning
                            ? AppTheme.primaryColor
                            : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // 재요청 & 인증하기 버튼
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: '재요청',
                      onPressed: () {
                        _smsCodeController.clear();
                        setState(() {
                          _remainingSeconds = 180;
                          _isTimerRunning = true;
                          _errorMessage = null;
                        });
                        _startTimer();
                        // 재인증 요청 로직 호출
                        // _requestVerificationCode();
                      },
                      isOutlined: true,
                      backgroundColor: AppTheme.primaryColor,
                      height: 54,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Obx(() => CustomButton(
                          text: '인증하기',
                          onPressed: _isTimerRunning &&
                                  _smsCodeController.text.length == 6
                              ? () => _verifyCode()
                              : () {},
                          isLoading: _authController.isLoading.value,
                          backgroundColor: AppTheme.primaryColor,
                          height: 54,
                        )),
                  ),
                ],
              ),

              const Spacer(),

              // 하단 안내 텍스트
              Text(
                '인증번호가 오지 않나요?',
                style: TextStyle(
                  color: AppTheme.textSecondaryColor,
                  fontSize: 14,
                ),
              ),
              TextButton(
                onPressed: () {
                  // 고객센터 안내
                },
                child: Text(
                  '고객센터 문의하기',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _verifyCode() async {
    if (_smsCodeController.text.length != 6) {
      setState(() {
        _errorMessage = '6자리 인증코드를 입력해주세요';
      });
      return;
    }

    if (!_isTimerRunning) {
      setState(() {
        _errorMessage = '인증 시간이 만료되었습니다. 재요청을 해주세요.';
      });
      return;
    }

    try {
      // 인증 시도
      await _authController.verifyPhoneCode(_smsCodeController.text);
      // 성공 시 타이머 정지
      _stopTimer();

      // 성공 메시지 및 화면 전환
      Get.snackbar(
        '인증 성공',
        '전화번호 인증이 완료되었습니다.',
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
        snackPosition: SnackPosition.BOTTOM,
      );

      // 홈 화면 또는 다음 화면으로 이동
      // Get.offAll(() => HomeScreen());
    } catch (e) {
      setState(() {
        _errorMessage = '유효하지 않은 인증코드입니다. 다시 확인해주세요.';
      });
    }
  }
}
