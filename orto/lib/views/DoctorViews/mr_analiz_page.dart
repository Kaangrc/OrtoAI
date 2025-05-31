import 'package:flutter/material.dart';
import 'package:ortopedi_ai/services/mr_service.dart';
import 'package:ortopedi_ai/utils/api_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';

class MRAnalizPage extends StatefulWidget {
  final String mrId;
  final String patientId;

  const MRAnalizPage({
    super.key,
    required this.mrId,
    required this.patientId,
  });

  @override
  State<MRAnalizPage> createState() => _MRAnalizPageState();
}

class _MRAnalizPageState extends State<MRAnalizPage> {
  final _storage = const FlutterSecureStorage();
  late final MRService _mrService;
  bool _isLoading = false;
  Set<String> _selectedSegmentTypes = {};
  Map<String, Map<String, dynamic>> _analysisResults = {};
  Map<String, dynamic>? _mrData;

  @override
  void initState() {
    super.initState();
    _mrService = MRService(
      dioClient: DioClient(storage: _storage),
      secureStorage: _storage,
    );
  }

  Future<void> _analyzeMR(String segmentType) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _mrService.segmentMr(
        widget.mrId,
        segmentType,
      );

      if (result['status'] == 'success') {
        setState(() {
          _analysisResults[segmentType] = result['data'];
          _mrData = result['mr'];
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'Bir hata oluştu')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Analiz sırasında bir hata oluştu: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _toggleSegmentType(String type) {
    setState(() {
      if (_selectedSegmentTypes.contains(type)) {
        _selectedSegmentTypes.remove(type);
        _analysisResults.remove(type);
      } else {
        _selectedSegmentTypes.add(type);
        _analyzeMR(type);
      }
    });
  }

  Widget _buildSegmentButton(String type) {
    final isSelected = _selectedSegmentTypes.contains(type);
    return ElevatedButton(
      onPressed: _isLoading ? null : () => _toggleSegmentType(type),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.blue : null,
        foregroundColor: isSelected ? Colors.white : null,
      ),
      child: Text(type.capitalize()),
    );
  }

  Widget _buildAnalysisResult() {
    if (_analysisResults.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _selectedSegmentTypes.map((segmentType) {
        final analysis = _analysisResults[segmentType];
        if (analysis == null) return const SizedBox.shrink();

        final status = analysis['status'] as String?;
        final segments =
            (analysis['segments'] as List<dynamic>?)?.cast<String>() ?? [];
        final boxes = (analysis['boxes'] as List<dynamic>?) ?? [];
        final outputImage = analysis['output_image'] as String?;

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${segmentType.capitalize()} Analiz Sonuçları',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                _buildInfoRow('Durum', status ?? 'Bilinmiyor'),
                _buildInfoRow('Segmentler', segments.join(', ')),
                if (boxes.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text('Tespit Edilen Bölgeler:'),
                  const SizedBox(height: 4),
                  ...boxes.map((box) {
                    final bone = box['bone'] as String?;
                    final boxCoords = box['box'] as List<dynamic>?;
                    return Text('$bone: ${boxCoords?.join(', ')}');
                  }),
                ],
                if (outputImage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    'İşlenmiş Görüntü',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  FutureBuilder<String?>(
                    future: _storage.read(key: 'token'),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child:
                              Text('Token yüklenirken hata: ${snapshot.error}'),
                        );
                      }

                      final token = snapshot.data;
                      if (token == null) {
                        return const Center(
                          child: Text('Token bulunamadı'),
                        );
                      }

                      return Image.network(
                        outputImage,
                        headers: {
                          'Authorization': 'Bearer $token',
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          print('Görüntü yükleme hatası: $error');
                          print('Görüntü URL: $outputImage');
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error_outline,
                                    color: Colors.red, size: 48),
                                const SizedBox(height: 16),
                                Text('Görüntü yüklenemedi: $error'),
                                const SizedBox(height: 8),
                                Text('URL: $outputImage',
                                    style: const TextStyle(fontSize: 12)),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MR Analizi'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Segmentasyon Seçenekleri',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildSegmentButton('merged'),
                        _buildSegmentButton('femur'),
                        _buildSegmentButton('tibia'),
                        _buildSegmentButton('fibula'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_analysisResults.isNotEmpty)
              _buildAnalysisResult(),
          ],
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
