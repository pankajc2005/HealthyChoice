import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';
import 'blindpage.dart';

class ProfileForm extends StatefulWidget {
  const ProfileForm({super.key});

  @override
  State<ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<ProfileForm> {
  final TextEditingController nameController = TextEditingController();
  final FlutterTts flutterTts = FlutterTts();

  final List<String> goals = [];
  final List<String> avoidItems = [];
  final List<String> healthIssues = [
    "Heart Disease",
    "High Blood Pressure",
    "High Cholesterol",
    "Diabetes",
    "Obesity",
    "Kidney Issues",
  ];

  final Map<String, List<String>> preferenceSections = {
    "Ingredients": ["Vegan", "Vegetarian", "Palm oil free"],
    "Allergens": [
      "Gluten-free", "Dairy-free", "Egg-free", "Nut-free", "Peanut-free", "Sesame-free", "Soy-free",
      "Celery-free", "Mustard-free", "Lupin-free", "Fish-free", "Shellfish-free", "Mollusc-free", "Sulfite-free"
    ],
  };

  late Map<String, List<String>> preferenceSelections;

  @override
  void initState() {
    super.initState();
    preferenceSelections = {
      for (var key in preferenceSections.keys) key: [],
    };

    speakBlindNotice();
  }

  Future<void> speakBlindNotice() async {
    await flutterTts.setLanguage("en-IN");
    await flutterTts.setSpeechRate(0.4);
    await flutterTts.speak(
      "Welcome to Healthy Choice, your go to for healthy food! If you're visually impaired, tap and hold the screen so we can personalize the app for you.",
    );
  }

  void handleBlindUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isBlind', true);
    Navigator.push(context, MaterialPageRoute(builder: (_) => const BlindPage()));
  }

  void handleSubmit() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    
    // Save basic profile data
    await prefs.setString('full_name', nameController.text);
    await prefs.setStringList('goals', goals);
    await prefs.setStringList('avoid', avoidItems);
    
    // Extract health issues that were selected
    List<String> selectedHealthIssues = [];
    for (String issue in healthIssues) {
      if (avoidItems.contains(issue)) {
        selectedHealthIssues.add(issue);
      }
    }
    // Save health issues explicitly for the quickSafetyCheck method
    await prefs.setStringList('health_issues', selectedHealthIssues);
    
    // Save other preference selections
    for (var entry in preferenceSelections.entries) {
      await prefs.setStringList('pref_${entry.key}', entry.value);
    }
    
    // Set timestamp for when profile was last updated
    await prefs.setInt('profile_last_updated', DateTime.now().millisecondsSinceEpoch);
    
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomeScreen()));
  }

  void toggleChip(List<String> list, String value) {
    setState(() => list.contains(value) ? list.remove(value) : list.add(value));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: handleBlindUser,
      child: Scaffold(
        backgroundColor: const Color(0xFF4A4EDA),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Center(
                child: Image.asset('assets/images/logo.png', height: 100),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        "Complete Profile",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF4A4EDA)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    questionBlock("Full Name", child: TextFormField(
                      controller: nameController,
                      decoration: customInputDecoration(),
                    )),
                    questionBlock("Goals", child: Wrap(
                      spacing: 10,
                      children: [
                        chip("Weight Loss", goals),
                        chip("Stay Fit", goals),
                        chip("Gain Muscle", goals),
                        chip("Improve Digestion", goals),
                      ],
                    )),
                    questionBlock("Health Issues", child: Wrap(
                      spacing: 10,
                      children: healthIssues.map((issue) => chip(issue, avoidItems)).toList(),
                    )),
                    questionBlock("Trying to Avoid", child: Wrap(
                      spacing: 10,
                      children: [
                        chip("Salt", avoidItems),
                        chip("Sugar", avoidItems),
                        chip("Milk", avoidItems),
                      ],
                    )),
                    ...preferenceSections.entries.map((entry) {
                      return questionBlock(entry.key, child: Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        children: entry.value
                            .map((item) => chip(item, preferenceSelections[entry.key]!))
                            .toList(),
                      ));
                    }).toList(),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF673BDF),
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                        ),
                        onPressed: handleSubmit,
                        child: const Text(
                          "Done",
                          style: TextStyle(fontSize: 19, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget chip(String title, List<String> list) {
    return FilterChip(
      label: Text(title),
      selected: list.contains(title),
      onSelected: (_) => toggleChip(list, title),
      backgroundColor: const Color(0xFFE7E9FD),
      selectedColor: const Color(0xFF4A4EDA),
      labelStyle: const TextStyle(color: Colors.black),
    );
  }

  Widget questionBlock(String title, {required Widget child}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F5FB),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4A4EDA),
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 10),
                  child,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration customInputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFFF0F2FA),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide.none,
      ),
    );
  }
}