import 'package:flutter/material.dart';
import '../services/service_provider.dart';

class ModelsInfoScreen extends StatefulWidget {
  const ModelsInfoScreen({Key? key}) : super(key: key);

  @override
  _ModelsInfoScreenState createState() => _ModelsInfoScreenState();
}

class _ModelsInfoScreenState extends State<ModelsInfoScreen> {
  final ServiceProvider _serviceProvider = ServiceProvider();
  bool _isLoading = true;
  String _errorMessage = '';
  List<Map<String, dynamic>> _models = [];

  @override
  void initState() {
    super.initState();
    _loadModels();
  }

  Future<void> _loadModels() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final geminiService = await _serviceProvider.getGeminiService();
      final models = await geminiService.listAvailableModels();

      setState(() {
        _models = models;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load models: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gemini Models Info'),
        backgroundColor: const Color(0xFF6D30EA),
        foregroundColor: Colors.white,
      ),
      body: _buildContent(),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadModels,
        backgroundColor: const Color(0xFF6D30EA),
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              'Error',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _errorMessage,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }

    if (_models.isEmpty) {
      return const Center(
        child: Text('No models available'),
      );
    }

    return ListView.builder(
      itemCount: _models.length,
      itemBuilder: (context, index) {
        final model = _models[index];
        final name = model['displayName'] ?? 'Unknown';
        final supportedMethods = model['supportedGenerationMethods'] as List<dynamic>? ?? [];
        final description = model['description'] ?? 'No description available';
        final inputTokenLimit = model['inputTokenLimit']?.toString() ?? 'N/A';
        final outputTokenLimit = model['outputTokenLimit']?.toString() ?? 'N/A';

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 2,
          child: ExpansionTile(
            title: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Input limit: $inputTokenLimit, Output limit: $outputTokenLimit',
              style: const TextStyle(fontSize: 12),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Description:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(description),
                    const SizedBox(height: 16),
                    const Text(
                      'Supported Methods:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    supportedMethods.isEmpty
                        ? const Text('No methods listed')
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: supportedMethods
                                .map<Widget>((method) => Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 2),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.check_circle, size: 16, color: Colors.green),
                                          const SizedBox(width: 8),
                                          Text(method.toString()),
                                        ],
                                      ),
                                    ))
                                .toList(),
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
} 