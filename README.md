# HealthyChoice

A Flutter application for analyzing food products for their health impact and safety based on personal dietary preferences and health conditions.

## 📱 Overview

HealthyChoice helps users make informed decisions about food products by scanning barcodes and analyzing whether products align with their dietary needs, health conditions, and preferences. The app leverages Google's Gemini AI for deep nutritional analysis while implementing local safety checks for instant feedback.

### 🌟 Key Features

- **Barcode Scanning**: Instantly scan food product barcodes
- **Personalized Health Analysis**: Analyze products based on your specific health profile
- **AI-Powered Insights**: Get detailed health insights and recommendations from Google Gemini AI
- **Allergen Detection**: Automatically identify allergens that may cause reactions
- **Smart Local Safety Analysis**: Get instant safety determinations without waiting for API calls
- **Health Condition Awareness**: Recognizes products that may impact specific health conditions
- **Alternative Product Suggestions**: Recommends healthier alternatives to problematic products
- **Scan History**: Keep track of previously scanned products
- **Accessibility**: Built-in features for visually impaired users

## 🛠️ Technology Stack

- **Frontend**: Flutter (Dart)
- **AI/ML**: Google Gemini AI
- **Data Source**: Open Food Facts API
- **State Management**: Provider
- **Local Storage**: SharedPreferences
- **Text-to-Speech**: flutter_tts
- **Barcode Scanning**: flutter_barcode_scanner

## 📋 Requirements

- Flutter 3.0+
- Dart 2.17+
- Android 5.0+ (API level 21+) or iOS 11.0+
- Google Gemini API key

## 🔧 Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/yourusername/HealthyChoice.git
   cd HealthyChoice
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Configure API keys:**
   - Create a `secrets.dart` file in the `lib/config` directory
   - Add your Gemini API key:
   ```dart
   const String GEMINI_API_KEY = 'your_gemini_api_key_here';
   ```

4. **Run the app:**
   ```bash
   flutter run
   ```

## 📱 Usage

### Profile Setup

1. Start the app and create your profile with:
   - Personal health goals
   - Health conditions
   - Ingredients you want to avoid
   - Allergen concerns
   - Dietary preferences (vegan, vegetarian, etc.)

### Scanning Products

1. Tap the scan button on the home screen
2. Point your camera at a product barcode
3. Wait for analysis to complete
4. View the detailed safety and health analysis

### Understanding Results

- **Green Badge**: Product is safe for your health profile
- **Yellow Badge**: Contains ingredients you prefer to avoid but is generally safe
- **Red Badge**: Contains allergens or ingredients that conflict with your health conditions
- **AI Analysis**: Detailed breakdown of the product's compatibility with your health needs
- **Alternatives**: Suggestions for similar but healthier products

## 🏗️ Architecture

The app follows a modular architecture with clean separation of concerns:

- **Screens**: UI components and layouts
- **Services**: Business logic and external API interactions
- **Models**: Data structures and transformations
- **Widgets**: Reusable UI components
- **Utilities**: Helper functions and extensions

## 📁 Project Structure

```
lib/
├── api/
│   └── api_service.dart              # Open Food Facts API integration
├── config/
│   └── secrets.dart                  # API keys (not included in repo)
├── models/
│   ├── analysis_result.dart          # AI analysis result model
│   ├── product_scan.dart             # Scanned product model
│   └── user_preferences.dart         # User preference models
├── screens/
│   ├── blindpage.dart                # Accessibility screen
│   ├── home_screen.dart              # Main screen with scan button
│   ├── profile_form.dart             # User profile setup
│   └── results_page.dart             # Product analysis display
├── services/
│   ├── gemini_service.dart           # AI integration service
│   ├── scan_history_service.dart     # Local storage for scans
│   └── service_provider.dart         # Service dependency injection
├── widgets/
│   ├── allergen_filter_chip.dart     # Allergen selection UI
│   ├── analysis_display.dart         # AI analysis visualization
│   └── alternative_products_section.dart # Alternative products display
└── main.dart                         # App entry point
```

### Key Components

#### 1. Safety Determination System

The app implements a dual-layer safety check:

1. **Quick Safety Check** (Local)
   - Instantly checks for allergens and avoided ingredients
   - Provides immediate feedback without API calls
   - Handles common safety determinations locally

2. **Deep Analysis** (AI-Powered)
   - Uses Gemini AI for comprehensive nutritional analysis
   - Evaluates ingredient interactions with health conditions
   - Provides personalized recommendations

#### 2. ProfileForm

Captures user preferences and health information with:
- Health goals
- Health conditions
- Ingredients to avoid
- Allergen preferences
- Dietary restrictions

#### 3. ResultsPage

Displays comprehensive product analysis:
- Nutritional information
- Safety determination
- Health insights
- Compatible with health goals
- Alternative product suggestions

#### 4. GeminiService

Interfaces with Google's Gemini AI:
- Sends structured prompts with product and user data
- Processes AI responses into actionable insights
- Implements caching to reduce API calls
- Provides fallback mechanisms for offline use

## 🔍 Safety Determination Logic

Safety is determined through several layers:

1. **Allergen Check**: Compares product allergens against user's allergen avoidances
2. **Ingredient Analysis**: Checks for ingredients the user wants to avoid
3. **Health Impact Assessment**: Evaluates potential impact on user's health conditions
4. **Nutritional Compatibility**: Analyzes if nutritional profile aligns with health goals

### Safety Classification

- **Safe**: No allergens or concerning ingredients detected
- **Use Caution**: Contains ingredients user prefers to avoid
- **Unsafe**: Contains allergens or ingredients that conflict with health conditions

## ⚡ Optimized Safety Determination System

The app implements a highly efficient multi-tiered safety analysis system:

### Performance Optimization

1. **Local First Approach**:
   - Safety checks happen locally first for instant feedback
   - No waiting for network requests for common safety cases
   - AI is only called when needed for complex analysis

2. **Intelligent Caching**:
   - Analysis results are cached with timestamps
   - Cache is automatically invalidated when user profile changes
   - Reduces unnecessary API calls for previously scanned products

3. **Fallback Mechanisms**:
   - In offline mode, falls back to local safety checks
   - Gracefully handles API failures with local determinations
   - Progressive enhancement based on available connectivity

### Technical Implementation

```dart
// Quick local safety check implementation
Future<AnalysisResult> quickSafetyCheck(Map<String, dynamic> productData) async {
  // Get user preferences
  final allergenPrefs = _prefs.getStringList('pref_Allergens') ?? [];
  final healthIssues = _prefs.getStringList('health_issues') ?? [];
  
  // Extract product allergens
  final allergens = productData['allergens_tags'] ?? [];
  
  // Check for allergen concerns
  bool hasAllergenConcern = false;
  for (var allergenPref in allergenPrefs) {
    // Convert format (e.g., "Dairy-free" to "dairy")
    String allergenName = allergenPref.toLowerCase();
    if (allergenName.endsWith('-free')) {
      allergenName = allergenName.substring(0, allergenName.length - 5);
    }
    
    // Check if this allergen is in the product
    if (formattedAllergens.any((a) => a.contains(allergenName))) {
      return AnalysisResult(
        compatibility: 'poor',
        isSafeForUser: false,
        // Additional properties...
      );
    }
  }
  
  // Continue with other safety checks...
}
```

This optimized system ensures that users get immediate feedback about product safety without waiting for AI analysis in most cases, significantly improving the user experience.

## 📊 Data Flow

1. User scans product barcode
2. App fetches product data from Open Food Facts API
3. Local safety check is performed immediately
4. If needed, data is sent to Gemini AI for deeper analysis
5. Results are displayed and cached for future reference
6. Product is added to scan history

## 🌐 API Integration

### Open Food Facts API

Used to retrieve comprehensive product information:
- Ingredients
- Nutritional values
- Allergens
- Additives
- Processing information

### Google Gemini API

Provides advanced analysis:
- Compatibility assessment
- Health insights
- Personalized recommendations
- Alternative product suggestions

## 🧠 Gemini AI Integration Details

HealthyChoice utilizes Google's Gemini AI for sophisticated natural language understanding and personalized analysis. The implementation follows best practices for AI integration in mobile applications:

### Prompt Engineering

The app constructs detailed prompts that include:

1. **Product Information**:
   ```
   PRODUCT INFORMATION:
   - Name: [Product Name]
   - Brand: [Brand Name]
   - Categories: [Product Categories]
   - Ingredients: [Full Ingredients List]
   - Nutri-Score: [Nutritional Grade]
   - NOVA Group: [Processing Level]
   - Allergens present: [Formatted Allergen List]
   - Additives: [Formatted Additives List]
   - Nutrition (per 100g): [Detailed Nutritional Breakdown]
   ```

2. **User Profile Context**:
   ```
   USER PROFILE:
   - Name: [User Name]
   - Health goals: [User's Health Goals]
   - Avoiding: [Ingredients to Avoid]
   - Health issues: [Health Conditions]
   
   USER PREFERENCES:
   - Nutrition preferences: [Nutrition Preferences]
   - Ingredient preferences: [Ingredient Preferences]
   - Processing preferences: [Processing Preferences]
   - Label preferences: [Label Preferences]
   - Allergen avoidances: [Allergen Preferences]
   ```

3. **Response Format Requirements**:
   ```
   Please provide a JSON response with the following structure:
   {
     "compatibility": "good", // Can be "good", "moderate", or "poor"
     "explanation": "A brief explanation of the compatibility assessment",
     "isSafeForUser": true, // Explicit boolean indicating safety
     "safetyReason": "Clear explanation why this product is safe or unsafe",
     "recommendations": ["List of recommendations"],
     "healthInsights": ["List of health insights"],
     "nutritionalValues": { ... }, // Extracted values
     "alternatives": [ ... ] // Alternative product suggestions
   }
   ```

### AI Response Processing

The app implements robust handling of AI responses:

1. **Structured Parsing**:
   - Extracts structured data using RegExp to find JSON objects
   - Handles partial responses gracefully
   - Falls back to local safety checks if parsing fails

2. **Response Validation**:
   - Verifies compatibility and safety determinations
   - Ensures recommendations are relevant to user profile
   - Validates nutritional values for consistency

3. **User-Friendly Transformation**:
   - Converts technical terms to user-friendly language
   - Formats health insights for easy comprehension
   - Prioritizes actionable recommendations

### Gemini Configuration

```dart
final Map<String, dynamic> requestBody = {
  "contents": [
    {
      "parts": [
        {
          "text": prompt
        }
      ]
    }
  ],
  "generationConfig": {
    "temperature": 0.2,  // Lower temperature for more consistent responses
    "topP": 0.8,
    "topK": 40,
    "maxOutputTokens": 1024
  }
};
```

This carefully tuned integration ensures that the AI provides reliable, relevant, and personalized analysis for each product scan while maintaining responsiveness and user privacy.

## 🔐 Privacy

- All user health data is stored locally on the device
- API requests only include anonymous product and preference data
- No personal information is transmitted to external services

## 🔮 Future Enhancements

- Offline mode with downloaded product database
- Social sharing of safe product discoveries
- Meal planning based on safe products
- OCR for reading ingredient lists directly
- Expanded database of health condition interactions
- Community-contributed alternative suggestions

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 👏 Acknowledgments

- Open Food Facts for their comprehensive food database
- Google Gemini team for the AI capabilities
- The Flutter community for their invaluable resources and support
