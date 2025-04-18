import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/analysis_result.dart';

class AlternativeProductsSection extends StatelessWidget {
  final List<AlternativeProduct> alternatives;
  
  const AlternativeProductsSection({
    Key? key,
    required this.alternatives,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (alternatives.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF0F8FF),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.swap_horiz, color: Color(0xFF6D30EA)),
              const SizedBox(width: 8),
              Text(
                "Better Alternatives",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6D30EA),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Description
          const Text(
            "Based on your health goals, these products may be better options:",
            style: TextStyle(fontSize: 14, color: Colors.black54),
          ),
          const SizedBox(height: 16),
          
          // Alternatives list
          ...alternatives.map((alt) => _buildAlternativeItem(alt, context)).toList(),
        ],
      ),
    );
  }
  
  Widget _buildAlternativeItem(AlternativeProduct alternative, BuildContext context) {
    final hasImage = alternative.imageUrl != null && alternative.imageUrl!.isNotEmpty;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: IntrinsicHeight(  // Ensures both columns have same height
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image
            if (hasImage)
              GestureDetector(
                onTap: () => _showImageDialog(context, alternative),
                child: Hero(
                  tag: 'product_image_${alternative.name}',
                  child: Container(
                    width: 85,
                    height: 85,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: alternative.imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey.shade200,
                          child: const Center(
                            child: SizedBox(
                              width: 30,
                              height: 30,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF6D30EA),
                              ),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey.shade200,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.image_not_supported, color: Colors.grey),
                                const SizedBox(height: 4),
                                Text(
                                  "No Image",
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            
            // Spacing between image and text
            if (hasImage) const SizedBox(width: 12),
            
            // Product details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product name
                  Text(
                    alternative.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  
                  // Reason
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Why: ",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          alternative.reason,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  
                  // Nutritional benefits if available
                  if (alternative.nutritionalBenefits != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Benefits: ",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            alternative.nutritionalBenefits!,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ],
                  
                  // Search button
                  Align(
                    alignment: Alignment.bottomRight,
                    child: TextButton.icon(
                      onPressed: () {
                        // Handle searching for this product
                        _searchForProduct(context, alternative.name);
                      },
                      icon: Icon(Icons.search, size: 16, color: Color(0xFF6D30EA)),
                      label: Text(
                        "Find Product",
                        style: TextStyle(
                          color: Color(0xFF6D30EA),
                          fontSize: 12,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                        minimumSize: Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showImageDialog(BuildContext context, AlternativeProduct product) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: Text(
                  product.name,
                  style: TextStyle(fontSize: 16),
                ),
                backgroundColor: Color(0xFF6D30EA),
                foregroundColor: Colors.white,
                elevation: 0,
                leading: IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              Hero(
                tag: 'product_image_${product.name}',
                child: CachedNetworkImage(
                  imageUrl: product.imageUrl!,
                  fit: BoxFit.contain,
                  height: 300,
                  width: double.infinity,
                  placeholder: (context, url) => SizedBox(
                    height: 300,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF6D30EA),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => SizedBox(
                    height: 300,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 48, color: Colors.grey),
                          SizedBox(height: 16),
                          Text("Image not available"),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    if (product.nutritionalBenefits != null) ...[
                      Text(
                        "Nutritional Benefits:",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(product.nutritionalBenefits!),
                      SizedBox(height: 8),
                    ],
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _searchForProduct(context, product.name);
                      },
                      icon: Icon(Icons.search),
                      label: Text("Search for this product"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF6D30EA),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  void _searchForProduct(BuildContext context, String productName) {
    // Show a snackbar to indicate we're searching
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Searching for "$productName"...'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
    
    // Launch a web search
    _launchSearch(productName);
  }
  
  Future<void> _launchSearch(String query) async {
    final url = Uri.parse('https://www.google.com/search?q=${Uri.encodeComponent(query)}');
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      print('Error launching URL: $e');
    }
  }
} 