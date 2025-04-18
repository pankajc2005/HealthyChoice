import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/logo_screen.dart';  // Import the LogoScreen
import 'services/service_provider.dart';

void main() {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations for faster startup
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Initialize the app immediately without waiting for services
  runApp(NutritionAssistantApp());
  
  // Initialize services in the background after app has started
  _initializeServicesAsync();
}

// Asynchronously initialize services without blocking the UI
Future<void> _initializeServicesAsync() async {
  final serviceProvider = ServiceProvider();
  // Move service initialization to background
  serviceProvider.initializeServices();
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
