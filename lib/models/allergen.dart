import 'package:flutter/material.dart';

class AllergenFilterChip extends StatelessWidget {
  final String label;
  final String status;
  final IconData icon;

  const AllergenFilterChip({
    Key? key,
    required this.label,
    required this.status,
    required this.icon,
  }) : super(key: key);

  Color _getColorByStatus() {
    switch (status) {
      case 'safe':
        return Color(0xFFE6F5E9);
      case 'caution':
        return Color(0xFFFFF3CD);
      case 'danger':
        return Color(0xFFFDE7E9);
      default:
        return Colors.grey[200]!;
    }
  }

  Color _getTextColorByStatus() {
    switch (status) {
      case 'safe':
        return Color(0xFF2ECC71);
      case 'caution':
        return Color(0xFFF39C12);
      case 'danger':
        return Color(0xFFE74C3C);
      default:
        return Colors.black;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      labelStyle: TextStyle(
        color: _getTextColorByStatus(),
        fontWeight: FontWeight.w600,
      ),
      backgroundColor: _getColorByStatus(),
      avatar: Icon(
        icon,
        color: _getTextColorByStatus(),
        size: 20,
      ),
    );
  }
}