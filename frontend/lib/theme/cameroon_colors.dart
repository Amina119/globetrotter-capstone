import 'package:flutter/material.dart';

/// Brand colors drawn from the Cameroonian flag, used to give the app a
/// distinct local identity (GlobeTrotter is based in Nkolmbong, Yaoundé).
/// Extended with vibrant sunset/ocean accents for a travel-forward feel.
class CameroonColors {
  CameroonColors._();

  static const green = Color(0xFF007A3D);
  static const greenDark = Color(0xFF00532A);
  static const greenLight = Color(0xFF3FB871);
  static const red = Color(0xFFCE1126);
  static const redDark = Color(0xFFA30D1E);
  static const gold = Color(0xFFFCD116);
  static const goldDeep = Color(0xFFF5A623);

  /// Warm sunset accent used for highlights, ratings, and "recommended" tags.
  static const sunsetOrange = Color(0xFFFF7A45);
  static const sunsetPink = Color(0xFFFF5D8F);

  /// Cool ocean accent used for maps/travel-adjacent surfaces.
  static const oceanBlue = Color(0xFF1E88E5);
  static const oceanDeep = Color(0xFF0B4F8A);

  static const surfaceTint = Color(0xFFFFFBF2);

  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [greenDark, green, Color(0xFF1E9E5A)],
  );

  static const sunsetGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [sunsetPink, sunsetOrange],
  );

  static const goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [goldDeep, gold],
  );

  static const oceanGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [oceanDeep, oceanBlue],
  );
}
