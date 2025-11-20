import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode {
  light,
  dark,
  auto,
}

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'app_theme_mode';
  
  AppThemeMode _currentThemeMode = AppThemeMode.light;
  bool _isDarkMode = false;
  bool _isInitialized = false;
  
  AppThemeMode get currentThemeMode => _currentThemeMode;
  bool get isDarkMode => _isDarkMode;
  bool get isInitialized => _isInitialized;
  
  ThemeProvider() {
    _loadThemeMode();
  }
  
  Future<void> _loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeIndex = prefs.getInt(_themeKey) ?? 0;
      if (themeIndex < AppThemeMode.values.length) {
        _currentThemeMode = AppThemeMode.values[themeIndex];
      }
      _updateTheme();
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      // Default to light theme if loading fails
      _currentThemeMode = AppThemeMode.light;
      _updateTheme();
      _isInitialized = true;
      notifyListeners();
    }
  }
  
  Future<void> setThemeMode(AppThemeMode mode) async {
    if (_currentThemeMode == mode) return;
    
    _currentThemeMode = mode;
    _updateTheme();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themeKey, mode.index);
    } catch (e) {
      // Handle error silently
    }
    
    notifyListeners();
  }
  
  void _updateTheme() {
    switch (_currentThemeMode) {
      case AppThemeMode.light:
        _isDarkMode = false;
        break;
      case AppThemeMode.dark:
        _isDarkMode = true;
        break;
      case AppThemeMode.auto:
        // For now, default to light mode
        _isDarkMode = false;
        break;
    }
  }
  
  // Get the appropriate color scheme based on current theme
  ColorScheme get colorScheme {
    return _isDarkMode ? _darkColorScheme : _lightColorScheme;
  }
  
  // Get success color (maps to tertiary)
  Color get success => colorScheme.tertiary;
  
  // Reset the theme state to default values
  void resetState() {
    // We don't reset theme preferences as they are user settings
    // that should persist across sessions
    print('ThemeProvider: State reset not needed - theme preferences preserved');
  }
  
  // Light theme color scheme
  static const ColorScheme _lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF2196F3),
    onPrimary: Colors.white,
    secondary: Color(0xFF64B5F6),
    onSecondary: Colors.white,
    surface: Colors.white,
    onSurface: Color(0xFF424242),
    error: Color(0xFFF44336),
    onError: Colors.white,
    outline: Color(0xFFE0E0E0),
    outlineVariant: Color(0xFFE0E0E0),
    shadow: Color(0x1A000000),
    scrim: Color(0x52000000),
    inverseSurface: Color(0xFF424242),
    onInverseSurface: Colors.white,
    inversePrimary: Color(0xFF64B5F6),
    surfaceTint: Color(0xFF2196F3),
    // Add success color
    tertiary: Color(0xFF4CAF50), // This will be used as success
  );
  
  // Dark theme color scheme
  static const ColorScheme _darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF90CAF9),
    onPrimary: Colors.white,
    secondary: Color(0xFF64B5F6),
    onSecondary: Colors.white,
    surface: Color(0xFF424242),
    onSurface: Colors.white,
    error: Color(0xFFEF5350),
    onError: Colors.white,
    outline: Color(0xFF616161),
    outlineVariant: Color(0xFF424242),
    shadow: Color(0x1A000000),
    scrim: Color(0x52000000),
    inverseSurface: Colors.white,
    onInverseSurface: Color(0xFF424242),
    inversePrimary: Color(0xFF1976D2),
    surfaceTint: Color(0xFF90CAF9),
    // Add success color
    tertiary: Color(0xFF66BB6A), // This will be used as success
  );
  
  // Get theme data for MaterialApp
  ThemeData get themeData {
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        labelStyle: TextStyle(color: colorScheme.onSurface),
        hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.6)),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outline,
        thickness: 1,
      ),
      iconTheme: IconThemeData(
        color: colorScheme.onSurface,
      ),
      scaffoldBackgroundColor: colorScheme.surface,
    );
  }
}
