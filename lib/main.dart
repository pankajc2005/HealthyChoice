import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/logo_screen.dart';  // Import the LogoScreen
import 'services/service_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  // Start measuring init time
  final stopwatch = Stopwatch()..start();
  
  // Ensure Flutter is initialized with priority on rendering
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set system UI and orientation in parallel to other initialization
  // This improves startup time by running operations concurrently
  Future systemConfigFuture = SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]).then((_) => SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  ));
  
  // Start loading environment variables but don't wait for completion
  // We'll access them when needed, preventing startup delay
  Future envFuture = dotenv.load(fileName: ".env");
  
  // Start app immediately for faster perceived loading
  runApp(NutritionAssistantApp());
  
  // Finish initialization in background
  _completeInitializationAsync(stopwatch, systemConfigFuture, envFuture);
}

/// Finishes any remaining initialization tasks in the background
/// This allows the UI to appear faster while heavy work completes afterward
Future<void> _completeInitializationAsync(
  Stopwatch stopwatch,
  Future systemConfigFuture,
  Future envFuture,
) async {
  try {
    // Wait for basic config to complete
    await Future.wait([systemConfigFuture, envFuture]);
    
    // Initialize service provider without blocking UI
    final serviceProvider = ServiceProvider();
    // Start service initialization, but don't wait for it
    serviceProvider.initializeServices();
    
    print('App initialization completed in ${stopwatch.elapsedMilliseconds}ms');
  } catch (e) {
    print('Background initialization error: $e');
  }
}

class NutritionAssistantApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HealthyChoice',
      theme: ThemeData(
        primaryColor: Color(0xFF6D30EA),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: AppBarTheme(
          systemOverlayStyle: SystemUiOverlayStyle.dark,
          backgroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: LogoScreen(),   // Use LogoScreen as the initial screen
      debugShowCheckedModeBanner: false,
    );
  }
}
