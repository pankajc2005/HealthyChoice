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
    
    // Simulate logo loading and prepare for navigation
    _initializeApp();
  }
  
  Future<void> _initializeApp() async {
    // Wait for framework to settle
    await Future.delayed(const Duration(milliseconds: 200));
    
    // Mark logo as loaded to trigger animation
    if (mounted) {
      setState(() {
        _isLogoLoaded = true;
      });
    }
    
    // Allow navigation after minimum display time
    await Future.delayed(const Duration(milliseconds: 800));
    
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
                    cacheHeight: 600, // Add cache hints for faster loading
                    cacheWidth: 600,
                    filterQuality: FilterQuality.medium, // Lower quality for faster loading
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
