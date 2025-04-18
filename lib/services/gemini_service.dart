import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_service.dart';
import '../models/analysis_result.dart';
import '../models/product_scan.dart';

class GeminiService {
  // API key 
  static const String _apiKey = 'AIzaSyA4oC2febrTDhg2Ii0tJjBEg3NWKs1-YPM';
  // Updated endpoint to use Gemini 2.0 Flash model
  static const String _apiEndpoint = 'https://generativelanguage.googleapis.com/v1/models/gemini-2.0-flash:generateContent';
  // Base URL for Gemini API
  static const String _baseApiUrl = 'https://generativelanguage.googleapis.com/v1';
  
  final SharedPreferences _prefs;
  
  GeminiService(this._prefs);
  
  // New method to list available models
  Future<List<Map<String, dynamic>>> listAvailableModels() async {
    final url = Uri.parse('$_baseApiUrl/models?key=$_apiKey');
    
    try {
      final response = await http.get(url);
      
      print('List Models API Status Code: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final models = jsonResponse['models'] as List<dynamic>;
        
        // Print models to console for debugging
        for (var model in models) {
          print('Model: ${model['name']}');
          print('Display Name: ${model['displayName']}');
          print('Supported Generation Methods: ${model['supportedGenerationMethods']}');
          print('-------------------------');
        }
        
        // Return the list of models
        return models.map<Map<String, dynamic>>((model) => {
          'name': model['name'],
          'displayName': model['displayName'],
          'supportedGenerationMethods': model['supportedGenerationMethods'],
          'description': model['description'] ?? 'No description available',
          'inputTokenLimit': model['inputTokenLimit'] ?? 'N/A',
          'outputTokenLimit': model['outputTokenLimit'] ?? 'N/A',
        }).toList();
      } else {
        print('Error listing models: ${response.body}');
        throw Exception('Failed to list models: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception listing models: $e');
      throw Exception('Error fetching model list: $e');
    }
  }
  
  Future<AnalysisResult> analyzeProductForUser(
    Map<String, dynamic> productData, 
    String barcode
  ) async {
    // Get comprehensive user preferences from SharedPreferences
    final userName = _prefs.getString('full_name') ?? 'User';
    
    // Get general user goals and avoidance preferences
    final goals = _prefs.getStringList('goals') ?? [];
    final avoid = _prefs.getStringList('avoid') ?? [];
    
    // Get detailed preference information from profile form categories
    final nutritionPrefs = _prefs.getStringList('pref_Nutrition') ?? [];
    final ingredientPrefs = _prefs.getStringList('pref_Ingredients') ?? [];
    final processingPrefs = _prefs.getStringList('pref_Processing') ?? [];
    final labelPrefs = _prefs.getStringList('pref_Labels') ?? [];
    final allergenPrefs = _prefs.getStringList('pref_Allergens') ?? [];
    
    // Get health issues to consider
    final healthIssues = _prefs.getStringList('pref_Health Issues') ?? [];
    
    // Check cache first (invalidate cache if profile was updated recently)
    final profileUpdateTime = _prefs.getInt('profile_last_updated') ?? 0;
    final currentCache = _prefs.getString('${barcode}_analysis');
    final cacheTime = _prefs.getInt('${barcode}_analysis_time') ?? 0;
    
    final cacheKey = '${barcode}_analysis';
    final cachedResult = (profileUpdateTime > cacheTime) ? null : _checkCache(cacheKey);
    if (cachedResult != null) return cachedResult;
    
    // Extract product information
    final productName = productData['product_name'] ?? 'Unknown Product';
    final ingredients = productData['ingredients_text'] ?? 'No ingredient information available';
    final nutriScore = (productData['nutriscore_grade'] ?? '').toUpperCase();
    final nutrientLevels = productData['nutrient_levels'] ?? {};
    final allergens = productData['allergens_tags'] ?? [];
    final brands = productData['brands'] ?? '';
    final categories = productData['categories'] ?? '';
    final countries = productData['countries'] ?? '';
    final nutriments = productData['nutriments'] ?? {};
    final additives = productData['additives_tags'] ?? [];
    final novaGroup = productData['nova_group'] != null 
                       ? productData['nova_group'].toString() 
                       : 'unknown';
    
    // Build a map of nutrient levels for easier processing
    final nutrients = {
      'Sugar': nutrientLevels['sugars'],
      'Fat': nutrientLevels['fat'],
      'Salt': nutrientLevels['salt'],
      'Saturated Fat': nutrientLevels['saturated-fat'],
    };
    
    // Prepare prompt with product and comprehensive user data
    final prompt = _buildEnhancedProductAnalysisPrompt(
      productName: productName,
      brands: brands,
      categories: categories,
      countries: countries,
      ingredients: ingredients,
      nutriScore: nutriScore,
      nutrients: nutrients,
      allergens: allergens,
      additives: additives,
      novaGroup: novaGroup,
      nutriments: nutriments,
      
      // User preferences
      userName: userName,
      goals: goals,
      avoid: avoid,
      nutritionPrefs: nutritionPrefs,
      ingredientPrefs: ingredientPrefs,
      processingPrefs: processingPrefs,
      labelPrefs: labelPrefs,
      allergenPrefs: allergenPrefs,
      healthIssues: healthIssues
    );
    
    try {
      final analysisResult = await _sendGeminiRequest(prompt);
      
      // Cache the result with timestamp
      _cacheResult(cacheKey, analysisResult);
      _prefs.setInt('${barcode}_analysis_time', DateTime.now().millisecondsSinceEpoch);
      
      return analysisResult;
    } catch (e) {
      print('Gemini API Error: $e'); // Add debugging info
      return AnalysisResult(
        isError: true,
        errorMessage: 'Could not analyze this product: ${e.toString()}',
        compatibility: 'unknown',
        explanation: 'An error occurred while analyzing this product.',
        recommendations: [],
        healthInsights: [],
      );
    }
  }
  
  AnalysisResult? _checkCache(String key) {
    final cachedData = _prefs.getString(key);
    if (cachedData != null) {
      try {
        return AnalysisResult.fromJson(json.decode(cachedData));
      } catch (e) {
        _prefs.remove(key); // Remove invalid cache entry
        return null;
      }
    }
    return null;
  }
  
  void _cacheResult(String key, AnalysisResult result) {
    _prefs.setString(key, json.encode(result.toJson()));
  }
  
  String _buildEnhancedProductAnalysisPrompt({
    required String productName,
    required String brands,
    required String categories,
    required String countries,
    required String ingredients,
    required String nutriScore,
    required Map<String, dynamic> nutrients,
    required List<dynamic> allergens,
    required List<dynamic> additives,
    required String novaGroup,
    required Map<String, dynamic> nutriments,
    
    // User preferences
    required String userName,
    required List<String> goals,
    required List<String> avoid,
    required List<String> nutritionPrefs,
    required List<String> ingredientPrefs,
    required List<String> processingPrefs,
    required List<String> labelPrefs,
    required List<String> allergenPrefs,
    required List<String> healthIssues,
  }) {
    // Format allergens for better readability
    final formattedAllergens = allergens.map((allergen) {
      // Extract just the allergen name from formats like "en:milk"
      if (allergen is String && allergen.contains(':')) {
        return allergen.split(':').last;
      }
      return allergen;
    }).join(', ');
    
    // Format additives for better readability
    final formattedAdditives = additives.map((additive) {
      // Extract just the additive code from formats like "en:e100"
      if (additive is String && additive.contains(':')) {
        return additive.split(':').last.toUpperCase();
      }
      return additive;
    }).join(', ');
    
    // Extract key nutritional information
    final energy = nutriments['energy-kcal_100g'] ?? nutriments['energy_100g'];
    final sugar = nutriments['sugars_100g'];
    final salt = nutriments['salt_100g'];
    final fat = nutriments['fat_100g'];
    final saturatedFat = nutriments['saturated-fat_100g'];
    final protein = nutriments['proteins_100g'];
    final carbs = nutriments['carbohydrates_100g'];
    final fiber = nutriments['fiber_100g'];
    
    // Format nutrient levels
    final nutrientsText = nutrients.entries
        .where((e) => e.value != null)
        .map((e) => "${e.key}: ${e.value.toString().toUpperCase()}")
        .join(', ');
    
    // Build more comprehensive nutrition section
    String nutritionText = 'Nutrition (per 100g/ml):\n';
    if (energy != null) nutritionText += '- Energy: $energy kcal\n';
    if (protein != null) nutritionText += '- Protein: $protein g\n';
    if (carbs != null) nutritionText += '- Carbohydrates: $carbs g\n';
    if (sugar != null) nutritionText += '- Sugar: $sugar g\n';
    if (fat != null) nutritionText += '- Fat: $fat g\n';
    if (saturatedFat != null) nutritionText += '- Saturated Fat: $saturatedFat g\n';
    if (salt != null) nutritionText += '- Salt: $salt g\n';
    if (fiber != null) nutritionText += '- Fiber: $fiber g\n';
        
    return '''
You are a nutrition assistant for HealthyChoice app. Based on the detailed product information and comprehensive user preferences below, provide a personalized analysis:

PRODUCT INFORMATION:
- Name: $productName
- Brand: $brands
- Categories: $categories
- Origin: $countries
- Ingredients: $ingredients
- Nutri-Score: $nutriScore 
- NOVA Group (Processing Level): $novaGroup (where 1=unprocessed, 4=highly processed)
- Nutrient Levels: $nutrientsText
- Allergens present: $formattedAllergens
- Additives: $formattedAdditives
$nutritionText

USER PROFILE:
- Name: $userName
- Health goals: ${goals.join(', ')}
- Avoiding: ${avoid.join(', ')}
- Health issues: ${healthIssues.join(', ')}

USER PREFERENCES:
- Nutrition preferences: ${nutritionPrefs.join(', ')}
- Ingredient preferences: ${ingredientPrefs.join(', ')}
- Processing preferences: ${processingPrefs.join(', ')}
- Label preferences: ${labelPrefs.join(', ')}
- Allergen avoidances: ${allergenPrefs.join(', ')}

Please provide a JSON response with the following structure:
{
  "compatibility": "good", // Can be "good", "moderate", or "poor"
  "explanation": "A brief explanation of the compatibility assessment",
  "isSafeForUser": true, // Explicit boolean indicating if this product is safe for the user
  "safetyReason": "Clear explanation why this product is safe or unsafe for this specific user",
  "recommendations": ["List of recommendations or alternatives"],
  "healthInsights": ["List of health insights about this product"],
  "nutritionalValues": {
    "energy": 250, // Extracted calorie value per 100g in kcal
    "sugars": 12.5, // Extracted sugar content per 100g in grams
    "sodium": 400, // Extracted sodium content per 100g in mg
    "fats": 5.2, // Extracted fat content per 100g in grams
    "saturatedFats": 2.1, // Extracted saturated fat content per 100g in grams
    "protein": 3.5, // Extracted protein content per 100g in grams
    "carbs": 30, // Extracted carbohydrate content per 100g in grams
    "fiber": 1.2 // Extracted fiber content per 100g in grams
  },
  "healthScore": 75, // On a scale of 0-100, how healthy this product is for this specific user
  "alternatives": [
    {
      "name": "Specific product name as alternative",
      "reason": "Brief reason why this is a better alternative",
      "nutritionalBenefits": "Key nutritional advantages",
      "imageUrl": null // URLs are often unreliable, so set to null
    }
  ]
}

Focus on how this product aligns with the user's specific health profile:
1. If the user has health issues (like high blood pressure, diabetes, etc.), analyze how this product might affect those conditions
2. If the user prefers low salt/sugar/fat, evaluate the product against those preferences
3. If the user avoids certain ingredients or additives, check if they're present
4. If the user has allergen concerns, carefully check the allergen list
5. If the user prefers certain processing levels (like minimally processed foods), evaluate the NOVA group score
6. If the user has specific nutritional goals (like high protein), analyze the nutritional composition accordingly

The "isSafeForUser" field should be:
- false if the product contains any allergens the user is avoiding
- false if the product contains ingredients that would negatively impact their health issues
- true otherwise

For the "nutritionalValues" section, use the provided values rather than estimates when available.
Provide 2-3 actionable recommendations and health insights, personalized to the user's specific health profile.

If the compatibility is "moderate" or "poor", always suggest 2-3 specific alternative products that would better align with the user's health profile.
''';
  }
  
  Future<AnalysisResult> _sendGeminiRequest(String prompt) async {
    final url = Uri.parse('$_apiEndpoint?key=$_apiKey');
    
    // Updated request format to match Gemini API requirements
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
        "temperature": 0.2,
        "topP": 0.8,
        "topK": 40,
        "maxOutputTokens": 1024
      }
    };
    
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );
      
      print('Gemini API Status Code: ${response.statusCode}'); // Add debugging info
      
      if (response.statusCode == 200) {
        try {
          final jsonResponse = json.decode(response.body);
          
          // Debug output
          print('Gemini API Response: ${response.body.substring(0, min(200, response.body.length))}...');
          
          final textResponse = jsonResponse['candidates'][0]['content']['parts'][0]['text'];
          
          // Extract the JSON object from the response
          final RegExp jsonRegex = RegExp(r'\{.*\}', dotAll: true);
          final jsonMatch = jsonRegex.firstMatch(textResponse);
          
          if (jsonMatch != null) {
            final jsonStr = jsonMatch.group(0);
            final Map<String, dynamic> analysisData = json.decode(jsonStr!);
            
            // Process alternative products and fetch images
            List<AlternativeProduct> alternatives = [];
            if (analysisData['alternatives'] != null) {
              try {
                // Get the raw alternatives from Gemini
                final List<dynamic> rawAlternatives = analysisData['alternatives'];
                
                // Process each alternative and fetch images
                for (var alt in rawAlternatives) {
                  String name = alt['name'] ?? 'Unknown Alternative';
                  String reason = alt['reason'] ?? 'Better alternative';
                  String? benefits = alt['nutritionalBenefits'];
                  
                  // Get category from benefits or reason if available
                  String? category;
                  if (benefits != null && benefits.isNotEmpty) {
                    // Try to extract category from benefits
                    final lowercaseBenefits = benefits.toLowerCase();
                    if (lowercaseBenefits.contains('dairy')) category = 'dairy';
                    else if (lowercaseBenefits.contains('cereal')) category = 'cereal';
                    else if (lowercaseBenefits.contains('snack')) category = 'snack';
                    else if (lowercaseBenefits.contains('beverage')) category = 'beverage';
                    else if (lowercaseBenefits.contains('fruit')) category = 'fruit';
                    // Add more category extractions as needed
                  }
                  
                  // First check if Gemini provided an image URL
                  String? imageUrl = alt['imageUrl'];
                  
                  // If not, fetch image from our API
                  if (imageUrl == null || imageUrl.isEmpty) {
                    imageUrl = await ApiService.getProductImageUrl(name, category: category);
                  }
                  
                  // Add the alternative with the image
                  alternatives.add(AlternativeProduct(
                    name: name,
                    reason: reason,
                    nutritionalBenefits: benefits,
                    imageUrl: imageUrl,
                  ));
                }
              } catch (e) {
                print('Error processing alternatives: $e');
              }
            }
            
            return AnalysisResult(
              isError: false,
              errorMessage: '',
              compatibility: analysisData['compatibility'] ?? 'unknown',
              explanation: analysisData['explanation'] ?? 'No explanation provided.',
              recommendations: List<String>.from(analysisData['recommendations'] ?? []),
              healthInsights: List<String>.from(analysisData['healthInsights'] ?? []),
              alternatives: alternatives,
              isSafeForUser: analysisData['isSafeForUser'] ?? false,
              safetyReason: analysisData['safetyReason'] ?? '',
              nutritionalValues: _extractNutritionalValues(analysisData['nutritionalValues']),
            );
          } else {
            throw Exception('Could not parse JSON from response: $textResponse');
          }
        } catch (e) {
          throw Exception('Failed to parse Gemini response: $e');
        }
      } else {
        // Provide more detailed error message
        print('Error Response: ${response.body}');
        throw Exception('Gemini API request failed with status ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network or API error: $e');
    }
  }
  
  // Helper method to get a color-coded compatibility value
  static String getCompatibilityEmoji(String compatibility) {
    switch (compatibility.toLowerCase()) {
      case 'good':
        return '✅';
      case 'moderate':
        return '⚠️';
      case 'poor':
        return '❌';
      default:
        return '❓';
    }
  }
  
  // Helper method to convert nutritional values to the right format
  Map<String, double> _extractNutritionalValues(dynamic nutritionalValuesData) {
    final result = <String, double>{};
    
    // Helper function to safely convert to double
    double safeToDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        // Try to parse string, handling different formats
        final cleanedString = value.replaceAll(RegExp(r'[^\d\.\-]'), '');
        return double.tryParse(cleanedString) ?? 0.0;
      }
      return 0.0;
    }
    
    if (nutritionalValuesData != null && nutritionalValuesData is Map<String, dynamic>) {
      nutritionalValuesData.forEach((key, value) {
        result[key] = safeToDouble(value);
      });
    }
    
    return result;
  }
  
  // Add new method after analyzeProductForUser
  Future<List<Map<String, dynamic>>> getSuggestedAlternatives(
    Map<String, dynamic> productData, 
    String barcode,
    {bool forceFetch = false}
  ) async {
    // Get comprehensive user preferences from SharedPreferences
    final userName = _prefs.getString('full_name') ?? 'User';
    
    // Get general user goals and avoidance preferences
    final goals = _prefs.getStringList('goals') ?? [];
    final avoid = _prefs.getStringList('avoid') ?? [];
    
    // Get detailed preference information from profile form categories
    final nutritionPrefs = _prefs.getStringList('pref_Nutrition') ?? [];
    final ingredientPrefs = _prefs.getStringList('pref_Ingredients') ?? [];
    final processingPrefs = _prefs.getStringList('pref_Processing') ?? [];
    final labelPrefs = _prefs.getStringList('pref_Labels') ?? [];
    final allergenPrefs = _prefs.getStringList('pref_Allergens') ?? [];
    
    // Get health issues to consider
    final healthIssues = _prefs.getStringList('pref_Health Issues') ?? [];
    
    // Check cache first unless force fetch is requested
    // Also invalidate cache if profile was updated recently
    final profileUpdateTime = _prefs.getInt('profile_last_updated') ?? 0;
    final cacheTime = _prefs.getInt('${barcode}_alternatives_time') ?? 0;
    
    final cacheKey = '${barcode}_alternatives';
    if (!forceFetch && profileUpdateTime <= cacheTime) {
      final cachedResult = _checkAlternativesCache(cacheKey);
      if (cachedResult != null) return cachedResult;
    }
    
    // Extract product information
    final productName = productData['product_name'] ?? 'Unknown Product';
    final categories = productData['categories'] ?? '';
    final brands = productData['brands'] ?? '';
    final ingredients = productData['ingredients_text'] ?? 'No ingredient information available';
    final nutriments = productData['nutriments'] ?? {};
    final allergens = productData['allergens_tags'] ?? [];
    final additives = productData['additives_tags'] ?? [];
    final novaGroup = productData['nova_group'] != null 
                       ? productData['nova_group'].toString() 
                       : 'unknown';
    final nutriScore = (productData['nutriscore_grade'] ?? '').toUpperCase();
    
    // Prepare prompt specifically for alternatives with enhanced preferences
    final prompt = _buildEnhancedAlternativesPrompt(
      productName: productName,
      categories: categories,
      brands: brands,
      ingredients: ingredients,
      nutriments: nutriments,
      allergens: allergens,
      additives: additives,
      novaGroup: novaGroup,
      nutriScore: nutriScore,
      
      // User preferences
      userName: userName,
      goals: goals,
      avoid: avoid,
      nutritionPrefs: nutritionPrefs,
      ingredientPrefs: ingredientPrefs,
      processingPrefs: processingPrefs,
      labelPrefs: labelPrefs,
      allergenPrefs: allergenPrefs,
      healthIssues: healthIssues
    );
    
    try {
      final alternatives = await _fetchAlternativesFromGemini(prompt);
      
      // Cache the result with timestamp
      _cacheAlternatives(cacheKey, alternatives);
      _prefs.setInt('${barcode}_alternatives_time', DateTime.now().millisecondsSinceEpoch);
      
      return alternatives;
    } catch (e) {
      print('Gemini Alternatives API Error: $e');
      // Return a default list in case of error, but without image URLs
      return [
        {
          'product_name': 'Healthy Alternative (Similar to ${productName.split(' ').take(3).join(' ')})',
          'image_url': null,
          'nutriscore_grade': 'A',
          'brand': 'Health Choice',
          'description': 'A healthier alternative aligned with your dietary preferences.'
        }
      ];
    }
  }
  
  List<Map<String, dynamic>>? _checkAlternativesCache(String key) {
    final cachedData = _prefs.getString(key);
    if (cachedData != null) {
      try {
        final List<dynamic> decoded = json.decode(cachedData);
        return decoded.cast<Map<String, dynamic>>();
      } catch (e) {
        _prefs.remove(key); // Remove invalid cache entry
        return null;
      }
    }
    return null;
  }
  
  void _cacheAlternatives(String key, List<Map<String, dynamic>> alternatives) {
    _prefs.setString(key, json.encode(alternatives));
  }
  
  String _buildEnhancedAlternativesPrompt({
    required String productName,
    required String categories,
    required String brands,
    required String ingredients,
    required Map<String, dynamic> nutriments,
    required List<dynamic> allergens,
    required List<dynamic> additives, 
    required String novaGroup,
    required String nutriScore,
    
    // User preferences
    required String userName,
    required List<String> goals,
    required List<String> avoid,
    required List<String> nutritionPrefs,
    required List<String> ingredientPrefs,
    required List<String> processingPrefs,
    required List<String> labelPrefs,
    required List<String> allergenPrefs,
    required List<String> healthIssues,
  }) {
    // Format allergens for better readability
    final formattedAllergens = allergens.map((allergen) {
      // Extract just the allergen name from formats like "en:milk"
      if (allergen is String && allergen.contains(':')) {
        return allergen.split(':').last;
      }
      return allergen;
    }).join(', ');
    
    // Format additives for better readability
    final formattedAdditives = additives.map((additive) {
      // Extract just the additive code from formats like "en:e100"
      if (additive is String && additive.contains(':')) {
        return additive.split(':').last.toUpperCase();
      }
      return additive;
    }).join(', ');
    
    // Extract key nutritional information for prompt
    final energy = nutriments['energy-kcal_100g'] ?? nutriments['energy_100g'];
    final sugar = nutriments['sugars_100g'];
    final salt = nutriments['salt_100g'];
    final fat = nutriments['fat_100g'];
    final saturatedFat = nutriments['saturated-fat_100g'];
    final protein = nutriments['proteins_100g'];
    
    // Build comprehensive nutrition section for the prompt
    String nutritionText = '';
    if (energy != null) nutritionText += '- Energy: $energy kcal\n';
    if (protein != null) nutritionText += '- Protein: $protein g\n';
    if (sugar != null) nutritionText += '- Sugar: $sugar g\n';
    if (fat != null) nutritionText += '- Fat: $fat g\n';
    if (saturatedFat != null) nutritionText += '- Saturated Fat: $saturatedFat g\n';
    if (salt != null) nutritionText += '- Salt: $salt g\n';
    
    return '''
You are a personalized nutrition assistant for HealthyChoice app. Based on the product information and user preferences below, suggest healthier alternative products:

PRODUCT TO IMPROVE UPON:
- Name: $productName
- Category: $categories
- Brand: $brands
- Ingredients: $ingredients
- Nutri-Score: $nutriScore
- NOVA Group (Processing Level): $novaGroup (1=unprocessed, 4=highly processed)
- Allergens present: $formattedAllergens
- Additives: $formattedAdditives
- Nutrition (per 100g):
$nutritionText

USER PROFILE:
- Name: $userName
- Health goals: ${goals.join(', ')}
- Avoiding: ${avoid.join(', ')}
- Health issues: ${healthIssues.join(', ')}

USER PREFERENCES:
- Nutrition preferences: ${nutritionPrefs.join(', ')}
- Ingredient preferences: ${ingredientPrefs.join(', ')}
- Processing preferences: ${processingPrefs.join(', ')}
- Label preferences: ${labelPrefs.join(', ')}
- Allergen avoidances: ${allergenPrefs.join(', ')}

Please provide a JSON array of 3-4 specific alternative products with the following structure:
[
  {
    "product_name": "Specific product name as alternative",
    "brand": "Brand name of the alternative product",
    "nutriscore_grade": "A", // Estimate Nutri-Score grade (A-E)
    "description": "Brief reason why this is a better alternative for this specific user",
    "image_url": null // We don't use image URLs
  }
]

Focus on providing alternatives that specifically address this user's health profile:
1. If the user has health issues (like high blood pressure, diabetes, etc.), suggest products that won't negatively impact those conditions
2. If the user prefers low salt/sugar/fat, suggest alternatives with reduced amounts
3. If the user avoids certain ingredients or additives, ensure the alternatives don't contain them
4. If the user has allergen concerns, ensure all alternatives are free from those allergens
5. If the user prefers certain processing levels, suggest alternatives with appropriate NOVA scores
6. If the user has specific nutritional preferences (like high protein), ensure alternatives match these criteria

Each alternative MUST be:
- A real product with a specific brand and name (not generic suggestions)
- Available in the same general category as the original product
- Clearly better for this specific user's health profile
- Free from any allergens the user is avoiding
- Supportive of the user's specific health goals and preferences
''';
  }
  
  Future<List<Map<String, dynamic>>> _fetchAlternativesFromGemini(String prompt) async {
    final url = Uri.parse('$_apiEndpoint?key=$_apiKey');
    
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
        "temperature": 0.4,
        "topP": 0.9,
        "topK": 40,
        "maxOutputTokens": 1024
      }
    };
    
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );
      
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final textResponse = jsonResponse['candidates'][0]['content']['parts'][0]['text'];
        
        // Extract the JSON array from the response
        final RegExp jsonRegex = RegExp(r'\[.*\]', dotAll: true);
        final jsonMatch = jsonRegex.firstMatch(textResponse);
        
        if (jsonMatch != null) {
          try {
            final List<dynamic> alternatives = json.decode(jsonMatch.group(0)!);
            return alternatives.cast<Map<String, dynamic>>();
          } catch (e) {
            print('Error parsing alternatives JSON: $e');
            throw Exception('Failed to parse alternatives from Gemini response');
          }
        } else {
          throw Exception('No valid JSON array found in Gemini response');
        }
      } else {
        throw Exception('Gemini API error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Exception in _fetchAlternativesFromGemini: $e');
      throw Exception('Error fetching alternatives: $e');
    }
  }
}

// Helper function for string manipulation
int min(int a, int b) => a < b ? a : b; 