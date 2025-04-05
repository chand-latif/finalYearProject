import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF09D1C7);
  static const Color background = Colors.grey;
  static const Color text = Colors.black87;
}

class AppTextStyles {
  static const TextStyle headline = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.text,
  );
  static const TextStyle body = TextStyle(fontSize: 16, color: AppColors.text);
}
