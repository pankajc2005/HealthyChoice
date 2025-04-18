import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'profile_form.dart'; // Updated to go to ProfileForm

class LogoScreen extends StatefulWidget {
  const LogoScreen({super.key});

  @override
  State<LogoScreen> createState() => _LogoScreenState();
}

class _LogoScreenState extends State<LogoScreen> {
  bool _isLogoLoaded = false;
  bool _canProceed = false;

  @override
  void initState() {
    super.initState();
    
    // Optimize system UI for faster startup
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    
    // Initialize app with optimized timing
    _initializeApp();
  }
  
  Future<void> _initializeApp() async {
    // Enable immediate rendering for perceived faster loading
    if (mounted) {
      // Show logo immediately 
      setState(() {
        _isLogoLoaded = true;
      });
    }
    
    // Only wait for a minimal time - reduced from 1000ms to 600ms total
    await Future.delayed(const Duration(milliseconds: 600));
    
    if (mounted) {
      setState(() {
        _canProceed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6C30EA), Color(0xFF145AE0)], // Gradient background
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo with animation
              AnimatedOpacity(
                opacity: _isLogoLoaded ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeIn,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOut,
                  height: _isLogoLoaded ? 300 : 250, // Slightly smaller to speed up loading
                  child: Image.asset(
                    'assets/images/logo.png',
                    cacheHeight: 300, // Reduced cache size for faster loading
                    cacheWidth: 300,
                    filterQuality: FilterQuality.low, // Use lowest quality for splash screen
                    gaplessPlayback: true, // Prevent flickering during image load
                  ),
                ),
              ),
              
              const SizedBox(height: 40),

              // "Get Started" Button
              AnimatedOpacity(
                opacity: _canProceed ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: ElevatedButton(
                  onPressed: _canProceed ? () {
                    // Navigate to ProfileForm instead of HomeScreen
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const ProfileForm()),
                    );
                  } : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 5,
                  ),
                  child: const Text(
                    "🚀 Get Started",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              
              // Loading indicator
              if (!_canProceed)
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withOpacity(0.8)),
                      strokeWidth: 2.0,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
