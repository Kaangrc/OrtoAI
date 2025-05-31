import 'package:flutter/material.dart';
import 'package:ortopedi_ai/models/patientmodel.dart';
import 'package:ortopedi_ai/models/file_model.dart';
import 'package:ortopedi_ai/models/mr_model.dart';
import 'package:ortopedi_ai/services/patient_service.dart';
import 'package:ortopedi_ai/services/file_service.dart';
import 'package:ortopedi_ai/services/mr_service.dart';
import 'package:ortopedi_ai/utils/api_client.dart';
import 'package:ortopedi_ai/views/DoctorViews/mr_analiz_page.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';

class PatientDetailPage extends StatefulWidget {
  final PatientModel patient;

  const PatientDetailPage({super.key, required this.patient});

  @override
  State<PatientDetailPage> createState() => _PatientDetailPageState();
}

class _PatientDetailPageState extends State<PatientDetailPage> {
  final _storage = const FlutterSecureStorage();
  late final FileService _fileService;
  late final MRService _mrService;
  bool _isLoading = true;
  List<FileModel> _patientFiles = [];
  List<MRModel> _patientMRs = [];

  @override
  void initState() {
    super.initState();
    _fileService = FileService(
      dioClient: DioClient(storage: _storage),
    );
    _mrService = MRService(
      dioClient: DioClient(storage: _storage),
      secureStorage: _storage,
    );
    _loadPatientFiles();
    _loadPatientMRs();
  }

  Future<void> _loadPatientFiles() async {
    try {
      final allFiles = await _fileService.getAllFiles();
      setState(() {
        _patientFiles = allFiles
            .where((file) => widget.patient.fileIds?.contains(file.id) ?? false)
            .toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Dosyalar yüklenirken hata oluştu: $e')),
        );
      }
    }
  }

  Future<void> _loadPatientMRs() async {
    try {
      final mrs = await _mrService.getPatientMr(widget.patient.id);
      setState(() {
        _patientMRs = mrs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('MR kayıtları yüklenirken hata oluştu: $e')),
        );
      }
    }
  }

  Future<void> _addMR() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (image != null) {
        // Dosya uzantısını kontrol et
        final String fileExtension = image.path.split('.').last.toLowerCase();
        if (fileExtension != 'png') {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Lütfen sadece PNG formatında görsel seçin'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        final File imageFile = File(image.path);
        final TextEditingController notesController = TextEditingController();

        if (mounted) {
          final bool? addNotes = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Not Ekle'),
              content: TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  hintText: 'MR görüntüsü için not ekleyin',
                ),
                maxLines: 3,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('İptal'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Ekle'),
                ),
              ],
            ),
          );

          if (addNotes == true) {
            setState(() => _isLoading = true);
            final result = await _mrService.addMr(
              patientId: widget.patient.id,
              imageFile: imageFile,
              notes: notesController.text,
            );

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(result['message']),
                  backgroundColor:
                      result['status'] == 'success' ? Colors.green : Colors.red,
                ),
              );

              if (result['status'] == 'success') {
                _loadPatientMRs();
              }
            }
          }
        }
      }
    } on PlatformException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Görsel seçilirken bir hata oluştu: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Beklenmeyen bir hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.patient.firstName} ${widget.patient.lastName}'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
                          const Text(
                            'Hasta Bilgileri',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildInfoRow('Ad', widget.patient.firstName),
                          _buildInfoRow('Soyad', widget.patient.lastName),
                          _buildInfoRow('E-posta', widget.patient.email),
                          _buildInfoRow('Telefon', widget.patient.primaryPhone),
                          if (widget.patient.secondaryPhone != null)
                            _buildInfoRow('İkincil Telefon',
                                widget.patient.secondaryPhone!),
                          _buildInfoRow(
                              'Doğum Tarihi',
                              DateFormat('dd/MM/yyyy')
                                  .format(widget.patient.dateOfBirth)),
                          _buildInfoRow(
                              'Cinsiyet',
                              widget.patient.gender == 'Male'
                                  ? 'Erkek'
                                  : 'Kadın'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'MR Kayıtları',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: _addMR,
                                icon: const Icon(Icons.add),
                                label: const Text('MR Ekle'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (_patientMRs.isEmpty)
                            const Center(
                              child: Text('Hastanın MR kaydı bulunmuyor'),
                            )
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _patientMRs.length,
                              itemBuilder: (context, index) {
                                final mr = _patientMRs[index];
                                return ListTile(
                                  leading: const Icon(Icons.image),
                                  title: Text('MR ${index + 1}'),
                                  subtitle:
                                      mr.notes != null ? Text(mr.notes!) : null,
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        DateFormat('dd/MM/yyyy')
                                            .format(mr.createdAt),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: const Icon(Icons.analytics),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  MRAnalizPage(
                                                mrId: mr.id,
                                                patientId: widget.patient.id,
                                              ),
                                            ),
                                          );
                                        },
                                        tooltip: 'Analiz Et',
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Hastanın Dosyaları',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (_patientFiles.isEmpty)
                            const Center(
                              child: Text(
                                  'Hastanın kayıtlı olduğu dosya bulunmuyor'),
                            )
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _patientFiles.length,
                              itemBuilder: (context, index) {
                                final file = _patientFiles[index];
                                return ListTile(
                                  leading: const Icon(Icons.folder),
                                  title: Text(file.name),
                                  onTap: () {
                                    // Dosya detay sayfasına yönlendirme yapılabilir
                                  },
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
}
