import 'package:shared_preferences/shared_preferences.dart';
import 'gemini_service.dart';

/// A simple service provider that gives access to app services.
/// This is a singleton to avoid creating multiple instances of services.
class ServiceProvider {
  static final ServiceProvider _instance = ServiceProvider._internal();
  
  factory ServiceProvider() {
    return _instance;
  }
  
  ServiceProvider._internal();
  
  // Lazy-initialized services
  GeminiService? _geminiService;
  
  /// Get the Gemini service instance, creating it if needed
  Future<GeminiService> getGeminiService() async {
    if (_geminiService == null) {
      final prefs = await SharedPreferences.getInstance();
      _geminiService = GeminiService(prefs);
    }
    return _geminiService!;
  }

  // Add this method for background initialization
  Future<void> initializeServices() async {
    // Initialize services in parallel to improve performance
    await Future.wait([
      getGeminiService(),
      // Add other service initializations here
    ]).catchError((error) {
      // Handle initialization errors silently
      print('Service initialization error: $error');
    });
  }
} 