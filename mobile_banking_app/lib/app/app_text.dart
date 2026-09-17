import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppText {
  AppText._();

  // Headers
  static TextStyle h1 = GoogleFonts.notoSansKhmer(
    fontSize: 32,
  );

  static TextStyle h2 = GoogleFonts.notoSansKhmer(
    fontSize: 28,
    fontWeight: FontWeight.w700,
  );

  static TextStyle h3 = GoogleFonts.notoSansKhmer(
    fontSize: 24,
    fontWeight: FontWeight.w600,
  );

  static TextStyle h4 = GoogleFonts.notoSansKhmer(
    fontSize: 20,
    fontWeight: FontWeight.w600,
  );

  // Body
  static TextStyle bodyLarge = GoogleFonts.notoSansKhmer(
    fontSize: 18,
    fontWeight: FontWeight.w400,
  );

  static TextStyle bodyMedium = GoogleFonts.notoSansKhmer(
    fontSize: 16,
    fontWeight: FontWeight.w400,
  );

  static TextStyle bodySmall = GoogleFonts.notoSansKhmer(
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );

  // Labels
  static TextStyle labelLarge = GoogleFonts.notoSansKhmer(
    fontSize: 16,
    fontWeight: FontWeight.w500,
  );

  static TextStyle labelMedium = GoogleFonts.notoSansKhmer(
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  static TextStyle labelSmall = GoogleFonts.notoSansKhmer(
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );
}