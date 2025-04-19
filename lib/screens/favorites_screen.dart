import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_service.dart';
import '../models/product_scan.dart';
import 'results_page.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({Key? key}) : super(key: key);

  @override
  _FavoritesScreenState createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _favoriteProducts = [];
  static const String _favoritesKey = 'favorite_products';

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final favoriteProductCodes = prefs.getStringList(_favoritesKey) ?? [];
      
      List<Map<String, dynamic>> products = [];
      
      // Load each product data
      for (String barcode in favoriteProductCodes) {
        try {
          final productData = await ApiService.getProductInfo(barcode);
          products.add({
            'barcode': barcode,
            'data': productData,
          });
        } catch (e) {
          print('Error loading product $barcode: $e');
        }
      }
      
      setState(() {
        _favoriteProducts = products;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading favorites: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _removeFromFavorites(String barcode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoriteProducts = prefs.getStringList(_favoritesKey) ?? [];
      
      favoriteProducts.remove(barcode);
      await prefs.setStringList(_favoritesKey, favoriteProducts);
      
      setState(() {
        _favoriteProducts.removeWhere((product) => product['barcode'] == barcode);
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Removed from favorites'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('Error removing from favorites: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Favorite Products'),
        centerTitle: true,
        backgroundColor: Color(0xFF6D30EA),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _favoriteProducts.isEmpty
              ? _buildEmptyFavorites()
              : _buildFavoritesList(),
    );
  }

  Widget _buildEmptyFavorites() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'No favorites yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Tap the heart icon on products to add them to favorites',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesList() {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _favoriteProducts.length,
      itemBuilder: (context, index) {
        final productInfo = _favoriteProducts[index];
        final barcode = productInfo['barcode'];
        final productData = productInfo['data'];
        
        return _buildProductCard(barcode, productData);
      },
    );
  }

  Widget _buildProductCard(String barcode, Map<String, dynamic> productData) {
    final productName = productData['product_name'] ?? 'Unknown Product';
    final brand = productData['brands'] ?? '';
    final imageUrl = productData['image_url'];
    final nutriScore = productData['nutriscore_grade']?.toUpperCase() ?? '';
    
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context, 
            MaterialPageRoute(
              builder: (context) => ResultsPage(barcode: barcode),
            ),
          ).then((_) => _loadFavorites());
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: imageUrl != null
                    ? Image.network(
                        imageUrl,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 80,
                            height: 80,
                            color: Colors.grey.shade200,
                            child: Icon(
                              Icons.image_not_supported,
                              color: Colors.grey,
                            ),
                          );
                        },
                      )
                    : Container(
                        width: 80,
                        height: 80,
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
                      productName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    if (brand.isNotEmpty)
                      Text(
                        brand,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        if (nutriScore.isNotEmpty)
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
                        Spacer(),
                        IconButton(
                          icon: Icon(Icons.favorite, color: Colors.red),
                          onPressed: () => _removeFromFavorites(barcode),
                          tooltip: 'Remove from favorites',
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(),
                        ),
                      ],
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