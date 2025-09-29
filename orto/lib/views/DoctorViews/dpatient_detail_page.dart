import 'package:flutter/material.dart';
import 'package:ortopedi_ai/models/patientmodel.dart';
import 'package:ortopedi_ai/models/file_model.dart';
import 'package:ortopedi_ai/models/mr_model.dart';
import 'package:ortopedi_ai/services/file_service.dart';
import 'package:ortopedi_ai/services/mr_service.dart';
import 'package:ortopedi_ai/utils/api_client.dart';
import 'package:ortopedi_ai/views/DoctorViews/mr_analiz_page.dart';
import 'package:ortopedi_ai/views/DoctorViews/form_fill_stepper.dart';
import 'package:ortopedi_ai/services/form_answer_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'package:ortopedi_ai/services/patient_service.dart';

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
  late final PatientService _patientService;
  // FormService gerekli değil; formlar file modeli üzerinden geliyor
  bool _isLoading = true;
  List<FileModel> _patientFiles = [];
  List<MRModel> _patientMRs = [];
  List<FileModel> _allFiles = [];
  final Set<String> _completedFormIds = {};
  List<Map<String, dynamic>> _completedFormAnswers = [];
  late final FormAnswerService _formAnswerService;

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
    _patientService = PatientService(
      dioClient: DioClient(storage: _storage),
    );
    _formAnswerService = FormAnswerService(
      dioClient: DioClient(storage: _storage),
    );
    // FormService kullanımına ihtiyaç yok
    _loadPatientFiles();
    _loadPatientMRs();
    _loadCompletedForms();
  }

  Future<void> _loadPatientFiles() async {
    try {
      final allFiles = await _fileService.getAllFiles();
      _allFiles = allFiles;
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

  Future<void> _assignFileToPatient() async {
    try {
      // Mevcut atanmış dosyaları çıkar, seçilebilir listeyi hazırla
      final assignedIds = Set<String>.from(widget.patient.fileIds ?? []);
      final selectable =
          _allFiles.where((f) => !assignedIds.contains(f.id)).toList();

      if (selectable.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Atanabilecek uygun dosya bulunamadı'),
            ),
          );
        }
        return;
      }

      FileModel? chosen;
      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Dosyaya Ekle'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: selectable.length,
                itemBuilder: (context, index) {
                  final file = selectable[index];
                  return ListTile(
                    leading: const Icon(Icons.folder),
                    title: Text(file.name),
                    onTap: () {
                      chosen = file;
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('İptal'),
              ),
            ],
          );
        },
      );

      if (chosen == null) return;

      setState(() => _isLoading = true);

      final newFileIds = <String>{...assignedIds, chosen!.id}.toList();
      final response = await _patientService.updatePatient(
        widget.patient.id,
        {
          'fileIds': newFileIds,
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Dosya atandı'),
            backgroundColor: response['status'] == 'success'
                ? Colors.green
                : Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      if (response['status'] == 'success') {
        await _loadPatientFiles();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Dosya atanırken hata oluştu: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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

  Future<void> _loadCompletedForms() async {
    try {
      print('DEBUG: Hasta ID: ${widget.patient.id}');
      final answers = await _formAnswerService.getAnswers(
        patientId: widget.patient.id,
      );
      print('DEBUG: API\'den dönen cevaplar: $answers');
      print('DEBUG: Toplam cevap sayısı: ${answers.length}');

      final completedIds = <String>{};
      final completedAnswers = <Map<String, dynamic>>[];

      for (final a in answers) {
        print('DEBUG: Cevap detayı: $a');
        final fid = a['form_id'];
        final pid = a['patient_id'];
        print('DEBUG: Form ID: $fid, Patient ID: $pid');

        // Ekstra güvenlik: patient_id kontrolü ekle
        if (pid == widget.patient.id && fid is String && fid.isNotEmpty) {
          completedIds.add(fid);
          completedAnswers.add(a);
        }
      }

      print('DEBUG: Filtrelenmiş form ID\'leri: $completedIds');
      print('DEBUG: Filtrelenmiş cevaplar sayısı: ${completedAnswers.length}');

      if (mounted) {
        setState(() {
          _completedFormIds
            ..clear()
            ..addAll(completedIds);
          _completedFormAnswers = completedAnswers;
        });
      }
    } catch (e) {
      print('DEBUG: _loadCompletedForms hatası: $e');
      // sessiz geç, UI bozulmasın
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

  void _showFormAnswerDetails(Map<String, dynamic> answer) {
    final formName = answer['name'] ?? 'Bilinmeyen Form';
    final totalScore = answer['total_form_score'] ?? 0;
    final createdAt = answer['created_at'];
    final questions = answer['questions'] as List<dynamic>? ?? [];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(formName),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (createdAt != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      'Doldurulma Tarihi: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(createdAt))}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                Text(
                  'Toplam Skor: $totalScore',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Sorular ve Cevaplar:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                ...questions.asMap().entries.map((entry) {
                  final index = entry.key;
                  final question = entry.value as Map<String, dynamic>;
                  final questionText =
                      question['question'] ?? 'Soru ${index + 1}';
                  final answerText = question['answer'] ?? 'Cevap verilmemiş';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${index + 1}. $questionText',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Text(
                            answerText,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
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
                            'Doldurulmuş Formlar',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (_completedFormAnswers.isEmpty)
                            const Center(
                              child: Text('Henüz doldurulmuş form bulunmuyor'),
                            )
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _completedFormAnswers.length,
                              itemBuilder: (context, index) {
                                final answer = _completedFormAnswers[index];
                                final formName =
                                    answer['name'] ?? 'Bilinmeyen Form';
                                final totalScore =
                                    answer['total_form_score'] ?? 0;
                                final createdAt = answer['created_at'];

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    leading: const Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                    ),
                                    title: Text(
                                      formName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('Toplam Skor: $totalScore'),
                                        if (createdAt != null)
                                          Text(
                                            'Doldurulma Tarihi: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(createdAt))}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                      ],
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.visibility),
                                      onPressed: () {
                                        _showFormAnswerDetails(answer);
                                      },
                                      tooltip: 'Detayları Görüntüle',
                                    ),
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
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton.icon(
                              onPressed: _assignFileToPatient,
                              icon: const Icon(Icons.add_link),
                              label: const Text('Dosyaya Ekle'),
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
                                return Card(
                                  child: ExpansionTile(
                                    leading: const Icon(Icons.folder),
                                    title: Text(file.name),
                                    children: [
                                      if (file.forms != null &&
                                          file.forms!.isNotEmpty)
                                        ...file.forms!.map((form) => ListTile(
                                              leading:
                                                  const Icon(Icons.description),
                                              title: Text(
                                                form.name,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              subtitle: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    form.description,
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  if (_completedFormIds
                                                      .contains(form.id))
                                                    const Padding(
                                                      padding: EdgeInsets.only(
                                                          top: 6.0),
                                                      child: Chip(
                                                          label: Text(
                                                              'Dolduruldu')),
                                                    ),
                                                ],
                                              ),
                                              trailing: FilledButton(
                                                onPressed: _completedFormIds
                                                        .contains(form.id)
                                                    ? null
                                                    : () async {
                                                        print(
                                                            'DEBUG: Form doldurma butonuna basıldı - Form ID: ${form.id}');
                                                        print(
                                                            'DEBUG: Mevcut _completedFormIds: $_completedFormIds');

                                                        // Önce mevcut durumu kontrol et
                                                        if (_completedFormIds
                                                            .contains(
                                                                form.id)) {
                                                          print(
                                                              'DEBUG: Form zaten _completedFormIds içinde');
                                                          if (mounted) {
                                                            ScaffoldMessenger
                                                                    .of(context)
                                                                .showSnackBar(
                                                              const SnackBar(
                                                                  content: Text(
                                                                      'Bu form zaten doldurulmuş.')),
                                                            );
                                                          }
                                                          return;
                                                        }

                                                        // API'den tekrar kontrol et
                                                        print(
                                                            'DEBUG: API\'den tekrar kontrol ediliyor...');
                                                        final answers =
                                                            await _formAnswerService
                                                                .getAnswers(
                                                          patientId:
                                                              widget.patient.id,
                                                          formId: form.id,
                                                        );
                                                        print(
                                                            'DEBUG: API\'den dönen cevaplar (form özelinde): $answers');

                                                        // Client-side doğrulama: sadece bu hasta + bu form kayıtlarını dikkate al
                                                        final alreadyFilled =
                                                            answers.any((a) =>
                                                                a['patient_id'] ==
                                                                    widget
                                                                        .patient
                                                                        .id &&
                                                                a['form_id'] ==
                                                                    form.id);

                                                        if (alreadyFilled) {
                                                          print(
                                                              'DEBUG: Client-side filtre ile bu hasta+form için cevap bulundu');
                                                          if (mounted) {
                                                            ScaffoldMessenger
                                                                    .of(context)
                                                                .showSnackBar(
                                                              const SnackBar(
                                                                  content: Text(
                                                                      'Bu form zaten doldurulmuş.')),
                                                            );
                                                          }
                                                          // Listeyi yenile
                                                          await _loadCompletedForms();
                                                          return;
                                                        }

                                                        print(
                                                            'DEBUG: Form doldurulmamış, stepper açılıyor');

                                                        final result =
                                                            await Navigator
                                                                .push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder: (context) =>
                                                                FormFillStepper(
                                                              formId: form.id,
                                                              patientId: widget
                                                                  .patient.id,
                                                            ),
                                                          ),
                                                        );
                                                        if (result is Map &&
                                                            result['status'] ==
                                                                'success' &&
                                                            result['formId'] ==
                                                                form.id) {
                                                          await _loadCompletedForms();
                                                        }
                                                      },
                                                child: Text(_completedFormIds
                                                        .contains(form.id)
                                                    ? 'Dolduruldu'
                                                    : 'Formu Doldur'),
                                              ),
                                            ))
                                      else
                                        const ListTile(
                                          leading: Icon(Icons.info_outline),
                                          title: Text(
                                              'Bu dosyada form bulunmuyor'),
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
