import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'camera_screen.dart';
import 'home_screen.dart';

class BlindPage extends StatefulWidget {
  const BlindPage({super.key});

  @override
  State<BlindPage> createState() => _BlindPageState();
}

class _BlindPageState extends State<BlindPage> {
  final FlutterTts flutterTts = FlutterTts();

  final String instruction =
      "Healthy Choice will now scan the product's barcode."
      "Show the entire package. Tap once to start scanning,"
      "or tap and hold to hear this again.";

  @override
  void initState() {
    super.initState();
    _speakInstructions();
  }

  Future<void> _speakInstructions() async {
    await flutterTts.setLanguage("en-IN");
    await flutterTts.setSpeechRate(0.35);
    await flutterTts.speak(instruction);
  }

  void _handleTap() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ScanPage()),
    );
  }

  void _handleLongPress() {
    flutterTts.stop();
    _speakInstructions();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      onLongPress: _handleLongPress,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            'Blind Mode Activated',
            style: TextStyle(color: Colors.white, fontSize: 24),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}