import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ortopedi_ai/models/file_model.dart';
import 'package:ortopedi_ai/models/form_model.dart';
import 'package:ortopedi_ai/models/patientmodel.dart';
import 'package:ortopedi_ai/services/file_service.dart';
import 'package:ortopedi_ai/services/form_answer_service.dart';
import 'package:ortopedi_ai/services/form_service.dart';
import 'package:ortopedi_ai/services/patient_service.dart';
import 'package:ortopedi_ai/utils/api_client.dart';

class FormFillStepper extends StatefulWidget {
  final String? preselectedPatientId;
  final String? preselectedFileId;
  final String? preselectedFormId;
  // Alternative direct params
  final String? patientId;
  final String? formId;

  const FormFillStepper({
    super.key,
    this.preselectedPatientId,
    this.preselectedFileId,
    this.preselectedFormId,
    this.patientId,
    this.formId,
  });

  @override
  State<FormFillStepper> createState() => _FormFillStepperState();
}

class _FormFillStepperState extends State<FormFillStepper> {
  final _storage = const FlutterSecureStorage();
  late final DioClient _dioClient;
  late final PatientService _patientService;
  late final FileService _fileService;
  late final FormService _formService;
  late final FormAnswerService _formAnswerService;

  int _currentStep = 0; // 0: Hasta, 1: Dosya, 2: Form, 3: Doldur
  bool _isLoading = true;
  bool _isSubmitting = false;

  List<PatientModel> _patients = [];
  List<FileModel> _files = [];
  List<FormModel> _forms = [];

  String? _selectedPatientId;
  String? _selectedFileId;
  String? _selectedFormId;

  FormModel? _form;
  List<Map<String, dynamic>> _answers = [];

  @override
  void initState() {
    super.initState();
    _dioClient = DioClient(storage: _storage);
    _patientService =
        PatientService(dioClient: _dioClient, secureStorage: _storage);
    _fileService = FileService(dioClient: _dioClient, secureStorage: _storage);
    _formService = FormService(dioClient: _dioClient, secureStorage: _storage);
    _formAnswerService = FormAnswerService(dioClient: _dioClient);

    _selectedPatientId = widget.patientId ?? widget.preselectedPatientId;
    _selectedFileId = widget.preselectedFileId;
    _selectedFormId = widget.formId ?? widget.preselectedFormId;

    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      // Patients
      final patients = await _patientService.getAllPatients();
      _patients = patients;

      // Files (for all; we'll filter by patient later if needed)
      final files = await _fileService.getAllFiles();
      _files = files;

      // If preselected file exists, load its forms list
      if (_selectedFileId != null) {
        final file = _files.firstWhere((f) => f.id == _selectedFileId,
            orElse: () => _files.first);
        _forms = file.forms ?? [];
      }

      // If preselected form exists, fetch full form info
      if (_selectedFormId != null) {
        _form = await _formService.getFormInfo(_selectedFormId!);
        _prepareAnswers();
      }

      // Skip completed steps automatically
      _currentStep = 0;
      if (_selectedPatientId != null) _currentStep = 1;
      if (_selectedFileId != null) _currentStep = 2;
      if (_selectedFormId != null) _currentStep = 3;

      // Extra guard: if direct ids provided, check already answered
      if (_selectedPatientId != null && _selectedFormId != null) {
        final existing = await _formAnswerService.getAnswers(
            patientId: _selectedPatientId!, formId: _selectedFormId!);
        // Client-side safety filter in case backend ignores query params
        final hasForThisPatientAndForm = existing.any((a) =>
            a['patient_id'] == _selectedPatientId &&
            a['form_id'] == _selectedFormId);
        if (hasForThisPatientAndForm) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Bu form zaten doldurulmuş.')),
            );
            Navigator.pop(context);
            return;
          }
        }
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Yükleme sırasında hata oluştu: $e')),
        );
      }
    }
  }

  void _prepareAnswers() {
    if (_form?.questions != null) {
      _answers = List.generate(
          _form!.questions!.length,
          (_) => {
                'value': null,
                'option_level': null,
              });
    }
  }

  Future<void> _loadFormsForFile(String fileId) async {
    final file =
        _files.firstWhere((f) => f.id == fileId, orElse: () => _files.first);
    setState(() => _forms = file.forms ?? []);
  }

  Future<void> _loadFormDetail(String formId) async {
    setState(() => _isLoading = true);
    try {
      final form = await _formService.getFormInfo(formId);
      setState(() {
        _form = form;
        _prepareAnswers();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Form yüklenirken hata: $e')),
        );
      }
    }
  }

  Future<void> _submit() async {
    if (_form == null) return;
    // prefer direct patient and form ids if provided
    final patientId = widget.patientId ?? _selectedPatientId;
    final formId = widget.formId ?? _form!.id;
    if (patientId == null) return;
    setState(() => _isSubmitting = true);
    try {
      final totalScore = _answers.fold<num>(0, (sum, a) {
        final lvl = a['option_level'];
        if (lvl is num) return sum + lvl;
        return sum;
      });
      final result = await _formAnswerService.sendFormAnswer(
        formId: formId,
        patientId: patientId,
        formInfo: _form!,
        answers: _answers,
        totalScore: totalScore,
      );
      if (result['status'] == 'success') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Form yanıtı gönderildi')),
          );
          Navigator.pop(context, {
            'status': 'success',
            'formId': _form!.id,
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'Gönderilemedi')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gönderim hatası: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Form Doldurma Sihirbazı'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStepHeader(),
                  const SizedBox(height: 16),
                  Expanded(child: _buildStepContent()),
                  const SizedBox(height: 16),
                  _buildNavButtons(),
                ],
              ),
            ),
    );
  }

  Widget _buildStepHeader() {
    final labels = ['Hasta', 'Dosya', 'Form', 'Doldur'];
    return Row(
      children: List.generate(4, (i) {
        final isActive = i == _currentStep;
        final isDone = i < _currentStep;
        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: isActive || isDone
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      labels[i],
                      style: TextStyle(
                        color:
                            isActive || isDone ? Colors.white : Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              if (i < 3)
                const SizedBox(
                  width: 8,
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildPatientStep();
      case 1:
        return _buildFileStep();
      case 2:
        return _buildFormStep();
      case 3:
        return _buildFillStep();
      default:
        return const SizedBox();
    }
  }

  Widget _buildPatientStep() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Hasta Seç',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedPatientId,
              decoration: const InputDecoration(
                labelText: 'Hasta',
                border: OutlineInputBorder(),
              ),
              items: _patients
                  .map((p) => DropdownMenuItem(
                      value: p.id, child: Text('${p.firstName} ${p.lastName}')))
                  .toList(),
              onChanged: (val) => setState(() => _selectedPatientId = val),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileStep() {
    final availableFiles = _selectedPatientId == null
        ? _files
        : _files
            .where((f) =>
                _patients
                    .firstWhere((p) => p.id == _selectedPatientId!)
                    .fileIds
                    ?.contains(f.id) ??
                false)
            .toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Dosya Seç',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedFileId,
              decoration: const InputDecoration(
                labelText: 'Dosya',
                border: OutlineInputBorder(),
              ),
              items: availableFiles
                  .map(
                      (f) => DropdownMenuItem(value: f.id, child: Text(f.name)))
                  .toList(),
              onChanged: (val) async {
                setState(() => _selectedFileId = val);
                if (val != null) await _loadFormsForFile(val);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormStep() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Form Seç',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (_forms.isEmpty)
              const Text('Bu dosyada form yok')
            else
              DropdownButtonFormField<String>(
                value: _selectedFormId,
                decoration: const InputDecoration(
                  labelText: 'Form',
                  border: OutlineInputBorder(),
                ),
                items: _forms
                    .map((fm) =>
                        DropdownMenuItem(value: fm.id, child: Text(fm.name)))
                    .toList(),
                onChanged: (val) async {
                  setState(() => _selectedFormId = val);
                  if (val != null) await _loadFormDetail(val);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFillStep() {
    if (_form == null) {
      return const Center(child: Text('Önce form seçin'));
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_form!.name,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: _form!.questions?.length ?? 0,
                itemBuilder: (context, index) {
                  final q = _form!.questions![index];
                  if (q.type == 'text') {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: TextFormField(
                        decoration: InputDecoration(
                          labelText: q.question,
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (val) {
                          _answers[index]['value'] = val;
                          _answers[index]['option_level'] = null;
                        },
                      ),
                    );
                  } else {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(q.question,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                          ),
                          ...?q.options?.map((opt) => RadioListTile<String>(
                                title: Text(opt.option),
                                value: opt.option,
                                groupValue: _answers[index]['value'] as String?,
                                onChanged: (val) {
                                  setState(() {
                                    _answers[index]['value'] = val;
                                    _answers[index]['option_level'] =
                                        opt.optionLevel;
                                  });
                                },
                              )),
                        ],
                      ),
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: _isSubmitting ? null : _submit,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white)),
                      )
                    : const Icon(Icons.save),
                label: Text(_isSubmitting ? 'Gönderiliyor...' : 'Kaydet'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        OutlinedButton(
          onPressed: _currentStep == 0
              ? null
              : () => setState(() {
                    _currentStep -= 1;
                  }),
          child: const Text('Geri'),
        ),
        FilledButton(
          onPressed: _canGoNext()
              ? () =>
                  setState(() => _currentStep = (_currentStep + 1).clamp(0, 3))
              : null,
          child: const Text('İleri'),
        ),
      ],
    );
  }

  bool _canGoNext() {
    switch (_currentStep) {
      case 0:
        return _selectedPatientId != null && _selectedPatientId!.isNotEmpty;
      case 1:
        return _selectedFileId != null && _selectedFileId!.isNotEmpty;
      case 2:
        return _selectedFormId != null && _selectedFormId!.isNotEmpty;
      case 3:
        return false; // submit button handles this step
      default:
        return false;
    }
  }
}
