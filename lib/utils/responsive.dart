import 'dart:math';
import 'package:flutter/material.dart';

/// Responsive utility that scales UI elements proportionally
/// based on a design reference size (iPhone 14 Pro - 393 x 852).
///
/// Usage:
///   final r = Responsive(context);
///   SizedBox(width: r.wp(90), height: r.hp(6));
///   Text('Hello', style: TextStyle(fontSize: r.sp(16)));
class Responsive {
  late final double _screenWidth;
  late final double _screenHeight;
  late final double _statusBarHeight;
  late final double _bottomPadding;
  late final double _safeHeight;
  late final double _pixelRatio;
  late final bool _isTablet;
  late final double _scaleFactor;

  // Design reference: iPhone 14 Pro
  static const double _designWidth = 393.0;
  static const double _designHeight = 852.0;

  Responsive(BuildContext context) {
    final mq = MediaQuery.of(context);
    _screenWidth = mq.size.width;
    _screenHeight = mq.size.height;
    _statusBarHeight = mq.padding.top;
    _bottomPadding = mq.padding.bottom;
    _safeHeight = _screenHeight - _statusBarHeight - _bottomPadding;
    _pixelRatio = mq.devicePixelRatio;
    _isTablet = mq.size.shortestSide >= 600;

    // Scale factor for tablets to prevent oversized elements
    _scaleFactor = _isTablet ? 0.85 : 1.0;
  }

  // ─── Getters ─────────────────────────────────────────────────────
  double get screenWidth => _screenWidth;
  double get screenHeight => _screenHeight;
  double get statusBarHeight => _statusBarHeight;
  double get bottomPadding => _bottomPadding;
  double get safeHeight => _safeHeight;
  double get pixelRatio => _pixelRatio;
  bool get isTablet => _isTablet;

  /// Width percentage (0-100) relative to screen width
  double wp(double percentage) => _screenWidth * (percentage / 100);

  /// Height percentage (0-100) relative to screen height
  double hp(double percentage) => _screenHeight * (percentage / 100);

  /// Safe height percentage (excludes status bar & bottom inset)
  double shp(double percentage) => _safeHeight * (percentage / 100);

  /// Scaled pixel for font sizes - maintains readability across devices
  double sp(double size) {
    final widthRatio = _screenWidth / _designWidth;
    final heightRatio = _screenHeight / _designHeight;
    final ratio = min(widthRatio, heightRatio);
    return (size * ratio * _scaleFactor).clamp(size * 0.75, size * 1.35);
  }

  /// Responsive dimension based on design width reference
  double w(double size) {
    return (size / _designWidth) * _screenWidth * _scaleFactor;
  }

  /// Responsive dimension based on design height reference
  double h(double size) {
    return (size / _designHeight) * _screenHeight * _scaleFactor;
  }

  /// Responsive radius (uses width ratio for consistency)
  double radius(double size) {
    final ratio = _screenWidth / _designWidth;
    return size * ratio * _scaleFactor;
  }

  /// Responsive padding/margin
  EdgeInsets symmetric({double horizontal = 0, double vertical = 0}) {
    return EdgeInsets.symmetric(
      horizontal: w(horizontal),
      vertical: h(vertical),
    );
  }

  EdgeInsets only({
    double left = 0,
    double top = 0,
    double right = 0,
    double bottom = 0,
  }) {
    return EdgeInsets.only(
      left: w(left),
      top: h(top),
      right: w(right),
      bottom: h(bottom),
    );
  }

  /// Max width for content on tablets to prevent overly wide layouts
  double get maxContentWidth => _isTablet ? 600.0 : _screenWidth;

  /// Adaptive value: returns phone value or tablet value
  T adaptive<T>(T phone, T tablet) => _isTablet ? tablet : phone;

  /// Grid cross-axis count based on screen width
  int get gridColumns {
    if (_screenWidth >= 900) return 4;
    if (_screenWidth >= 600) return 3;
    return 2;
  }
}
