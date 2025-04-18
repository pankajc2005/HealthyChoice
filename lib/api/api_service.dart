import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String _baseUrl = 'https://world.openfoodfacts.org/api/v0/product/';
  static const String _searchUrl = 'https://world.openfoodfacts.org/cgi/search.pl';

  static Future<Map<String, dynamic>> getProductInfo(String barcode) async {
    final isBarcode = RegExp(r'^\d+$').hasMatch(barcode);
    Uri url;

    if (isBarcode) {
      url = Uri.parse('https://world.openfoodfacts.org/api/v0/product/$barcode.json');
    } else {
      final searchUrl = Uri.parse('https://world.openfoodfacts.org/cgi/search.pl?search_terms=$barcode&search_simple=1&action=process&json=1');
      final searchResponse = await http.get(searchUrl);

      if (searchResponse.statusCode != 200) {
        throw Exception("Failed to search by name");
      }

      final searchData = json.decode(searchResponse.body);
      if (searchData['products'] != null && searchData['products'].isNotEmpty) {
        final firstProduct = searchData['products'][0];
        final code = firstProduct['code'];
        url = Uri.parse('https://world.openfoodfacts.org/api/v0/product/$code.json');
      } else {
        throw Exception("No product found with name");
      }
    }

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 1) {
        return data['product'] ?? {};
      } else {
        throw Exception("Product not found");
      }
    } else {
      throw Exception("Failed to fetch product data");
    }
  }

  /// ✅ ADD THIS METHOD FOR SEARCH SUGGESTIONS
  static Future<List<String>> getSuggestions(String query) async {
    final url = Uri.parse('https://world.openfoodfacts.org/cgi/search.pl?search_terms=$query&search_simple=1&action=process&json=1');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final products = data['products'] as List<dynamic>;
      return products
          .map<String>((item) => item['product_name']?.toString() ?? '')
          .where((name) => name.isNotEmpty)
          .toSet()
          .toList();
    } else {
      throw Exception("Failed to fetch suggestions");
    }
  }

  /// Fetches an image URL for a product based on name and category
  static Future<String?> getProductImageUrl(String productName, {String? category}) async {
    try {
      // Strategy 1: Search Open Food Facts by product name
      final searchUri = Uri.parse('$_searchUrl?search_terms=${Uri.encodeComponent(productName)}&search_simple=1&action=process&json=1');
      final searchResponse = await http.get(searchUri);
      
      if (searchResponse.statusCode == 200) {
        final searchData = json.decode(searchResponse.body);
        if (searchData['products'] != null && searchData['products'].isNotEmpty) {
          // Find the first product with an image
          for (var product in searchData['products']) {
            if (product['image_url'] != null && product['image_url'].toString().isNotEmpty) {
              return product['image_url'];
            }
            
            // Try image front URL if main image is missing
            if (product['image_front_url'] != null && product['image_front_url'].toString().isNotEmpty) {
              return product['image_front_url'];
            }
          }
        }
      }
      
      // Strategy 2: Try with category to narrow down search
      if (category != null && category.isNotEmpty) {
        final categorySearchUri = Uri.parse(
          '$_searchUrl?search_terms=${Uri.encodeComponent(productName)}&tagtype_0=categories&tag_contains_0=contains&tag_0=${Uri.encodeComponent(category)}&action=process&json=1'
        );
        
        final categoryResponse = await http.get(categorySearchUri);
        if (categoryResponse.statusCode == 200) {
          final categoryData = json.decode(categoryResponse.body);
          if (categoryData['products'] != null && categoryData['products'].isNotEmpty) {
            for (var product in categoryData['products']) {
              if (product['image_url'] != null && product['image_url'].toString().isNotEmpty) {
                return product['image_url'];
              }
            }
          }
        }
      }
      
      // Strategy 3: Fallback to placeholder based on category
      if (category != null) {
        // Return category-specific placeholder images
        switch (category.toLowerCase()) {
          case 'dairy':
          case 'milk':
          case 'yogurt':
            return 'https://images.openfoodfacts.org/images/categories/en:dairy-products.100x100.jpg';
          case 'cereal':
          case 'breakfast':
            return 'https://images.openfoodfacts.org/images/categories/en:breakfast-cereals.100x100.jpg';
          case 'snack':
          case 'chips':
          case 'crackers':
            return 'https://images.openfoodfacts.org/images/categories/en:snacks.100x100.jpg';
          case 'beverage':
          case 'drink':
          case 'juice':
            return 'https://images.openfoodfacts.org/images/categories/en:beverages.100x100.jpg';
          case 'fruit':
          case 'vegetable':
            return 'https://images.openfoodfacts.org/images/categories/en:fruits-and-vegetables.100x100.jpg';
          default:
            return 'https://images.openfoodfacts.org/images/categories/en:foods.100x100.jpg';
        }
      }
      
      // If all strategies fail, return a generic food placeholder
      return 'https://images.openfoodfacts.org/images/categories/en:foods.100x100.jpg';
    } catch (e) {
      print('Error fetching product image: $e');
      // Return a generic placeholder in case of errors
      return 'https://images.openfoodfacts.org/images/categories/en:foods.100x100.jpg';
    }
  }
}
