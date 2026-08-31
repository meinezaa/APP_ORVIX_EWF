import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_pt_ewf/Services/theme_service.dart';

void main() {
  group('ThemeService', () {
    test('uses warm light theme colors for the app', () {
      final themeService = ThemeService();

      expect(themeService.getLightTheme().scaffoldBackgroundColor, const Color(0xFFF8F4EE));
      expect(themeService.getLightTheme().colorScheme.primary, const Color(0xFFE87824));
    });
  });
}
