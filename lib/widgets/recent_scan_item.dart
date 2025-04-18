import 'package:flutter/material.dart';
import '../models/product_scan.dart';
import '../screens/results_page.dart';

class RecentScanItem extends StatelessWidget {
  final ProductScan scan;
  final bool isSmallScreen;
  final VoidCallback? onDelete;

  const RecentScanItem({
    Key? key,
    required this.scan,
    required this.isSmallScreen,
    this.onDelete,
  }) : super(key: key);

  Color _getStatusColor() {
    switch (scan.status) {
      case ScanStatus.safe:
        return Color(0xFF2ECC71);
      case ScanStatus.caution:
        return Color(0xFFF39C12);
      case ScanStatus.danger:
        return Color(0xFFE74C3C);
    }
  }

  String _getStatusText() {
    switch (scan.status) {
      case ScanStatus.safe:
        return 'Safe';
      case ScanStatus.caution:
        return 'Caution';
      case ScanStatus.danger:
        return 'Danger';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResultsPage(barcode: scan.barcode),
          ),
        );
      },
      child: Dismissible(
        key: Key(scan.barcode + scan.scanDate.toString()),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: EdgeInsets.only(right: 20.0),
          color: Colors.red,
          child: Icon(
            Icons.delete,
            color: Colors.white,
          ),
        ),
        onDismissed: (direction) {
          if (onDelete != null) {
            onDelete!();
          }
        },
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 5,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: isSmallScreen ? 32 : 40,
                  height: isSmallScreen ? 32 : 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(isSmallScreen ? 6 : 8),
                    color: Colors.grey[100],
                  ),
                  child: Icon(
                    Icons.shopping_bag,
                    color: _getStatusColor().withOpacity(0.7),
                    size: isSmallScreen ? 18 : 22,
                  ),
                ),
                SizedBox(width: isSmallScreen ? 8 : 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        scan.name,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 14 : 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: isSmallScreen ? 2 : 4),
                      Text(
                        scan.description,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 12 : 14,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: isSmallScreen ? 4 : 6),
                      Wrap(
                        spacing: isSmallScreen ? 8 : 12,
                        runSpacing: isSmallScreen ? 4 : 6,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isSmallScreen ? 6 : 8,
                              vertical: isSmallScreen ? 2 : 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor().withOpacity(0.1),
                              borderRadius: BorderRadius.circular(isSmallScreen ? 4 : 6),
                            ),
                            child: Text(
                              _getStatusText(),
                              style: TextStyle(
                                color: _getStatusColor(),
                                fontSize: isSmallScreen ? 10 : 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            _getTimeAgo(scan.scanDate),
                            style: TextStyle(
                              fontSize: isSmallScreen ? 10 : 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: isSmallScreen ? 14 : 16,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}