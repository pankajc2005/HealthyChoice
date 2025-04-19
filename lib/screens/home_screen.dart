import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import '../api/api_service.dart';
import '../models/product_scan.dart';
import '../services/scan_history_service.dart';
import '../services/cart_service.dart';
import '../widgets/allergen_filter_chip.dart';
import '../widgets/recent_scan_item.dart';
import 'camera_screen.dart';
import 'results_page.dart';
import 'models_info_screen.dart';
import 'cart_screen.dart';
import 'alternative_product_screen.dart';
import 'favorites_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  int _cartCount = 0;

  final List<Map<String, dynamic>> allergenFilters = [
    {'label': 'Gluten Free', 'status': 'safe', 'icon': Icons.check, 'color': Colors.green},
    {'label': 'Dairy', 'status': 'caution', 'icon': Icons.warning, 'color': Colors.orange},
    {'label': 'Peanuts', 'status': 'danger', 'icon': Icons.close, 'color': Colors.red},
    {'label': 'Soy', 'status': 'safe', 'icon': Icons.check, 'color': Colors.green},
    {'label': 'Shellfish', 'status': 'danger', 'icon': Icons.close, 'color': Colors.red},
  ];

  List<ProductScan> _recentScans = [];
  bool _isLoadingScans = true;

  @override
  void initState() {
    super.initState();
    _loadRecentScans();
    _loadCartCount();
  }

  Future<void> _loadCartCount() async {
    final count = await CartService.getCartCount();
    setState(() {
      _cartCount = count;
    });
  }

  Future<void> _loadRecentScans() async {
    setState(() {
      _isLoadingScans = true;
    });
    
    final scans = await ScanHistoryService.getRecentScans();
    
    setState(() {
      _recentScans = scans;
      _isLoadingScans = false;
    });
  }

  void _removeScan(ProductScan scan) async {
    final currentScans = await ScanHistoryService.getRecentScans();
    final updatedScans = currentScans.where((s) => 
      s.barcode != scan.barcode || s.scanDate != scan.scanDate).toList();
    
    await ScanHistoryService.clearScanHistory();
    for (var scan in updatedScans) {
      await ScanHistoryService.saveProductScan(scan);
    }
    
    _loadRecentScans();
  }

  void _searchProduct(String query) async {
    if (query.isEmpty) return;
    
    // Show loading indicator in the UI
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // Trim and clean up the query
      final cleanQuery = query.trim();
      
      // Check if query might be a barcode
      bool mightBeBarcode = cleanQuery.length >= 8 && 
                           cleanQuery.length <= 13 && 
                           RegExp(r'^\d+$').hasMatch(cleanQuery);
      
      if (mightBeBarcode) {
        // Direct search with barcode
        final productData = await ApiService.getProductInfo(cleanQuery);
        if (!mounted) return;
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResultsPage(barcode: cleanQuery),
          ),
        );
      } else {
        // Show a temporary loading snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20, 
                  height: 20, 
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
                SizedBox(width: 12),
                Text('Searching for "$cleanQuery"...'),
              ],
            ),
            duration: Duration(seconds: 1),
          ),
        );
        
        // Search by product name
        final productData = await ApiService.getProductInfo(cleanQuery);
        if (!mounted) return;
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResultsPage(barcode: cleanQuery),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      
      setState(() => _errorMessage = "Product not found. Try a different search term.");
      
      // Show a more helpful error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not find "$query". Try scanning the barcode instead.'),
          action: SnackBarAction(
            label: 'SCAN',
            onPressed: _openCamera,
          ),
          duration: Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _openCamera() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ScanPage()),
    );

    if (result != null) {
      print('Scanned Barcode: $result');
      _loadRecentScans();
      _loadCartCount();
    }
  }

  void _openCart() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CartScreen()),
    );
    
    _loadCartCount();
  }

  void _openAlternatives(String barcode) async {
    try {
      final productData = await ApiService.getProductInfo(barcode);
      
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AlternativeProductScreen(
            barcode: barcode,
            productData: productData,
          ),
        ),
      );
      
      _loadCartCount();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading product information')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 360;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ App Bar with Search
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'HealthyChoice',
                          style: TextStyle(
                            color: Color(0xFF6D30EA),
                            fontSize: isSmallScreen ? 24 : 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.info_outline, color: Colors.black),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => ModelsInfoScreen()),
                                );
                              },
                              tooltip: 'View Available AI Models',
                            ),
                            IconButton(
                              icon: Icon(Icons.favorite_outline, color: Colors.black),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => FavoritesScreen()),
                                );
                              },
                              tooltip: 'Favorites',
                            ),
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.shopping_cart_outlined, color: Colors.black),
                                  onPressed: _openCart,
                                  tooltip: 'Shopping Cart',
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
                            IconButton(
                              icon: Icon(Icons.notifications_none, color: Colors.black),
                              onPressed: () {},
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(30),
                      child: TypeAheadField<String>(
                        textFieldConfiguration: TextFieldConfiguration(
                          controller: _searchController,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            hintText: 'Search products or scan barcode',
                            prefixIcon: Icon(Icons.search),
                            suffixIcon: IconButton(
                              icon: Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                              },
                            ),
                            border: InputBorder.none,
                          ),
                          onSubmitted: (value) {
                            if (value.isNotEmpty) {
                              _searchProduct(value);
                            }
                          },
                        ),
                        suggestionsCallback: (pattern) async {
                          if (pattern.length < 3) return [];
                          return await ApiService.getSuggestions(pattern);
                        },
                        itemBuilder: (context, suggestion) => ListTile(
                          title: Text(suggestion),
                          leading: Icon(Icons.fastfood, color: Color(0xFF6D30EA)),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        ),
                        onSuggestionSelected: (suggestion) {
                          _searchController.text = suggestion;
                          _searchProduct(suggestion);
                        },
                        noItemsFoundBuilder: (context) => Container(
                          height: 50,
                          child: Center(
                            child: Text('No products found. Press enter to search.'),
                          ),
                        ),
                        loadingBuilder: (context) => Container(
                          height: 50,
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF6D30EA),
                            ),
                          ),
                        ),
                        keepSuggestionsOnLoading: false,
                        hideSuggestionsOnKeyboardHide: false,
                        hideOnEmpty: false,
                        hideOnError: false,
                        animationDuration: Duration(milliseconds: 300),
                      ),
                    ),
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
              ),

              // ✅ Main Banner
              Container(
                width: double.infinity,
                height: isSmallScreen ? 120 : 160,
                margin: const EdgeInsets.symmetric(horizontal: 16.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF6D30EA), Color(0xFF9B59B6)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -20,
                      bottom: -20,
                      child: Icon(
                        Icons.qr_code_scanner,
                        size: isSmallScreen ? 100 : 120,
                        color: Colors.white.withOpacity(0.2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Scan Your Food',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isSmallScreen ? 24 : 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Check ingredients and allergens instantly',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: isSmallScreen ? 14 : 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ✅ Recent Scans
              _buildRecentScansSection(),
            ],
          ),
        ),
      ),

      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (_recentScans.isNotEmpty)
            FloatingActionButton(
              heroTag: 'buy_button',
              onPressed: () {
                _openAlternatives(_recentScans.first.barcode);
              },
              backgroundColor: Colors.green,
              child: const Icon(Icons.shopping_bag, color: Colors.white),
              mini: true,
              tooltip: 'Find Better Products',
            ),
          const SizedBox(height: 10),
          FloatingActionButton.extended(
            heroTag: 'scan_button',
            onPressed: _openCamera,
            backgroundColor: const Color(0xFF6D30EA),
            icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
            label: const Text(
              'Scan Product',
              style: TextStyle(color: Colors.white),
            ),
            elevation: 4,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentScansSection() {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 360;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Scans',
                style: TextStyle(
                  fontSize: isSmallScreen ? 20 : 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_recentScans.isNotEmpty)
                TextButton(
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Clear History'),
                        content: Text('Are you sure you want to clear all scan history?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text('CANCEL'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: Text('CLEAR'),
                          ),
                        ],
                      ),
                    );
                    
                    if (confirmed == true) {
                      await ScanHistoryService.clearScanHistory();
                      _loadRecentScans();
                    }
                  },
                  child: Text(
                    'Clear All',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 14,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        
        if (_isLoadingScans)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_recentScans.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Icon(
                    Icons.history,
                    size: 48,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'No recent scans',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Scanned products will appear here',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _recentScans.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ResultsPage(barcode: _recentScans[index].barcode),
                      ),
                    );
                  },
                  child: RecentScanItem(
                    scan: _recentScans[index],
                    isSmallScreen: isSmallScreen,
                    onDelete: () => _removeScan(_recentScans[index]),
                    onBuy: () => _openAlternatives(_recentScans[index].barcode),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
