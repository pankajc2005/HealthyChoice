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
    // Get user preferences from SharedPreferences
    final userName = _prefs.getString('full_name') ?? 'User';
    final allergens = _prefs.getStringList('allergens') ?? [];
    final goals = _prefs.getStringList('goals') ?? [];
    final avoid = _prefs.getStringList('avoid') ?? [];
    
    // Check cache first
    final cacheKey = '${barcode}_analysis';
    final cachedResult = _checkCache(cacheKey);
    if (cachedResult != null) return cachedResult;
    
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
      _cacheResult(cacheKey, analysisResult);
      
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

Please provide a JSON response with the following structure:
{
  "compatibility": "good", // Can be "good", "moderate", or "poor"
  "explanation": "A brief explanation of the compatibility assessment",
  "isSafeForUser": true, // Explicit boolean indicating if this product is safe for the user
  "safetyReason": "Clear explanation why this product is safe or unsafe for this specific user",
  "recommendations": ["List of recommendations or alternatives"],
  "healthInsights": ["List of health insights about this product"],
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
  "alternatives": [
    {
      "name": "Specific product name as alternative",
      "reason": "Brief reason why this is a better alternative",
      "nutritionalBenefits": "Key nutritional advantages",
      "imageUrl": "https://example.com/product-image.jpg" // URL to product image if available
    }
  ]
}

Focus on how this product aligns with the user's specific health goals and preferences. 
Base the "isSafeForUser" field on whether the product contains any allergens the user is avoiding, conflicts with their health goals, or contains ingredients they are trying to avoid.
For the "nutritionalValues" section, provide your best estimates of the nutrient content based on the ingredients and any information provided. These values should be per 100g of the product and include clear units.
Provide 2-3 actionable recommendations and health insights.

If the compatibility is "moderate" or "poor", always suggest 2-3 specific alternative products that would better align with the user's health goals. Be specific with real product names that are commonly available, not generic suggestions.

For the alternative products, try to include an image URL if you know of a publicly available image of the product. The image URL should be a direct link to a product image. If you don't have a specific image URL, leave the imageUrl field empty or null.
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
    // Get user preferences from SharedPreferences
    final userName = _prefs.getString('full_name') ?? 'User';
    final allergens = _prefs.getStringList('allergens') ?? [];
    final goals = _prefs.getStringList('goals') ?? [];
    final avoid = _prefs.getStringList('avoid') ?? [];
    
    // Check cache first unless force fetch is requested
    final cacheKey = '${barcode}_alternatives';
    if (!forceFetch) {
      final cachedResult = _checkAlternativesCache(cacheKey);
      if (cachedResult != null) return cachedResult;
    }
    
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
      _cacheAlternatives(cacheKey, alternatives);
      
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