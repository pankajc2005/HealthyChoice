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
  static const _cachedAnalysisKey = 'cached_product_analysis';
  static const _cachedAlternativesKey = 'cached_alternatives';
  
  GeminiService(this._prefs);
  
  // Add lazy loading capability for heavier operations
  bool _initialized = false;
  
  // Defer heavy initialization until actually needed
  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    
    // Perform any heavy initialization here
    // This will only happen when the service is first used
    
    _initialized = true;
  }
  
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
    await _ensureInitialized();
    
    // Check for cached result first to improve performance
    final cachedResult = _getCachedAnalysis(barcode);
    if (cachedResult != null) {
      return cachedResult;
    }
    
    // Get user preferences from SharedPreferences
    final userName = _prefs.getString('full_name') ?? 'User';
    final allergens = _prefs.getStringList('allergens') ?? [];
    final goals = _prefs.getStringList('goals') ?? [];
    final avoid = _prefs.getStringList('avoid') ?? [];
    
    // Extract product information
    final productName = productData['product_name'] ?? 'Unknown Product';
    final ingredients = productData['ingredients_text'] ?? 'No ingredient information available';
    final nutriScore = (productData['nutriscore_grade'] ?? '').toUpperCase();
    final nutrientLevels = productData['nutrient_levels'] ?? {};
    
    // Build a map of nutrient levels for easier processing
    final nutrients = {
      'Sugar': nutrientLevels['sugars'],
      'Fat': nutrientLevels['fat'],
      'Salt': nutrientLevels['salt'],
      'Saturated Fat': nutrientLevels['saturated-fat'],
    };
    
    // Prepare prompt with product and user data
    final prompt = _buildProductAnalysisPrompt(
      productName: productName,
      ingredients: ingredients,
      nutriScore: nutriScore,
      nutrients: nutrients,
      allergens: allergens,
      goals: goals,
      avoid: avoid,
      userName: userName
    );
    
    try {
      final analysisResult = await _sendGeminiRequest(prompt);
      
      // Cache the result
      _cacheAnalysisResult(barcode, analysisResult);
      
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
  
  AnalysisResult? _getCachedAnalysis(String barcode) {
    try {
      final cachedResults = _prefs.getString(_cachedAnalysisKey) ?? '{}';
      final Map<String, dynamic> resultsMap = json.decode(cachedResults);
      
      if (resultsMap.containsKey(barcode)) {
        return AnalysisResult.fromJson(resultsMap[barcode]);
      }
    } catch (e) {
      print('Error retrieving cached analysis: $e');
    }
    return null;
  }
  
  void _cacheAnalysisResult(String barcode, AnalysisResult result) {
    try {
      final cachedResults = _prefs.getString(_cachedAnalysisKey) ?? '{}';
      final Map<String, dynamic> resultsMap = json.decode(cachedResults);
      
      resultsMap[barcode] = result.toJson();
      _prefs.setString(_cachedAnalysisKey, json.encode(resultsMap));
    } catch (e) {
      print('Error caching analysis: $e');
    }
  }
  
  String _buildProductAnalysisPrompt({
    required String productName,
    required String ingredients,
    required String nutriScore,
    required Map<String, dynamic> nutrients,
    required List<String> allergens,
    required List<String> goals,
    required List<String> avoid,
    required String userName,
  }) {
    final nutrientsText = nutrients.entries
        .where((e) => e.value != null)
        .map((e) => "${e.key}: ${e.value.toString().toUpperCase()}")
        .join(', ');
        
    return '''
You are a nutrition assistant for HealthyChoice app. Based on the product information and user preferences below, provide a personalized analysis:

PRODUCT INFORMATION:
- Name: $productName
- Ingredients: $ingredients
- Nutri-Score: $nutriScore 
- Nutrient Levels: $nutrientsText

USER PREFERENCES:
- Name: $userName
- Allergens to avoid: ${allergens.join(', ')}
- Health goals: ${goals.join(', ')}
- Trying to avoid: ${avoid.join(', ')}

IMPORTANT ANALYSIS GUIDELINES:
1. When evaluating products containing sugar for users with heart disease or diabetes:
   - Compare to daily recommended intake (25g/day for women, 36g/day for men)
   - Consider serving size and realistic consumption amount
   - Only mark as "not safe" if the product would significantly exceed daily recommended intake
   - Provide context about moderation rather than absolute avoidance

2. For all ingredients that users are trying to avoid:
   - Consider the quantity and concentration in the product
   - Evaluate based on recommended daily limits, not mere presence
   - Suggest moderation rather than complete avoidance when appropriate

3. Focus on practical nutrition advice that acknowledges:
   - Occasional consumption may be acceptable for most ingredients
   - The overall dietary pattern matters more than individual products
   - Health conditions require moderation, not necessarily elimination

Please provide a JSON response with the following structure:
{
  "compatibility": "good", // Can be "good", "moderate", or "poor"
  "explanation": "A nuanced explanation of the compatibility assessment",
  "isSafeForUser": true, // Boolean indicating if this product is safe in moderation
  "safetyReason": "Context-aware explanation about safety in appropriate amounts",
  "recommendations": ["List of recommendations or alternatives"],
  "healthInsights": ["Balanced insights about this product"],
  "nutritionalValues": {
    "energy": 250, // Estimated calorie value per 100g in kcal
    "sugars": 12.5, // Estimated sugar content per 100g in grams
    "sodium": 400, // Estimated sodium content per 100g in mg
    "fats": 5.2, // Estimated fat content per 100g in grams
    "saturatedFats": 2.1, // Estimated saturated fat content per 100g in grams
    "protein": 3.5, // Estimated protein content per 100g in grams
    "carbs": 30, // Estimated carbohydrate content per 100g in grams
    "fiber": 1.2 // Estimated fiber content per 100g in grams
  },
  "servingSizeInfo": {
    "servingSize": "30g", // Typical serving size if available
    "servingsPerContainer": 10, // Number of servings if available
    "sugarPerServing": 3.75, // Sugar per typical serving in grams
    "percentOfDailyRecommended": 15 // Percent of recommended daily intake per serving
  },
  "alternatives": [
    {
      "name": "Specific product name as alternative",
      "reason": "Brief reason why this is a better alternative",
      "nutritionalBenefits": "Key nutritional advantages",
      "imageUrl": null
    }
  ]
}

FOR SUGAR CONTENT EVALUATION:
- If a product contains 15g sugar per 100g, but a typical serving is 30g, then one serving provides only 4.5g sugar
- This would be 18% of a woman's and 12.5% of a man's recommended daily limit
- Such a product should NOT be classified as "unsafe" for heart disease patients when consumed in normal portions
- Instead, note that moderate consumption is acceptable while suggesting lower-sugar alternatives

Provide 2-3 actionable recommendations and balanced health insights.
If suggesting alternatives, be specific with real product names that are commonly available.
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
    await _ensureInitialized();
    
    // Check for cached alternatives
    final cachedAlternatives = _getCachedAlternatives(barcode);
    if (cachedAlternatives != null) {
      return cachedAlternatives;
    }
    
    // Get user preferences from SharedPreferences
    final userName = _prefs.getString('full_name') ?? 'User';
    final allergens = _prefs.getStringList('allergens') ?? [];
    final goals = _prefs.getStringList('goals') ?? [];
    final avoid = _prefs.getStringList('avoid') ?? [];
    
    // Extract product information
    final productName = productData['product_name'] ?? 'Unknown Product';
    final category = productData['categories'] ?? '';
    final brand = productData['brands'] ?? '';
    final ingredients = productData['ingredients_text'] ?? 'No ingredient information available';
    final nutrients = productData['nutriments'] ?? {};
    
    // Prepare prompt specifically for alternatives
    final prompt = _buildAlternativesPrompt(
      productName: productName,
      category: category,
      brand: brand,
      ingredients: ingredients,
      nutrients: nutrients,
      allergens: allergens,
      goals: goals,
      avoid: avoid,
      userName: userName
    );
    
    try {
      final alternatives = await _fetchAlternativesFromGemini(prompt);
      
      // Cache the result
      _cacheAlternatives(barcode, alternatives);
      
      return alternatives;
    } catch (e) {
      print('Gemini Alternatives API Error: $e');
      // Return a default list in case of error
      return [
        {
          'product_name': 'Healthy Alternative (Similar to ${productName.split(' ').take(3).join(' ')})',
          'image_url': 'https://images.unsplash.com/photo-1550583724-b2692b85b150?ixlib=rb-1.2.1&auto=format&fit=crop&w=100&q=80',
          'nutriscore_grade': 'A',
          'brand': 'Health Choice',
          'description': 'A healthier alternative aligned with your dietary preferences.'
        }
      ];
    }
  }
  
  void _cacheAlternatives(String barcode, List<Map<String, dynamic>> alternatives) {
    try {
      final cachedAlternatives = _prefs.getString(_cachedAlternativesKey) ?? '{}';
      final Map<String, dynamic> alternativesMap = json.decode(cachedAlternatives);
      
      alternativesMap[barcode] = alternatives;
      _prefs.setString(_cachedAlternativesKey, json.encode(alternativesMap));
    } catch (e) {
      print('Error caching alternatives: $e');
    }
  }
  
  List<Map<String, dynamic>>? _getCachedAlternatives(String barcode) {
    try {
      final cachedAlternatives = _prefs.getString(_cachedAlternativesKey) ?? '{}';
      final Map<String, dynamic> alternativesMap = json.decode(cachedAlternatives);
      
      if (alternativesMap.containsKey(barcode)) {
        final List<dynamic> altList = alternativesMap[barcode];
        return altList.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      print('Error retrieving cached alternatives: $e');
    }
    return null;
  }
  
  String _buildAlternativesPrompt({
    required String productName,
    required String category,
    required String brand,
    required String ingredients,
    required Map<String, dynamic> nutrients,
    required List<String> allergens,
    required List<String> goals,
    required List<String> avoid,
    required String userName,
  }) {
    return '''
You are a nutrition assistant for HealthyChoice app. Based on the product information and user preferences below, suggest healthier alternative products:

PRODUCT INFORMATION:
- Name: $productName
- Category: $category
- Brand: $brand
- Ingredients: $ingredients

USER PREFERENCES:
- Name: $userName
- Allergens to avoid: ${allergens.join(', ')}
- Health goals: ${goals.join(', ')}
- Trying to avoid: ${avoid.join(', ')}

Please provide a JSON array of alternative products with the following structure:
[
  {
    "product_name": "Specific product name as alternative",
    "brand": "Brand name of the alternative product",
    "nutriscore_grade": "A", // Estimate Nutri-Score grade (A-E)
    "description": "Brief reason why this is a better alternative",
    "image_url": "https://example.com/product-image.jpg" // URL to product image if available
  }
]

Provide 3-4 specific alternative products that would better align with the user's health goals. 
Be specific with real product names that are commonly available, not generic suggestions.
Each alternative should be a real product that is likely to be found in major grocery stores or health food stores.
The alternatives should be in the same category as the original product but healthier according to the user's preferences.

If the user is avoiding specific ingredients like salt, sugar, or additives, prioritize alternatives that have reduced amounts or are free from these ingredients.
If the user has allergens, ensure all alternatives are free from those allergens.
If the user has specific health goals like "weight loss" or "heart health", suggest products that support these goals.

For the image URLs, if you're not certain of a specific product image, you can use:
- https://images.unsplash.com/photo-1576186215879-9ca1fb10c541 (for packaged foods)
- https://images.unsplash.com/photo-1573246123716-6b1782bfc499 (for healthy products)
- https://images.unsplash.com/photo-1604329760661-e71dc83f8f26 (for organic products)
- https://images.unsplash.com/photo-1545601445-4d6a0a0565f0 (for dairy alternatives)
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