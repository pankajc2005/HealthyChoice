import 'package:flutter/material.dart';
import '../models/analysis_result.dart';
import '../services/gemini_service.dart';

class AnalysisDisplay extends StatelessWidget {
  final AnalysisResult analysis;
  final bool isExpanded;
  final VoidCallback onToggle;

  const AnalysisDisplay({
    Key? key,
    required this.analysis,
    this.isExpanded = false,
    required this.onToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (analysis.isError) {
      return _buildErrorDisplay();
    }

    final bool hasAlternatives = analysis.alternatives.isNotEmpty;
    final String compatibilityLower = analysis.compatibility.toLowerCase();
    final bool needsAlternatives = compatibilityLower == 'moderate' || compatibilityLower == 'poor';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with compatibility indicator
          InkWell(
            onTap: onToggle,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: analysis.getCompatibilityColor().withOpacity(0.1),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomLeft: isExpanded ? Radius.zero : Radius.circular(16),
                  bottomRight: isExpanded ? Radius.zero : Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    GeminiService.getCompatibilityEmoji(analysis.compatibility),
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'AI Health Analysis',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            // Add a special badge for safe products
                            if (analysis.compatibility.toLowerCase() == 'good')
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade700,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check_circle, color: Colors.white, size: 12),
                                    const SizedBox(width: 4),
                                    Text(
                                      "SAFE",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          analysis.explanation,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                          maxLines: isExpanded ? null : 2,
                          overflow: isExpanded ? null : TextOverflow.ellipsis,
                        ),
                        
                        // Add a note when alternatives are available
                        if (needsAlternatives && hasAlternatives && !isExpanded)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.arrow_downward,
                                  size: 14,
                                  color: Theme.of(context).primaryColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'See better alternatives below',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.black54,
                  ),
                ],
              ),
            ),
          ),
          
          // Expanded content
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (analysis.recommendations.isNotEmpty) ...[
                    const Text(
                      '🔍 Recommendations',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...analysis.recommendations.map((recommendation) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• ', style: TextStyle(fontSize: 16)),
                            Expanded(
                              child: Text(
                                recommendation,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                  
                  if (analysis.healthInsights.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      '💡 Health Insights',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...analysis.healthInsights.map((insight) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• ', style: TextStyle(fontSize: 16)),
                            Expanded(
                              child: Text(
                                insight,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildErrorDisplay() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red),
              SizedBox(width: 8),
              Text(
                'Analysis Error',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            analysis.errorMessage,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }
} 