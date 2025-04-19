import 'package:flutter/material.dart';
import '../models/analysis_result.dart';
import '../services/cart_service.dart';
import '../services/gemini_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AlternativeProductScreen extends StatefulWidget {
  final String barcode;
  final Map<String, dynamic> productData;
  
  const AlternativeProductScreen({
    Key? key,
    required this.barcode,
    required this.productData,
  }) : super(key: key);

  @override
  _AlternativeProductScreenState createState() => _AlternativeProductScreenState();
}

class _AlternativeProductScreenState extends State<AlternativeProductScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _alternatives = [];
  int _cartCount = 0;

  @override
  void initState() {
    super.initState();
    _loadAlternatives();
    _getCartCount();
  }

  Future<void> _getCartCount() async {
    final count = await CartService.getCartCount();
    setState(() {
      _cartCount = count;
    });
  }

  Future<void> _loadAlternatives() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get preferences instance for GeminiService
      final prefs = await SharedPreferences.getInstance();
      final geminiService = GeminiService(prefs);
      
      // Load alternatives
      final alternatives = await geminiService.getSuggestedAlternatives(
        widget.productData,
        widget.barcode,
      );
      
      setState(() {
        _alternatives = alternatives;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading alternatives: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addToCart(Map<String, dynamic> product) async {
    final item = CartItem(
      name: product['product_name'] ?? 'Unknown Product',
      imageUrl: product['image_url'],
      description: product['description'] ?? '',
      quantity: 1,
      nutriScore: product['nutriscore_grade'] ?? 'Unknown',
    );
    
    await CartService.addToCart(item);
    _showAddedToCartSnackbar(item.name);
    _getCartCount();
  }
  
  void _showAddedToCartSnackbar(String productName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$productName added to cart'),
        duration: Duration(seconds: 2),
        action: SnackBarAction(
          label: 'VIEW CART',
          onPressed: () {
            // Navigate to cart screen (implement later)
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productName = widget.productData['product_name'] ?? 'Unknown Product';
    final nutriScore = widget.productData['nutriscore_grade']?.toUpperCase() ?? 'Unknown';
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Alternative Products'),
        centerTitle: true,
        backgroundColor: Color(0xFF6D30EA),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.shopping_cart),
                onPressed: () {
                  // Navigate to cart screen (implement later)
                },
              ),
              if (_cartCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$_cartCount',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Original product info banner
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF6D30EA), Color(0xFF9B59B6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Alternatives For',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  productName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getNutriScoreColor(nutriScore),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Nutri-Score $nutriScore',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Alternatives heading
          Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Healthier Alternatives',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: _loadAlternatives,
                  icon: Icon(Icons.refresh, size: 16),
                  label: Text('Refresh'),
                  style: TextButton.styleFrom(
                    foregroundColor: Color(0xFF6D30EA),
                  ),
                ),
              ],
            ),
          ),
          
          // Main content
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _alternatives.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No alternatives found',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Try refreshing or scanning another product',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.all(16),
                        itemCount: _alternatives.length,
                        itemBuilder: (context, index) {
                          final alternative = _alternatives[index];
                          return _buildAlternativeCard(alternative);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlternativeCard(Map<String, dynamic> alternative) {
    final name = alternative['product_name'] ?? 'Unknown Product';
    final brand = alternative['brand'] ?? '';
    final description = alternative['description'] ?? '';
    final nutriScore = alternative['nutriscore_grade']?.toUpperCase() ?? 'Unknown';
    final imageUrl = alternative['image_url'];
    
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product image
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: imageUrl != null && imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 100,
                              height: 100,
                              color: Colors.grey.shade200,
                              child: Icon(
                                Icons.image_not_supported,
                                color: Colors.grey,
                              ),
                            );
                          },
                        )
                      : Container(
                          width: 100,
                          height: 100,
                          color: Colors.grey.shade200,
                          child: Icon(
                            Icons.image,
                            color: Colors.grey,
                          ),
                        ),
                ),
                SizedBox(width: 16),
                
                // Product details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (brand.isNotEmpty) ...[
                        SizedBox(height: 4),
                        Text(
                          brand,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                      SizedBox(height: 8),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getNutriScoreColor(nutriScore),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Nutri-Score $nutriScore',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            // Description & why better
            if (description.isNotEmpty) ...[
              SizedBox(height: 16),
              Text(
                'Why it\'s better:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ],
            
            // Actions
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    // Implement save for later functionality
                  },
                  icon: Icon(Icons.bookmark_border, size: 18),
                  label: Text('Save'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Color(0xFF6D30EA),
                  ),
                ),
                SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => _addToCart(alternative),
                  icon: Icon(Icons.shopping_cart, size: 18),
                  label: Text('Add to Cart'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF6D30EA),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Color _getNutriScoreColor(String score) {
    switch (score.toUpperCase()) {
      case 'A':
        return Colors.green;
      case 'B':
        return Color(0xFF85BB2F);
      case 'C':
        return Color(0xFFFFCC00);
      case 'D':
        return Color(0xFFFF9900);
      case 'E':
        return Color(0xFFFF0000);
      default:
        return Colors.grey;
    }
  }
} 