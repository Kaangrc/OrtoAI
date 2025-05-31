import 'package:flutter/material.dart';
import 'package:ortopedi_ai/services/form_service.dart';
import 'package:ortopedi_ai/models/form_model.dart';
import 'package:ortopedi_ai/services/patient_service.dart';
import 'package:ortopedi_ai/models/patientmodel.dart';
import 'package:ortopedi_ai/utils/api_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';

class DFormPage extends StatefulWidget {
  final String formId;
  const DFormPage({super.key, required this.formId});

  @override
  State<DFormPage> createState() => _DFormPageState();
}

class _DFormPageState extends State<DFormPage> {
  final FormService _formService = FormService(
    dioClient: DioClient(storage: const FlutterSecureStorage()),
  );
  final PatientService _patientService = PatientService(
    dioClient: DioClient(storage: const FlutterSecureStorage()),
  );
  FormModel? _form;
  List<PatientModel> _patients = [];
  bool _isLoading = true;
  bool _isEditing = false;
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedFormType = 'for patients';

  @override
  void initState() {
    super.initState();
    _loadForm();
  }

  Future<void> _loadForm() async {
    try {
      final form = await _formService.getFormInfo(widget.formId);
      setState(() {
        _form = form;
        _nameController.text = form.name;
        _descriptionController.text = form.description;
        _selectedFormType = form.type;
      });

      // Form yüklendikten sonra hastaları yükle
      if (form.fileId != null) {
        await _loadPatients(form.fileId!);
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Form yüklenirken hata oluştu: $e')),
        );
      }
    }
  }

  Future<void> _loadPatients(String fileId) async {
    try {
      final patients = await _patientService.getAllPatients();
      setState(() {
        _patients = patients
            .where((patient) => patient.fileIds?.contains(fileId) ?? false)
            .toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hastalar yüklenirken hata oluştu: $e')),
        );
      }
    }
  }

  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  Future<void> _updateForm() async {
    if (_form == null) return;

    try {
      final updatedData = {
        'name': _nameController.text,
        'description': _descriptionController.text,
        'type': _selectedFormType,
        'questions': _form!.questions?.map((q) => q.toJson()).toList(),
        'file_id': _form!.fileId,
        'level': _form!.level,
      };

      final result = await _formService.updateForm(_form!.id, updatedData);

      if (result['status'] == 'success') {
        await _loadForm();
        setState(() {
          _isEditing = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Form başarıyla güncellendi')),
          );
        }
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
          SnackBar(content: Text('Form güncellenirken hata oluştu: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Form Detayları'),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit),
            onPressed: _isEditing ? _updateForm : _toggleEditMode,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _form == null
              ? const Center(child: Text('Form bulunamadı'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_isEditing) ...[
                        TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Form Adı',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Form Açıklaması',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),
                        const Text('Form Tipi:',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        RadioListTile<String>(
                          title: const Text('Hastaya Gönder'),
                          value: 'for patients',
                          groupValue: _selectedFormType,
                          onChanged: (value) {
                            setState(() {
                              _selectedFormType = value!;
                            });
                          },
                        ),
                        RadioListTile<String>(
                          title: const Text('Kendin Doldur'),
                          value: 'for me',
                          groupValue: _selectedFormType,
                          onChanged: (value) {
                            setState(() {
                              _selectedFormType = value!;
                            });
                          },
                        ),
                      ] else ...[
                        Text(
                          _form!.name,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _form!.description,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Form Tipi: ${_form!.type == 'for patients' ? 'Hastaya Gönder' : 'Kendin Doldur'}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                      const SizedBox(height: 24),
                      const Text(
                        'Sorular',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_form!.questions != null &&
                          _form!.questions!.isNotEmpty)
                        ..._form!.questions!.map((question) => Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                title: Text(question.question),
                                subtitle: question.options != null
                                    ? Text(
                                        'Seçenekler: ${question.options!.join(", ")}')
                                    : null,
                                trailing: Text(question.type == 'text'
                                    ? 'Metin'
                                    : 'Çoktan Seçmeli'),
                              ),
                            ))
                      else
                        const Text('Bu formda henüz soru bulunmuyor'),
                      const SizedBox(height: 24),
                      const Text(
                        'Bu Dosyaya Ait Hastalar',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_patients.isNotEmpty)
                        ..._patients.map((patient) => Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  child: Text(
                                    patient.firstName[0] + patient.lastName[0],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                    '${patient.firstName} ${patient.lastName}'),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('E-posta: ${patient.email}'),
                                    Text('Telefon: ${patient.primaryPhone}'),
                                    Text(
                                        'Doğum Tarihi: ${DateFormat('dd/MM/yyyy').format(patient.dateOfBirth)}'),
                                  ],
                                ),
                              ),
                            ))
                      else
                        const Text('Bu dosyaya ait hasta bulunmuyor'),
                    ],
                  ),
                ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
