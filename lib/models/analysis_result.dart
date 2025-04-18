import 'package:flutter/material.dart';

class AlternativeProduct {
  final String name;
  final String reason;
  final String? nutritionalBenefits;
  final String? imageUrl;

  AlternativeProduct({
    required this.name,
    required this.reason,
    this.nutritionalBenefits,
    this.imageUrl,
  });

  factory AlternativeProduct.fromJson(Map<String, dynamic> json) {
    return AlternativeProduct(
      name: json['name'] ?? 'Unknown Alternative',
      reason: json['reason'] ?? 'Better alternative',
      nutritionalBenefits: json['nutritionalBenefits'],
      imageUrl: json['imageUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'reason': reason,
      'nutritionalBenefits': nutritionalBenefits,
      'imageUrl': imageUrl,
    };
  }
}

class AnalysisResult {
  final bool isError;
  final String errorMessage;
  final String compatibility; // 'good', 'moderate', 'poor', or 'unknown'
  final String explanation;
  final List<String> recommendations;
  final List<String> healthInsights;
  final List<AlternativeProduct> alternatives;
  final bool isSafeForUser;
  final String safetyReason;
  final Map<String, double> nutritionalValues;

  AnalysisResult({
    required this.isError,
    required this.errorMessage,
    required this.compatibility,
    required this.explanation,
    required this.recommendations,
    required this.healthInsights,
    this.alternatives = const [],
    this.isSafeForUser = false,
    this.safetyReason = '',
    this.nutritionalValues = const {},
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    // Process nutritional values
    Map<String, double> nutritionalValues = {};
    if (json['nutritionalValues'] != null) {
      final nutritionJson = json['nutritionalValues'] as Map<String, dynamic>;
      nutritionJson.forEach((key, value) {
        // Convert any numeric values to double
        if (value is num) {
          nutritionalValues[key] = value.toDouble();
        }
      });
    }
    
    return AnalysisResult(
      isError: json['isError'] ?? false,
      errorMessage: json['errorMessage'] ?? '',
      compatibility: json['compatibility'] ?? 'unknown',
      explanation: json['explanation'] ?? '',
      recommendations: List<String>.from(json['recommendations'] ?? []),
      healthInsights: List<String>.from(json['healthInsights'] ?? []),
      alternatives: json['alternatives'] != null
          ? List<Map<String, dynamic>>.from(json['alternatives'])
              .map((altJson) => AlternativeProduct.fromJson(altJson))
              .toList()
          : [],
      isSafeForUser: json['isSafeForUser'] ?? false,
      safetyReason: json['safetyReason'] ?? '',
      nutritionalValues: nutritionalValues,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isError': isError,
      'errorMessage': errorMessage,
      'compatibility': compatibility,
      'explanation': explanation,
      'recommendations': recommendations,
      'healthInsights': healthInsights,
      'alternatives': alternatives.map((alt) => alt.toJson()).toList(),
      'isSafeForUser': isSafeForUser,
      'safetyReason': safetyReason,
      'nutritionalValues': nutritionalValues,
    };
  }

  // Helper method to get a color based on compatibility
  Color getCompatibilityColor() {
    switch (compatibility.toLowerCase()) {
      case 'good':
        return Colors.green;
      case 'moderate':
        return Colors.orange;
      case 'poor':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
} 