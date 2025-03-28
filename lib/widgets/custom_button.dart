import 'package:flutter/material.dart';
import '../config/theme.dart';

// 소셜 로그인 버튼 종류
enum SocialButtonType {
  naver,
  facebook,
  phone,
}

// 일반 커스텀 버튼
class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color textColor;
  final double height;
  final bool isOutlined;
  final IconData? icon;
  final bool isLoading;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.backgroundColor = AppTheme.primaryColor,
    this.textColor = Colors.white,
    this.height = 50.0,
    this.isOutlined = false,
    this.icon,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: isOutlined
          ? OutlinedButton(
              onPressed: isLoading ? null : onPressed,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: backgroundColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _buildButtonContent(),
            )
          : ElevatedButton(
              onPressed: isLoading ? null : onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: backgroundColor,
                foregroundColor: textColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _buildButtonContent(),
            ),
    );
  }

  Widget _buildButtonContent() {
    if (isLoading) {
      return SizedBox(
        height: 24,
        width: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            isOutlined ? backgroundColor : textColor,
          ),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 10),
          Text(
            text,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isOutlined ? backgroundColor : textColor,
            ),
          ),
        ],
      );
    }

    return Text(
      text,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: isOutlined ? backgroundColor : textColor,
      ),
    );
  }
}

// 소셜 로그인 버튼
class SocialLoginButton extends StatelessWidget {
  final SocialButtonType type;
  final VoidCallback onPressed;
  final bool isLoading;

  const SocialLoginButton({
    super.key,
    required this.type,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 8),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _getButtonColor(),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: isLoading
            ? SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _getButtonIcon(),
                  const SizedBox(width: 10),
                  Text(
                    _getButtonText(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Color _getButtonColor() {
    switch (type) {
      case SocialButtonType.naver:
        return AppTheme.naverColor;
      case SocialButtonType.facebook:
        return AppTheme.facebookColor;
      case SocialButtonType.phone:
        return Colors.grey.shade800;
    }
  }

  String _getButtonText() {
    switch (type) {
      case SocialButtonType.naver:
        return '네이버로 로그인';
      case SocialButtonType.facebook:
        return '페이스북으로 로그인';
      case SocialButtonType.phone:
        return '전화번호로 로그인';
    }
  }

  Widget _getButtonIcon() {
    switch (type) {
      case SocialButtonType.naver:
        return const Text(
          'N',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        );
      case SocialButtonType.facebook:
        return const Icon(
          Icons.facebook,
          color: Colors.white,
          size: 20,
        );
      case SocialButtonType.phone:
        return const Icon(
          Icons.phone,
          color: Colors.white,
          size: 20,
        );
    }
  }
}
