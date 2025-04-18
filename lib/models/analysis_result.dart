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
  final ServingSizeInfo servingSizeInfo;

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
    ServingSizeInfo? servingSizeInfo,
  }) : this.servingSizeInfo = servingSizeInfo ?? ServingSizeInfo();

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    final List<String> recommendations = [];
    final List<String> healthInsights = [];
    final List<AlternativeProduct> alternatives = [];
    final Map<String, double> nutritionalValues = {};
    
    // Parse recommendations
    if (json['recommendations'] != null) {
      for (final recommendation in json['recommendations']) {
        recommendations.add(recommendation.toString());
      }
    }
    
    // Parse health insights
    if (json['healthInsights'] != null) {
      for (final insight in json['healthInsights']) {
        healthInsights.add(insight.toString());
      }
    }
    
    // Parse alternatives
    if (json['alternatives'] != null) {
      for (final alternative in json['alternatives']) {
        if (alternative is Map<String, dynamic>) {
          alternatives.add(AlternativeProduct.fromJson(alternative));
        }
      }
    }
    
    // Parse nutritional values
    if (json['nutritionalValues'] != null) {
      for (final entry in (json['nutritionalValues'] as Map<String, dynamic>).entries) {
        if (entry.value is num) {
          nutritionalValues[entry.key] = (entry.value as num).toDouble();
        } else if (entry.value is String) {
          try {
            nutritionalValues[entry.key] = double.parse(entry.value);
          } catch (e) {
            // Skip non-numeric values
          }
        }
      }
    }
    
    // Parse serving size information
    ServingSizeInfo? servingSizeInfo;
    if (json['servingSizeInfo'] != null) {
      servingSizeInfo = ServingSizeInfo.fromJson(json['servingSizeInfo']);
    }
    
    return AnalysisResult(
      isError: json['isError'] ?? false,
      errorMessage: json['errorMessage'] ?? '',
      compatibility: json['compatibility'] ?? 'unknown',
      explanation: json['explanation'] ?? 'No explanation available',
      recommendations: recommendations,
      healthInsights: healthInsights,
      alternatives: alternatives,
      isSafeForUser: json['isSafeForUser'] ?? false,
      safetyReason: json['safetyReason'] ?? '',
      nutritionalValues: nutritionalValues,
      servingSizeInfo: servingSizeInfo,
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
      'servingSizeInfo': servingSizeInfo.toJson(),
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

class ServingSizeInfo {
  final String servingSize;
  final int servingsPerContainer;
  final double sugarPerServing;
  final int percentOfDailyRecommended;

  ServingSizeInfo({
    this.servingSize = '30g',
    this.servingsPerContainer = 0,
    this.sugarPerServing = 0.0,
    this.percentOfDailyRecommended = 0,
  });

  factory ServingSizeInfo.fromJson(Map<String, dynamic> json) {
    return ServingSizeInfo(
      servingSize: json['servingSize'] ?? '30g',
      servingsPerContainer: json['servingsPerContainer'] ?? 0,
      sugarPerServing: json['sugarPerServing'] is num 
          ? (json['sugarPerServing'] as num).toDouble() 
          : 0.0,
      percentOfDailyRecommended: json['percentOfDailyRecommended'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'servingSize': servingSize,
      'servingsPerContainer': servingsPerContainer,
      'sugarPerServing': sugarPerServing,
      'percentOfDailyRecommended': percentOfDailyRecommended,
    };
  }
} 