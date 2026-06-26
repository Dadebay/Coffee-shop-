import 'package:flutter/material.dart';

@immutable
class AppColors {
  const AppColors._();

  // Brand
  static const Color primary    = Color(0xff1946bb);
  static const Color primary2   = Color(0xff187bff);

  // Backgrounds
  static const Color bgDark     = Color(0xff0D0D0D);
  static const Color bgCard     = Color(0xff161616);
  static const Color bgSurface  = Color(0xff1C1C1C);
  static const Color bgBorder   = Color(0xff2A2A2A);

  // Text
  static const Color textWhite  = Color(0xffFFFFFF);
  static const Color textGrey   = Color(0xff8A8A8A);
  static const Color textDim    = Color(0xff555555);

  // Status
  static const Color green      = Color(0xff3ead2c);
  static const Color greenLight = Color(0xffdcffce);
  static const Color red        = Color(0xffFF3B30);
  static const Color redLight   = Color(0xffffe0e0);
  static const Color orange     = Color(0xfffedb00);
  static const Color purple     = Color(0xffbf7ef3);
  static const Color purpleLight= Color(0xffe6cefe);
  static const Color blue       = Color(0xffcde7fc);

  // Akbulut palette reuse
  static const Color white      = Colors.white;
  static const Color black      = Colors.black;
  static const Color grey       = Colors.grey;
}
