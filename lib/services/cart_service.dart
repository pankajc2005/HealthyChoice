import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/analysis_result.dart';

class CartItem {
  final String name;
  final String? imageUrl;
  final String description;
  final int quantity;
  final String nutriScore;

  CartItem({
    required this.name,
    this.imageUrl,
    required this.description,
    required this.quantity,
    required this.nutriScore,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      name: json['name'] ?? 'Unknown Product',
      imageUrl: json['imageUrl'],
      description: json['description'] ?? '',
      quantity: json['quantity'] ?? 1,
      nutriScore: json['nutriScore'] ?? 'Unknown',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'imageUrl': imageUrl,
      'description': description,
      'quantity': quantity,
      'nutriScore': nutriScore,
    };
  }

  CartItem copyWith({
    String? name,
    String? imageUrl,
    String? description,
    int? quantity,
    String? nutriScore,
  }) {
    return CartItem(
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      nutriScore: nutriScore ?? this.nutriScore,
    );
  }
}

class CartService {
  static const String _cartKey = 'user_cart';
  
  // Add item to cart
  static Future<void> addToCart(CartItem item) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartItems = await getCartItems();
      
      // Check if product already exists
      int existingIndex = cartItems.indexWhere((existing) => existing.name == item.name);
      
      if (existingIndex >= 0) {
        // Update quantity if item exists
        CartItem existing = cartItems[existingIndex];
        cartItems[existingIndex] = existing.copyWith(quantity: existing.quantity + item.quantity);
      } else {
        // Add new item
        cartItems.add(item);
      }
      
      // Convert to JSON list and save
      final jsonList = cartItems.map((item) => item.toJson()).toList();
      await prefs.setString(_cartKey, jsonEncode(jsonList));
    } catch (e) {
      print('Error adding to cart: $e');
    }
  }

  // Get all cart items
  static Future<List<CartItem>> getCartItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_cartKey);
      
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }
      
      final jsonList = jsonDecode(jsonString) as List;
      return jsonList.map((json) => CartItem.fromJson(json)).toList();
    } catch (e) {
      print('Error retrieving cart: $e');
      return [];
    }
  }
  
  // Update cart item quantity
  static Future<void> updateQuantity(String productName, int quantity) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartItems = await getCartItems();
      
      int index = cartItems.indexWhere((item) => item.name == productName);
      if (index >= 0) {
        if (quantity <= 0) {
          // Remove item if quantity is 0 or less
          cartItems.removeAt(index);
        } else {
          // Update quantity
          cartItems[index] = cartItems[index].copyWith(quantity: quantity);
        }
        
        // Save updated cart
        final jsonList = cartItems.map((item) => item.toJson()).toList();
        await prefs.setString(_cartKey, jsonEncode(jsonList));
      }
    } catch (e) {
      print('Error updating cart: $e');
    }
  }
  
  // Remove item from cart
  static Future<void> removeFromCart(String productName) async {
    await updateQuantity(productName, 0);
  }
  
  // Clear entire cart
  static Future<void> clearCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cartKey);
    } catch (e) {
      print('Error clearing cart: $e');
    }
  }
  
  // Get cart count
  static Future<int> getCartCount() async {
    final items = await getCartItems();
    int total = 0;
    for (var item in items) {
      total += item.quantity;
    }
    return total;
  }
  
  // Add AlternativeProduct to cart
  static Future<void> addAlternativeToCart(AlternativeProduct product, String nutriScore) async {
    CartItem cartItem = CartItem(
      name: product.name,
      imageUrl: product.imageUrl,
      description: product.reason,
      quantity: 1,
      nutriScore: nutriScore,
    );
    
    await addToCart(cartItem);
  }
} 