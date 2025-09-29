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

  // Form controllers
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Form data
  String _selectedFormType = 'for patients';
  String _selectedRepetitionTime = '-';
  List<Question> _questions = [];

  // Services
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
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      // Go to first step with errors
      setState(() {
        _currentStep = 0;
      });
      return;
    }

    if (_questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen en az bir soru ekleyin'),
          backgroundColor: Colors.orange,
        ),
      );
      setState(() {
        _currentStep = 1; // Go to questions step
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

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
          // Önce loading durumunu kapat
          setState(() {
            _isLoading = false;
          });

          // Başarı mesajını göster
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Form başarıyla oluşturuldu'),
              backgroundColor: Theme.of(context).colorScheme.primary,
              behavior: SnackBarBehavior.floating,
            ),
          );

          // Form listesini güncelle
          widget.onFormAdded();

          // Form sayfasını kapat (kısa bir gecikme ile)
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted) {
              Navigator.pop(context);
            }
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
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
        setState(() {
          _isLoading = false;
        });
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

  Widget _buildSummaryCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                'Tekrarlama Süresi',
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
              const Text(
                'Sorular:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ..._questions.asMap().entries.map((entry) {
                final index = entry.key;
                final question = entry.value;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
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
                              question.question,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            if (question.options != null &&
                                question.options!.isNotEmpty)
                              Text(
                                'Seçenekler: ${question.options!.map((opt) => opt.option).join(", ")}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            Text(
                              'Tip: ${question.type == 'text' ? 'Metin' : 'Çoktan Seçmeli'}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
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
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
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
        return true; // Özet sayfası
      default:
        return false;
    }
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
          decoration: const InputDecoration(
            labelText: 'Form Adı *',
            prefixIcon: Icon(Icons.description),
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Lütfen form adını girin';
            }
            return null;
          },
          onChanged: (value) {
            setState(() {}); // UI'ı güncelle
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _descriptionController,
          decoration: const InputDecoration(
            labelText: 'Form Açıklaması *',
            prefixIcon: Icon(Icons.info),
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          maxLines: 3,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Lütfen form açıklamasını girin';
            }
            return null;
          },
          onChanged: (value) {
            setState(() {}); // UI'ı güncelle
          },
        ),
        const SizedBox(height: 24),
        const Text(
          'Tekrarlama Süresi *',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedRepetitionTime,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.schedule),
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
          onChanged: (value) {
            setState(() {
              _selectedRepetitionTime = value!;
            });
          },
        ),
        const SizedBox(height: 24),
        const Text(
          'Form Tipi *',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              RadioListTile<String>(
                title: const Text('Hastaya Gönder'),
                subtitle: const Text('Hastalar bu formu doldurabilir'),
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
                subtitle: const Text('Sadece doktorlar bu formu doldurabilir'),
                value: 'for me',
                groupValue: _selectedFormType,
                onChanged: (value) {
                  setState(() {
                    _selectedFormType = value!;
                  });
                },
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
                onPressed: () => _addTextQuestion(),
                icon: const Icon(Icons.text_fields),
                label: const Text('Metin Sorusu'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _addMultipleChoiceQuestion(),
                icon: const Icon(Icons.check_box),
                label: const Text('Çoktan Seçmeli'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Eklenen sorular
        if (_questions.isEmpty)
          Card(
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.quiz_outlined,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Henüz soru eklenmemiş',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Yukarıdaki butonları kullanarak sorular ekleyin',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else ...[
          const Text(
            'Eklenen Sorular',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ..._questions.asMap().entries.map((entry) {
            final index = entry.key;
            final question = entry.value;
            return _buildQuestionCard(index, question);
          }),
        ],
      ],
    );
  }

  Widget _buildStep2Content() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSummaryCard(),
        const SizedBox(height: 24),
        Card(
          color: Colors.blue[50],
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.blue[700],
                ),
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
        ),
      ],
    );
  }

  // Yeni inline soru ekleme metodları
  void _addTextQuestion() {
    HapticFeedback.lightImpact();
    setState(() {
      _questions.add(Question(
        question: '',
        type: 'text',
        level: 10,
      ));
    });
  }

  void _addMultipleChoiceQuestion() {
    HapticFeedback.lightImpact();
    setState(() {
      _questions.add(Question(
        question: '',
        options: <OptionModel>[],
        type: 'multiple_choice',
        level: 10,
      ));
    });
  }

  // Soru kartı oluşturma metodu
  Widget _buildQuestionCard(int index, Question question) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        title: Text(
          question.question.isEmpty
              ? 'Yeni ${question.type == 'text' ? 'Metin' : 'Çoktan Seçmeli'} Sorusu'
              : question.question,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color:
                question.question.isEmpty ? Colors.grey[600] : Colors.black87,
          ),
        ),
        subtitle: question.type == 'multiple_choice' &&
                question.options != null &&
                question.options!.isNotEmpty
            ? Text('${question.options!.length} seçenek')
            : question.type == 'text'
                ? const Text('Metin sorusu')
                : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                HapticFeedback.lightImpact();
                setState(() {
                  _questions.removeAt(index);
                });
              },
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: question.type == 'text'
                ? _buildTextQuestionEditor(index, question)
                : _buildMultipleChoiceQuestionEditor(index, question),
          ),
        ],
      ),
    );
  }

  // Metin sorusu editörü
  Widget _buildTextQuestionEditor(int index, Question question) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          initialValue: question.question,
          decoration: const InputDecoration(
            labelText: 'Soru *',
            prefixIcon: Icon(Icons.question_mark),
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          maxLines: 2,
          onChanged: (value) {
            setState(() {
              _questions[index] = Question(
                question: value,
                type: 'text',
                level: 10,
              );
            });
          },
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Icon(Icons.text_fields, color: Colors.blue),
            const SizedBox(width: 8),
            const Text('Metin Sorusu'),
            const Spacer(),
            Switch(
              value: true, // Zorunlu soru (şimdilik her zaman true)
              onChanged: (value) {
                // Zorunlu soru özelliği için gelecekte kullanılabilir
              },
            ),
            const Text('Zorunlu'),
          ],
        ),
      ],
    );
  }

  // Çoktan seçmeli soru editörü
  Widget _buildMultipleChoiceQuestionEditor(int index, Question question) {
    List<OptionModel> options = List.from(question.options ?? []);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          initialValue: question.question,
          decoration: const InputDecoration(
            labelText: 'Soru *',
            prefixIcon: Icon(Icons.question_mark),
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          maxLines: 2,
          onChanged: (value) {
            setState(() {
              _questions[index] = Question(
                question: value,
                options: options,
                type: 'multiple_choice',
                level: 10,
              );
            });
          },
        ),
        const SizedBox(height: 16),

        // Seçenek ekleme alanı
        Row(
          children: [
            Expanded(
              child: TextFormField(
                key: ValueKey('option_$index'),
                decoration: const InputDecoration(
                  labelText: 'Seçenek ekle',
                  prefixIcon: Icon(Icons.add_circle_outline),
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onFieldSubmitted: (value) {
                  if (value.trim().isNotEmpty) {
                    HapticFeedback.lightImpact();
                    setState(() {
                      options.add(OptionModel(
                        option: value.trim(),
                        optionLevel: 5, // Varsayılan değer
                      ));
                      _questions[index] = Question(
                        question: _questions[index].question,
                        options: options,
                        type: 'multiple_choice',
                        level: 10,
                      );
                    });
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                // Bu buton şimdilik sadece görsel amaçlı
                // Seçenek ekleme sadece Enter tuşu ile yapılıyor
              },
              child: const Icon(Icons.add),
            ),
          ],
        ),

        // Seçenekler (Düzenlenebilir kartlar)
        if (options.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text(
            'Seçenekler:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...options.asMap().entries.map((entry) {
            final optionIndex = entry.key;
            final option = entry.value;
            return _buildOptionCard(index, optionIndex, option, options);
          }),
        ],

        const SizedBox(height: 16),
        Row(
          children: [
            const Icon(Icons.check_box, color: Colors.green),
            const SizedBox(width: 8),
            const Text('Çoktan Seçmeli Soru'),
            const Spacer(),
            Switch(
              value: true, // Zorunlu soru (şimdilik her zaman true)
              onChanged: (value) {
                // Zorunlu soru özelliği için gelecekte kullanılabilir
              },
            ),
            const Text('Zorunlu'),
          ],
        ),
      ],
    );
  }

  // Seçenek kartı oluşturma metodu
  Widget _buildOptionCard(int questionIndex, int optionIndex,
      OptionModel option, List<OptionModel> options) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: option.option,
                decoration: const InputDecoration(
                  labelText: 'Seçenek',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onChanged: (value) {
                  setState(() {
                    options[optionIndex] = OptionModel(
                      option: value,
                      optionLevel: option.optionLevel,
                    );
                    _questions[questionIndex] = Question(
                      question: _questions[questionIndex].question,
                      options: options,
                      type: 'multiple_choice',
                      level: 10,
                    );
                  });
                },
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 60,
              child: DropdownButton<int>(
                value: option.optionLevel,
                isExpanded: true,
                items: List.generate(10, (i) => i + 1)
                    .map((level) => DropdownMenuItem(
                          value: level,
                          child: Text("$level"),
                        ))
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      options[optionIndex] = OptionModel(
                        option: option.option,
                        optionLevel: val,
                      );
                      _questions[questionIndex] = Question(
                        question: _questions[questionIndex].question,
                        options: options,
                        type: 'multiple_choice',
                        level: 10,
                      );
                    });
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
              onPressed: () {
                HapticFeedback.lightImpact();
                setState(() {
                  options.removeAt(optionIndex);
                  _questions[questionIndex] = Question(
                    question: _questions[questionIndex].question,
                    options: options,
                    type: 'multiple_choice',
                    level: 10,
                  );
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yeni Form Oluştur'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Step Progress Indicator
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
            // Form Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Step Title and Subtitle
                    Text(
                      _getStepTitle(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getStepSubtitle(),
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Step Content
                    _buildCurrentStepContent(),
                    const SizedBox(height: 32),
                    // Navigation Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (_currentStep > 0)
                          OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _currentStep -= 1;
                              });
                            },
                            child: const Text('Geri'),
                          )
                        else
                          const SizedBox(),
                        ElevatedButton(
                          onPressed: _isLoading
                              ? null
                              : (_canProceed()
                                  ? () {
                                      if (_currentStep < 2) {
                                        setState(() {
                                          _currentStep += 1;
                                        });
                                      } else {
                                        _submitForm();
                                      }
                                    }
                                  : null),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _canProceed()
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey,
                            foregroundColor:
                                _canProceed() ? Colors.white : Colors.grey[600],
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Text(
                                  _currentStep == 2 ? 'Form Oluştur' : 'İleri'),
                        ),
                      ],
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
}
