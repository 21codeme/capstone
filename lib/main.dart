import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/firebase/firebase_config.dart';
import 'app/theme/theme_provider.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'app/routes/app_router.dart';
import 'features/auth/presentation/screens/splash_screen.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Filter out specific error messages we don't want to display
  FlutterError.onError = (FlutterErrorDetails details) {
    // Check if the error message contains the text we want to filter out
    if (details.toString().contains('PigeonUserDetails')) {
      // Silently ignore this specific error
      return;
    }
    // Forward all other errors to the default handler
    FlutterError.presentError(details);
  };
  
  // Initialize Firebase using FirebaseConfig
  try {
    await FirebaseConfig.initialize();
    // Firebase initialized successfully
  } catch (e) {
    // Firebase initialization failed - this is handled gracefully by the app
    // The app will continue to run and handle Firebase errors appropriately
  }
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => AuthProvider())
      ],
      child: const PathFitApp(),
    ),
  );
}

class PathFitApp extends StatelessWidget {
  const PathFitApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'PathFit',
          theme: themeProvider.themeData,
          home: const SplashScreen(),
          onGenerateRoute: AppRouter.generateRoute,
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}


