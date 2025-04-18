import 'package:flutter/material.dart';

class AllergenFilterChip extends StatelessWidget {
  final String label;
  final String status;
  final IconData icon;
  final Color color;
  final bool isSmallScreen;

  const AllergenFilterChip({
    Key? key,
    required this.label,
    required this.status,
    required this.icon,
    required this.color,
    required this.isSmallScreen,
  }) : super(key: key);

  Color _getColorByStatus() {
    return color.withOpacity(0.1);
  }

  Color _getTextColorByStatus() {
    return color;
  }

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: isSmallScreen ? 12 : 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      labelStyle: TextStyle(
        color: _getTextColorByStatus(),
        fontWeight: FontWeight.w600,
      ),
      backgroundColor: _getColorByStatus(),
      avatar: Icon(
        icon,
        size: isSmallScreen ? 16 : 18,
        color: _getTextColorByStatus(),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 8 : 12,
        vertical: isSmallScreen ? 4 : 6,
      ),
    );
  }
}