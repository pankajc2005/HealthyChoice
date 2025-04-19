import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product_scan.dart';

class ScanHistoryService {
  static const String _scanHistoryKey = 'scan_history';
  static const int _maxRecentScans = 10;

  // Save a scan to history
  static Future<void> saveProductScan(ProductScan scan) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final scanHistory = await getRecentScans();
      
      // Check if product with same name already exists
      scanHistory.removeWhere((existingScan) => existingScan.name == scan.name);
      
      // Add new scan at the beginning
      scanHistory.insert(0, scan);
      
      // Keep only the most recent scans
      if (scanHistory.length > _maxRecentScans) {
        scanHistory.removeLast();
      }
      
      // Convert to JSON list and save
      final jsonList = scanHistory.map((scan) => _scanToJson(scan)).toList();
      await prefs.setString(_scanHistoryKey, jsonEncode(jsonList));
    } catch (e) {
      print('Error saving scan history: $e');
    }
  }

  // Get all recent scans
  static Future<List<ProductScan>> getRecentScans() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_scanHistoryKey);
      
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }
      
      final jsonList = jsonDecode(jsonString) as List;
      
      // Limit the number of scans to load for better performance
      if (jsonList.length > 10) {
        final trimmedList = jsonList.sublist(0, 10);
        // Save the trimmed list back to preferences to improve future load times
        await prefs.setString(_scanHistoryKey, jsonEncode(trimmedList));
        return trimmedList.map((json) => _scanFromJson(json)).toList();
      }
      
      return jsonList.map((json) => _scanFromJson(json)).toList();
    } catch (e) {
      print('Error retrieving scan history: $e');
      return [];
    }
  }
  
  // Clear all scan history
  static Future<void> clearScanHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_scanHistoryKey);
    } catch (e) {
      print('Error clearing scan history: $e');
    }
  }
  
  // Helper method to convert scan to JSON
  static Map<String, dynamic> _scanToJson(ProductScan scan) {
    return {
      'name': scan.name,
      'status': scan.status.toString().split('.').last,
      'description': scan.description,
      'imagePath': scan.imagePath,
      'scanDate': scan.scanDate.toIso8601String(),
      'barcode': scan.barcode,
    };
  }
  
  // Helper method to convert JSON to scan
  static ProductScan _scanFromJson(Map<String, dynamic> json) {
    return ProductScan(
      name: json['name'] ?? 'Unknown Product',
      status: _parseStatus(json['status'] ?? 'caution'),
      description: json['description'] ?? '',
      imagePath: json['imagePath'] ?? 'assets/images/placeholder.png',
      scanDate: DateTime.parse(json['scanDate']),
      barcode: json['barcode'] ?? '',
    );
  }
  
  // Parse status string to enum
  static ScanStatus _parseStatus(String status) {
    switch (status.toLowerCase()) {
      case 'safe':
        return ScanStatus.safe;
      case 'danger':
        return ScanStatus.danger;
      case 'caution':
      default:
        return ScanStatus.caution;
    }
  }
} 