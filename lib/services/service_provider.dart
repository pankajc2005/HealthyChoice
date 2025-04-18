import 'package:shared_preferences/shared_preferences.dart';
import 'gemini_service.dart';
import 'vision_service.dart';

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
  VisionService? _visionService;
  SharedPreferences? _sharedPreferences;
  bool _isInitializing = false;
  
  /// Start background initialization without blocking the UI thread
  /// This preloads services but doesn't wait for completion
  void initializeServices() {
    if (_isInitializing) return;
    _isInitializing = true;
    
    // Start initializing shared preferences in background
    SharedPreferences.getInstance().then((prefs) {
      _sharedPreferences = prefs;
      
      // Once we have preferences, create service instances but don't run
      // any heavy initialization code - that will happen on first use
      _geminiService = GeminiService(prefs);
      _visionService = VisionService();
      
      print('Service provider initialized basics');
    }).catchError((error) {
      _isInitializing = false;
      print('Service initialization error: $error');
    });
  }
  
  /// Get shared preferences, initializing if needed
  Future<SharedPreferences> getSharedPreferences() async {
    if (_sharedPreferences != null) {
      return _sharedPreferences!;
    }
    
    _sharedPreferences = await SharedPreferences.getInstance();
    return _sharedPreferences!;
  }
  
  /// Get the Gemini service instance, creating it if needed
  Future<GeminiService> getGeminiService() async {
    if (_geminiService != null) {
      return _geminiService!;
    }
    
    final prefs = await getSharedPreferences();
    _geminiService = GeminiService(prefs);
    return _geminiService!;
  }
  
  /// Get the Vision service instance, creating it if needed
  Future<VisionService> getVisionService() async {
    if (_visionService != null) {
      return _visionService!;
    }
    
    _visionService = VisionService();
    return _visionService!;
  }
} 