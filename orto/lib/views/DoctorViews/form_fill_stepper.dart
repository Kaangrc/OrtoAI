import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ortopedi_ai/models/form_model.dart';
import 'package:ortopedi_ai/models/option_model.dart';
import 'package:ortopedi_ai/services/form_service.dart';
import 'package:ortopedi_ai/utils/api_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class FormStepper extends StatefulWidget {
  final String fileId;
  final VoidCallback onFormAdded;

  const FormStepper({
    Key? key,
    required this.fileId,
    required this.onFormAdded,
  }) : super(key: key);

  @override
  State<FormStepper> createState() => _FormStepperState();
}

class _FormStepperState extends State<FormStepper> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;
  bool _isLoading = false;

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedFormType = 'for patients';
  String _selectedRepetitionTime = '-';
  List<Question> _questions = [];

  // Soru düzenleme için
  int? _editingQuestionIndex;
  final _questionTextController = TextEditingController();
  final _optionController = TextEditingController();
  String _currentQuestionType = 'text';
  List<OptionModel> _tempOptions = [];

  late final DioClient _dioClient;
  late final FormService _formService;

  @override
  void initState() {
    super.initState();
    const storage = FlutterSecureStorage();
    _dioClient = DioClient(storage: storage);
    _formService = FormService(dioClient: _dioClient, secureStorage: storage);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _questionTextController.dispose();
    _optionController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      setState(() => _currentStep = 0);
      return;
    }

    if (_questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen en az bir soru ekleyin'),
          backgroundColor: Colors.orange,
        ),
      );
      setState(() => _currentStep = 1);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final formData = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'questions': _questions
            .map((q) => {
                  'question': q.question,
                  'options': q.options?.map((opt) => opt.toJson()).toList(),
                  'type': q.type,
                  'level': 10,
                })
            .toList(),
        'type': _selectedFormType,
        'file_id': widget.fileId,
        'level': 10,
        'repeat': _selectedRepetitionTime,
      };

      final response = await _formService.addForm(formData);

      if (response['status'] == 'success') {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Form başarıyla oluşturuldu'),
              backgroundColor: Theme.of(context).colorScheme.primary,
              behavior: SnackBarBehavior.floating,
            ),
          );
          widget.onFormAdded();
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted) Navigator.pop(context);
          });
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Form oluşturulamadı'),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Form oluşturulurken hata oluştu: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _startAddingQuestion(String type) {
    setState(() {
      _editingQuestionIndex = null;
      _currentQuestionType = type;
      _questionTextController.clear();
      _optionController.clear();
      _tempOptions = [];
    });
    _showQuestionDialog();
  }

  void _editQuestion(int index) {
    final q = _questions[index];
    setState(() {
      _editingQuestionIndex = index;
      _currentQuestionType = q.type;
      _questionTextController.text = q.question;
      _tempOptions = List.from(q.options ?? []);
      _optionController.clear();
    });
    _showQuestionDialog();
  }

  void _showQuestionDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Text(
                          _editingQuestionIndex == null
                              ? 'Yeni Soru Ekle'
                              : 'Soruyu Düzenle',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          if (_questionTextController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Soru metni boş olamaz')),
                            );
                            return;
                          }
                          if (_currentQuestionType == 'multiple_choice' &&
                              _tempOptions.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('En az bir seçenek eklemelisiniz')),
                            );
                            return;
                          }

                          final newQuestion = Question(
                            question: _questionTextController.text.trim(),
                            type: _currentQuestionType,
                            options: _currentQuestionType == 'multiple_choice'
                                ? _tempOptions
                                : null,
                            level: 10,
                          );

                          setState(() {
                            if (_editingQuestionIndex != null) {
                              _questions[_editingQuestionIndex!] = newQuestion;
                            } else {
                              _questions.add(newQuestion);
                            }
                          });

                          Navigator.pop(context);
                          HapticFeedback.mediumImpact();
                        },
                        child: Text(
                          _editingQuestionIndex == null ? 'Ekle' : 'Kaydet',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Soru tipi seçimi
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setModalState(() {
                                      _currentQuestionType = 'text';
                                      _tempOptions = [];
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    decoration: BoxDecoration(
                                      color: _currentQuestionType == 'text'
                                          ? Theme.of(context)
                                              .colorScheme
                                              .primary
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.text_fields,
                                          color: _currentQuestionType == 'text'
                                              ? Colors.white
                                              : Colors.grey[600],
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Metin',
                                          style: TextStyle(
                                            color:
                                                _currentQuestionType == 'text'
                                                    ? Colors.white
                                                    : Colors.grey[600],
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setModalState(() {
                                      _currentQuestionType = 'multiple_choice';
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    decoration: BoxDecoration(
                                      color: _currentQuestionType ==
                                              'multiple_choice'
                                          ? Theme.of(context)
                                              .colorScheme
                                              .primary
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.radio_button_checked,
                                          color: _currentQuestionType ==
                                                  'multiple_choice'
                                              ? Colors.white
                                              : Colors.grey[600],
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Çoktan Seçmeli',
                                          style: TextStyle(
                                            color: _currentQuestionType ==
                                                    'multiple_choice'
                                                ? Colors.white
                                                : Colors.grey[600],
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Soru metni
                        TextFormField(
                          controller: _questionTextController,
                          decoration: InputDecoration(
                            labelText: 'Soru',
                            hintText: 'Sorunuzu buraya yazın...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                            contentPadding: const EdgeInsets.all(16),
                          ),
                          maxLines: 3,
                          textInputAction: TextInputAction.done,
                        ),

                        // Çoktan seçmeli için seçenekler
                        if (_currentQuestionType == 'multiple_choice') ...[
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              const Text(
                                'Seçenekler',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${_tempOptions.length} seçenek',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Seçenek ekleme
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer
                                  .withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _optionController,
                                    decoration: const InputDecoration(
                                      hintText: 'Yeni seçenek...',
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                    ),
                                    onSubmitted: (value) {
                                      if (value.trim().isNotEmpty) {
                                        setModalState(() {
                                          _tempOptions.add(OptionModel(
                                            option: value.trim(),
                                            optionLevel: 5,
                                          ));
                                        });
                                        _optionController.clear();
                                        HapticFeedback.lightImpact();
                                      }
                                    },
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.add_circle,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                  onPressed: () {
                                    if (_optionController.text
                                        .trim()
                                        .isNotEmpty) {
                                      setModalState(() {
                                        _tempOptions.add(OptionModel(
                                          option: _optionController.text.trim(),
                                          optionLevel: 5,
                                        ));
                                      });
                                      _optionController.clear();
                                      HapticFeedback.lightImpact();
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Eklenen seçenekler
                          if (_tempOptions.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Column(
                                children: [
                                  Icon(Icons.list_alt,
                                      size: 40, color: Colors.grey[400]),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Henüz seçenek eklenmedi',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            )
                          else
                            ..._tempOptions.asMap().entries.map((entry) {
                              final index = entry.key;
                              final option = entry.value;
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: ListTile(
                                  leading: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${index + 1}',
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  title: Text(option.option),
                                  subtitle: Text(
                                    'Puan: ${option.optionLevel}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Puan seçici
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[100],
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: DropdownButton<int>(
                                          value: option.optionLevel,
                                          underline: const SizedBox(),
                                          isDense: true,
                                          items: List.generate(10, (i) => i + 1)
                                              .map((level) => DropdownMenuItem(
                                                    value: level,
                                                    child: Text('$level'),
                                                  ))
                                              .toList(),
                                          onChanged: (val) {
                                            if (val != null) {
                                              setModalState(() {
                                                _tempOptions[index] =
                                                    OptionModel(
                                                  option: option.option,
                                                  optionLevel: val,
                                                );
                                              });
                                            }
                                          },
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline,
                                            color: Colors.red),
                                        onPressed: () {
                                          setModalState(() {
                                            _tempOptions.removeAt(index);
                                          });
                                          HapticFeedback.lightImpact();
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yeni Form Oluştur'),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Progress Indicator
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: List.generate(3, (index) {
                  final isActive = index == _currentStep;
                  final isCompleted = index < _currentStep;
                  return Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isActive || isCompleted
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.grey[300],
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: isActive || isCompleted
                                      ? Colors.white
                                      : Colors.grey[600],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (index < 2)
                          Expanded(
                            child: Container(
                              height: 2,
                              color: isCompleted
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.grey[300],
                            ),
                          ),
                      ],
                    ),
                  );
                }),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getStepTitle(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getStepSubtitle(),
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 24),
                    _buildCurrentStepContent(),
                    const SizedBox(height: 32),
                    _buildNavigationButtons(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 0:
        return 'Form Bilgileri';
      case 1:
        return 'Sorular';
      case 2:
        return 'Özet ve Onay';
      default:
        return '';
    }
  }

  String _getStepSubtitle() {
    switch (_currentStep) {
      case 0:
        return 'Formun temel bilgilerini girin';
      case 1:
        return 'Forma sorular ekleyin';
      case 2:
        return 'Bilgileri kontrol edin ve formu oluşturun';
      default:
        return '';
    }
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStep0Content();
      case 1:
        return _buildStep1Content();
      case 2:
        return _buildStep2Content();
      default:
        return const SizedBox();
    }
  }

  Widget _buildStep0Content() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'Form Adı',
            prefixIcon: const Icon(Icons.description),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          validator: (value) =>
              value?.isEmpty ?? true ? 'Form adı gerekli' : null,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _descriptionController,
          decoration: InputDecoration(
            labelText: 'Form Açıklaması',
            prefixIcon: const Icon(Icons.info_outline),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          maxLines: 3,
          validator: (value) =>
              value?.isEmpty ?? true ? 'Açıklama gerekli' : null,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 24),
        const Text('Tekrarlama Süresi',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedRepetitionTime,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.schedule),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          items: const [
            DropdownMenuItem(value: '-', child: Text('Tekrarlama Yok')),
            DropdownMenuItem(value: '1 ay', child: Text('1 Ay')),
            DropdownMenuItem(value: '3 ay', child: Text('3 Ay')),
            DropdownMenuItem(value: '6 ay', child: Text('6 Ay')),
            DropdownMenuItem(value: '9 ay', child: Text('9 Ay')),
            DropdownMenuItem(value: '12 ay', child: Text('12 Ay')),
            DropdownMenuItem(value: '15 ay', child: Text('15 Ay')),
          ],
          onChanged: (value) =>
              setState(() => _selectedRepetitionTime = value!),
        ),
        const SizedBox(height: 24),
        const Text('Form Tipi',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            children: [
              RadioListTile<String>(
                title: const Text('Hastaya Gönder'),
                subtitle: const Text('Hastalar bu formu doldurabilir'),
                value: 'for patients',
                groupValue: _selectedFormType,
                onChanged: (value) =>
                    setState(() => _selectedFormType = value!),
              ),
              Divider(height: 1, color: Colors.grey[300]),
              RadioListTile<String>(
                title: const Text('Kendin Doldur'),
                subtitle: const Text('Sadece doktorlar bu formu doldurabilir'),
                value: 'for me',
                groupValue: _selectedFormType,
                onChanged: (value) =>
                    setState(() => _selectedFormType = value!),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep1Content() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Soru ekleme butonları
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _startAddingQuestion('text'),
                icon: const Icon(Icons.text_fields),
                label: const Text('Metin Sorusu'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _startAddingQuestion('multiple_choice'),
                icon: const Icon(Icons.radio_button_checked),
                label: const Text('Çoktan Seçmeli'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Sorular listesi
        if (_questions.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              children: [
                Icon(Icons.quiz_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Henüz soru eklenmemiş',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Yukarıdaki butonları kullanarak sorular ekleyin',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _questions.length,
            itemBuilder: (context, index) =>
                _buildQuestionCard(index, _questions[index]),
          ),
      ],
    );
  }

  Widget _buildQuestionCard(int index, Question question) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _editQuestion(index),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          question.type == 'text'
                              ? Icons.text_fields
                              : Icons.radio_button_checked,
                          size: 18,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          question.type == 'text'
                              ? 'Metin Sorusu'
                              : 'Çoktan Seçmeli',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      question.question,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                    if (question.type == 'multiple_choice' &&
                        question.options != null &&
                        question.options!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: question.options!.take(3).map((opt) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              opt.option,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[700],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      if (question.options!.length > 3)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            '+${question.options!.length - 3} seçenek daha',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  setState(() => _questions.removeAt(index));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep2Content() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSummaryCard(),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[700]),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Form oluşturulduktan sonra düzenleyemezsiniz. Lütfen bilgileri kontrol edin.',
                  style: TextStyle(
                    color: Colors.blue[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Form Bilgileri Özeti',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildSummaryRow('Form Adı', _nameController.text),
          _buildSummaryRow('Açıklama', _descriptionController.text),
          _buildSummaryRow(
              'Tekrarlama',
              _selectedRepetitionTime == '-'
                  ? 'Tekrarlama Yok'
                  : _selectedRepetitionTime),
          _buildSummaryRow(
              'Form Tipi',
              _selectedFormType == 'for patients'
                  ? 'Hastaya Gönder'
                  : 'Kendin Doldur'),
          _buildSummaryRow('Soru Sayısı', '${_questions.length} soru'),
          if (_questions.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            const Text(
              'Sorular:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ..._questions.asMap().entries.map((entry) {
              final idx = entry.key;
              final q = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${idx + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            q.question,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            q.type == 'text'
                                ? 'Metin Sorusu'
                                : 'Çoktan Seçmeli',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                          if (q.options != null && q.options!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'Seçenekler: ${q.options!.map((o) => o.option).join(", ")}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (_currentStep > 0)
          OutlinedButton.icon(
            onPressed: () => setState(() => _currentStep -= 1),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Geri'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          )
        else
          const SizedBox(),
        ElevatedButton.icon(
          onPressed: _isLoading
              ? null
              : (_canProceed()
                  ? () {
                      if (_currentStep < 2) {
                        setState(() => _currentStep += 1);
                      } else {
                        _submitForm();
                      }
                    }
                  : null),
          icon: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Icon(
                  _currentStep == 2 ? Icons.check_circle : Icons.arrow_forward),
          label: Text(_isLoading
              ? 'İşleniyor...'
              : (_currentStep == 2 ? 'Form Oluştur' : 'İleri')),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return _nameController.text.trim().isNotEmpty &&
            _descriptionController.text.trim().isNotEmpty;
      case 1:
        return _questions.isNotEmpty;
      case 2:
        return true;
      default:
        return false;
    }
  }
}
