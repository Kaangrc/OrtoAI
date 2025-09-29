import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:ortopedi_ai/services/form_service.dart';
import 'package:ortopedi_ai/models/form_model.dart';
import 'package:ortopedi_ai/models/option_model.dart';
import 'package:ortopedi_ai/services/patient_service.dart';
import 'package:ortopedi_ai/models/patientmodel.dart';
import 'package:ortopedi_ai/utils/api_client.dart';
import 'package:ortopedi_ai/services/form_answer_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class DFormPage extends StatefulWidget {
  final String formId;
  final String? preselectedPatientId;
  const DFormPage({super.key, required this.formId, this.preselectedPatientId});

  @override
  State<DFormPage> createState() => _DFormPageState();
}

class _DFormPageState extends State<DFormPage> with TickerProviderStateMixin {
  final FormService _formService = FormService(
    dioClient: DioClient(storage: const FlutterSecureStorage()),
  );
  final PatientService _patientService = PatientService(
    dioClient: DioClient(storage: const FlutterSecureStorage()),
  );
  final FormAnswerService _formAnswerService = FormAnswerService(
    dioClient: DioClient(storage: const FlutterSecureStorage()),
  );

  FormModel? _form;
  List<PatientModel> _patients = [];
  final Set<String> _completedForPatient = {}; // patientId set
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isUpdating = false;
  bool _isSubmitting = false;

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedFormType = 'for patients';
  String _selectedRepetitionTime = '-';
  String? _selectedPatientId;
  List<Map<String, dynamic>> _answers = [];

  late AnimationController _fabAnimationController;
  late AnimationController _slideAnimationController;
  late Animation<double> _fabScaleAnimation;
  late Animation<Offset> _slideAnimation;

  // Scroll controller for better UX
  final ScrollController _scrollController = ScrollController();
  bool _showFab = true;

  @override
  void initState() {
    super.initState();
    _initializeLocale();
    _setupAnimations();
    _setupScrollListener();
    _loadForm();
  }

  Future<void> _initializeLocale() async {
    await initializeDateFormatting('tr', null);
  }

  String _formatDate(DateTime date) {
    try {
      return DateFormat('dd MMMM yyyy, HH:mm', 'tr').format(date);
    } catch (e) {
      // Fallback to simple format if locale is not available
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
    }
  }

  void _setupAnimations() {
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fabScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _fabAnimationController, curve: Curves.elasticOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
        parent: _slideAnimationController, curve: Curves.easeOut));

    _slideAnimationController.forward();
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.userScrollDirection ==
          ScrollDirection.reverse) {
        if (_showFab) {
          setState(() => _showFab = false);
          _fabAnimationController.reverse();
        }
      } else if (_scrollController.position.userScrollDirection ==
          ScrollDirection.forward) {
        if (!_showFab) {
          setState(() => _showFab = true);
          _fabAnimationController.forward();
        }
      }
    });
  }

  Future<void> _loadForm() async {
    try {
      final form = await _formService.getFormInfo(widget.formId);
      setState(() {
        _form = form;
        _nameController.text = form.name;
        _descriptionController.text = form.description;
        _selectedFormType = form.type;
        _selectedRepetitionTime = form.repeat ?? '-';
      });

      if (form.fileId != null) {
        await _loadPatients(form.fileId!);
      }

      // Hasta ön seçimi
      _selectedPatientId = widget.preselectedPatientId ?? _selectedPatientId;

      // Cevap dizisini hazırla
      if (form.questions != null) {
        _answers = List.generate(form.questions!.length, (index) {
          return {
            'value': null,
            'option_level': null,
          };
        });
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Form yüklenirken hata oluştu: $e');
    }
  }

  Future<void> _loadPatients(String fileId) async {
    try {
      final patients = await _patientService.getAllPatients();
      final attached = patients
          .where((patient) => patient.fileIds?.contains(fileId) ?? false)
          .toList();
      // doldurulmuş kontrolü
      final completed = <String>{};
      for (final p in attached) {
        final answers = await _formAnswerService.getAnswers(
          patientId: p.id,
          formId: _form?.id,
        );
        if (answers.isNotEmpty) completed.add(p.id);
      }
      if (mounted) {
        setState(() {
          _patients = attached;
          _completedForPatient
            ..clear()
            ..addAll(completed);
        });
      }
    } catch (e) {
      _showErrorSnackBar('Hastalar yüklenirken hata oluştu: $e');
    }
  }

  void _toggleEditMode() {
    HapticFeedback.lightImpact();
    setState(() {
      _isEditing = !_isEditing;
      if (_isEditing) {
        _fabAnimationController.forward();
      } else {
        _fabAnimationController.reverse();
      }
    });
  }

  Future<void> _updateForm() async {
    if (_form == null) return;

    setState(() => _isUpdating = true);
    HapticFeedback.mediumImpact();

    try {
      final updatedData = {
        'name': _nameController.text,
        'description': _descriptionController.text,
        'type': _selectedFormType,
        'repeat': _selectedRepetitionTime,
        'questions': _form!.questions?.map((q) => q.toJson()).toList(),
        'file_id': _form!.fileId,
        'level': _form!.level,
      };

      final result = await _formService.updateForm(_form!.id, updatedData);

      if (result['status'] == 'success') {
        await _loadForm();
        setState(() => _isEditing = false);
        _showSuccessSnackBar('Form başarıyla güncellendi');
        _fabAnimationController.reverse();
      } else {
        _showErrorSnackBar(result['message'] ?? 'Bir hata oluştu');
      }
    } catch (e) {
      _showErrorSnackBar('Form güncellenirken hata oluştu: $e');
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  Future<void> _deleteQuestion(int questionIndex) async {
    final confirmed = await _showDeleteDialog(
      title: 'Soruyu Sil',
      content: 'Bu soruyu silmek istediğinizden emin misiniz?',
    );

    if (confirmed && _form != null) {
      HapticFeedback.heavyImpact();
      setState(() {
        final newQuestions = List<Question>.from(_form!.questions ?? []);
        newQuestions.removeAt(questionIndex);
        _form = _form!.copyWith(questions: newQuestions);
      });
      await _updateForm();
    }
  }

  Future<void> _refreshData() async {
    HapticFeedback.lightImpact();
    await _loadForm();
  }

  Future<void> _editQuestion(int questionIndex, Question question) async {
    HapticFeedback.lightImpact();

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _QuestionEditBottomSheet(
        question: question,
        questionIndex: questionIndex,
      ),
    );

    if (result != null && _form != null) {
      setState(() {
        final newQuestions = List<Question>.from(_form!.questions ?? []);
        newQuestions[questionIndex] = Question(
          question: result['question'] ?? question.question,
          options: result['options'] ?? question.options,
          type: result['type'] ?? question.type,
          level: question.level,
        );
        _form = _form!.copyWith(questions: newQuestions);
      });
      await _updateForm();
    }
  }

  Future<void> _addNewQuestion() async {
    HapticFeedback.lightImpact();

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _QuestionEditBottomSheet(
        question: null,
        questionIndex: -1,
      ),
    );

    if (result != null && _form != null) {
      setState(() {
        final newQuestions = List<Question>.from(_form!.questions ?? []);
        newQuestions.add(Question(
          question: result['question'] ?? '',
          options: result['options'],
          type: result['type'] ?? 'text',
          level: 10,
        ));
        _form = _form!.copyWith(questions: newQuestions);
      });
      await _updateForm();
    }
  }

  Future<void> _deleteForm() async {
    final confirmed = await _showDeleteDialog(
      title: 'Formu Sil',
      content:
          'Bu formu silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.',
    );

    if (confirmed && _form != null) {
      HapticFeedback.heavyImpact();
      try {
        final result = await _formService.deleteForm(_form!.id);
        if (result['status'] == 'success') {
          _showSuccessSnackBar('Form başarıyla silindi');
          Navigator.pop(context);
        } else {
          _showErrorSnackBar(
              result['message'] ?? 'Form silinirken hata oluştu');
        }
      } catch (e) {
        _showErrorSnackBar('Form silinirken hata oluştu: $e');
      }
    }
  }

  Future<void> _copyForm() async {
    HapticFeedback.lightImpact();
    if (_form == null) return;

    try {
      final copiedData = {
        'name': '${_form!.name} (Kopya)',
        'description': _form!.description,
        'questions': _form!.questions?.map((q) => q.toJson()).toList(),
        'type': _form!.type,
        'file_id': _form!.fileId,
        'level': _form!.level,
      };

      final result = await _formService.addForm(copiedData);

      if (result['status'] == 'success') {
        _showSuccessSnackBar('Form başarıyla kopyalandı');
      } else {
        _showErrorSnackBar(
            result['message'] ?? 'Form kopyalanırken hata oluştu');
      }
    } catch (e) {
      _showErrorSnackBar('Form kopyalanırken hata oluştu: $e');
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<bool> _showDeleteDialog(
      {required String title, required String content}) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(Icons.warning, color: Colors.orange.shade700),
                const SizedBox(width: 12),
                Text(title),
              ],
            ),
            content: Text(content),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('İptal'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                ),
                child: const Text('Sil'),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _form == null
              ? _buildErrorState()
              : SlideTransition(
                  position: _slideAnimation,
                  child: CustomScrollView(
                    controller: _scrollController,
                    slivers: [
                      _buildAppBar(),
                      SliverPadding(
                        padding: const EdgeInsets.all(16),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            _buildFormInfoCard(),
                            const SizedBox(height: 16),
                            _buildQuestionsCard(),
                            const SizedBox(height: 16),
                            _buildPatientsCard(),
                            const SizedBox(height: 100), // FAB için alan
                          ]),
                        ),
                      ),
                    ],
                  ),
                ),
      floatingActionButton: _isEditing
          ? ScaleTransition(
              scale: _fabScaleAnimation,
              child: FloatingActionButton.extended(
                onPressed: _isUpdating ? null : _updateForm,
                backgroundColor: _isUpdating
                    ? Theme.of(context).colorScheme.outline
                    : Theme.of(context).colorScheme.primary,
                icon: _isUpdating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.save),
                label: Text(_isUpdating ? 'Kaydediliyor...' : 'Kaydet'),
              ),
            )
          : null,
    );
  }

  Widget _buildFillFormCard() {
    if (_form == null) return const SizedBox.shrink();
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.assignment,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Formu Doldur',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (widget.preselectedPatientId == null) ...[
              DropdownButtonFormField<String>(
                value: _selectedPatientId,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.person),
                  labelText: 'Hasta Seçin',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: _patients
                    .map((p) => DropdownMenuItem(
                          value: p.id,
                          child: Text('${p.firstName} ${p.lastName}'),
                        ))
                    .toList(),
                onChanged: (val) => setState(() => _selectedPatientId = val),
              ),
              const SizedBox(height: 16),
            ],
            if (_form!.questions != null && _form!.questions!.isNotEmpty)
              ..._form!.questions!.asMap().entries.map((entry) {
                final index = entry.key;
                final question = entry.value;
                return _buildAnswerInput(index, question);
              }).toList(),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: _isSubmitting ? null : _submitAnswers,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
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

  Widget _buildAnswerInput(int index, Question question) {
    if (question.type == 'text') {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          decoration: InputDecoration(
            labelText: question.question,
            border: const OutlineInputBorder(),
          ),
          onChanged: (val) {
            _answers[index]['value'] = val;
            _answers[index]['option_level'] = null;
          },
        ),
      );
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              question.question,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          ...?question.options?.map((opt) => RadioListTile<String>(
                title: Text(opt.option),
                value: opt.option,
                groupValue: _answers[index]['value'] as String?,
                onChanged: (val) {
                  setState(() {
                    _answers[index]['value'] = val;
                    _answers[index]['option_level'] = opt.optionLevel;
                  });
                },
              )),
        ],
      ),
    );
  }

  Future<void> _submitAnswers() async {
    if (_form == null) return;
    final patientId = widget.preselectedPatientId ?? _selectedPatientId;
    if (patientId == null || patientId.isEmpty) {
      _showErrorSnackBar('Lütfen hasta seçin');
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final totalScore = _answers.fold<num>(0, (sum, a) {
        final lvl = a['option_level'];
        if (lvl is num) return sum + lvl;
        return sum;
      });
      final result = await _formAnswerService.sendFormAnswer(
        formId: _form!.id,
        patientId: patientId,
        formInfo: _form!,
        answers: _answers,
        totalScore: totalScore,
      );
      if (result['status'] == 'success') {
        _showSuccessSnackBar('Form yanıtı gönderildi');
      } else {
        _showErrorSnackBar(result['message'] ?? 'Form yanıtı gönderilemedi');
      }
    } catch (e) {
      _showErrorSnackBar('Form yanıtı gönderilirken hata oluştu: $e');
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: true,
      pinned: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      foregroundColor: Theme.of(context).colorScheme.onSurface,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          _form?.name ?? 'Form Detayları',
          style: const TextStyle(fontSize: 18),
        ),
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
      ),
      actions: [
        if (!_isEditing)
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  _toggleEditMode();
                  break;
                case 'copy':
                  _copyForm();
                  break;
                case 'delete':
                  _deleteForm();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: ListTile(
                  leading: Icon(Icons.edit, size: 20),
                  title: Text('Düzenle'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'copy',
                child: ListTile(
                  leading: Icon(Icons.copy, size: 20),
                  title: Text('Kopyala'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete, size: 20, color: Colors.red),
                  title: Text('Sil', style: TextStyle(color: Colors.red)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Form bulunamadı',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'İstediğiniz form mevcut değil veya erişim izniniz yok',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Geri Dön'),
          ),
        ],
      ),
    );
  }

  Widget _buildFormInfoCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.description,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Form Bilgileri',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (_isEditing) ...[
              _buildInlineEditableField(
                label: 'Form Adı',
                controller: _nameController,
                icon: Icons.title,
              ),
              const SizedBox(height: 16),
              _buildInlineEditableField(
                label: 'Açıklama',
                controller: _descriptionController,
                icon: Icons.info_outline,
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              _buildRepetitionTimeDropdown(),
              const SizedBox(height: 16),
              _buildFormTypeDropdown(),
            ] else ...[
              _buildInfoRow('Form Adı', _form!.name, Icons.title),
              const SizedBox(height: 12),
              _buildInfoRow('Açıklama', _form!.description, Icons.info_outline),
              const SizedBox(height: 12),
              _buildInfoRow(
                'Form Tipi',
                _form!.type == 'for patients'
                    ? 'Hastaya Gönder'
                    : 'Kendin Doldur',
                Icons.people,
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                'Tekrarlama Süresi',
                _form!.repeat == null || _form!.repeat == '-'
                    ? 'Tekrarlama Yok'
                    : _form!.repeat!,
                Icons.repeat,
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                'Oluşturulma',
                _form!.createdAt != null
                    ? _formatDate(_form!.createdAt!)
                    : 'Bilinmiyor',
                Icons.schedule,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionsCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.quiz,
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Sorular',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_form!.questions?.length ?? 0}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (_isEditing)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 16),
                child: OutlinedButton.icon(
                  onPressed: _addNewQuestion,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Yeni Soru Ekle'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            if (_form!.questions != null && _form!.questions!.isNotEmpty)
              ..._form!.questions!.asMap().entries.map((entry) {
                final index = entry.key;
                final question = entry.value;
                return _buildQuestionCard(index, question);
              })
            else
              _buildEmptyQuestionsState(),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientsCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.people,
                    color: Theme.of(context).colorScheme.onTertiaryContainer,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Hastalar',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.tertiary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_patients.length}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.tertiary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (_patients.isNotEmpty)
              ..._patients.map((patient) => _buildPatientTile(patient))
            else
              _buildEmptyPatientsState(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInlineEditableField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
          ),
        ),
      ],
    );
  }

  Widget _buildRepetitionTimeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tekrarlama Süresi',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedRepetitionTime,
          decoration: InputDecoration(
            prefixIcon: const Icon(
              Icons.repeat,
              size: 20,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
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
      ],
    );
  }

  Widget _buildFormTypeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Form Tipi',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedFormType,
          decoration: InputDecoration(
            prefixIcon: Icon(
              _selectedFormType == 'for patients' ? Icons.people : Icons.person,
              size: 20,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
          ),
          items: const [
            DropdownMenuItem(
              value: 'for patients',
              child: Text('Hastaya Gönder'),
            ),
            DropdownMenuItem(
              value: 'for me',
              child: Text('Kendin Doldur'),
            ),
          ],
          onChanged: (value) {
            setState(() {
              _selectedFormType = value!;
            });
          },
        ),
      ],
    );
  }

  Widget _buildQuestionCard(int index, Question question) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 0,
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _isEditing ? () => _editQuestion(index, question) : null,
          onLongPress: _isEditing ? () => _deleteQuestion(index) : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: question.type == 'text'
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.secondary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: question.type == 'text'
                                ? Theme.of(context).colorScheme.onPrimary
                                : Theme.of(context).colorScheme.onSecondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
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
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                question.type == 'text'
                                    ? Icons.text_fields
                                    : Icons.radio_button_checked,
                                size: 14,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                question.type == 'text'
                                    ? 'Metin'
                                    : 'Çoktan Seçmeli',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                              ),
                              if (question.options != null &&
                                  question.options!.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${question.options!.length} seçenek',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (_isEditing) ...[
                      IconButton(
                        icon: Icon(
                          Icons.edit,
                          color: Theme.of(context).colorScheme.primary,
                          size: 20,
                        ),
                        onPressed: () => _editQuestion(index, question),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.delete,
                          color: Theme.of(context).colorScheme.error,
                          size: 20,
                        ),
                        onPressed: () => _deleteQuestion(index),
                      ),
                    ],
                  ],
                ),
                if (question.options != null &&
                    question.options!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: question.options!.take(3).map((option) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          option.option,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList()
                      ..addAll(question.options!.length > 3
                          ? [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .outline
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  '+${question.options!.length - 3} daha',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              )
                            ]
                          : []),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyQuestionsState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color:
                  Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.quiz_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Henüz soru yok',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Bu formda henüz soru bulunmuyor.\nYeni sorular eklemek için düzenleme moduna geçin.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
          if (!_isEditing) ...[
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _toggleEditMode,
              icon: const Icon(Icons.edit, size: 18),
              label: const Text('Düzenleme Modu'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPatientTile(PatientModel patient) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Card(
        elevation: 0,
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _navigateToPatientDetail(patient),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primaryContainer,
                        Theme.of(context).colorScheme.secondaryContainer,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      patient.firstName[0] + patient.lastName[0],
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${patient.firstName} ${patient.lastName}',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.email,
                            size: 14,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              patient.email,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.phone,
                            size: 14,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            patient.primaryPhone,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (_completedForPatient.contains(patient.id))
                  const Chip(label: Text('Dolduruldu'))
                else
                  FilledButton(
                    onPressed: () async {
                      setState(() => _selectedPatientId = patient.id);
                      await _submitAnswers();
                      // başarılıysa durumu güncelle
                      final answers = await _formAnswerService.getAnswers(
                        patientId: patient.id,
                        formId: _form?.id,
                      );
                      if (mounted && answers.isNotEmpty) {
                        setState(() {
                          _completedForPatient.add(patient.id);
                        });
                      }
                    },
                    child: const Text('Formu Doldur'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyPatientsState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color:
                  Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.people_outline,
              size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Henüz hasta yok',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Bu dosyaya henüz hasta eklenmemiş.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _navigateToPatientDetail(PatientModel patient) {
    HapticFeedback.lightImpact();
    _showSuccessSnackBar(
        '${patient.firstName} ${patient.lastName} detayına gidiliyor...');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _fabAnimationController.dispose();
    _slideAnimationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

// Modern Bottom Sheet for Question Editing
class _QuestionEditBottomSheet extends StatefulWidget {
  final Question? question;
  final int questionIndex;

  const _QuestionEditBottomSheet({
    this.question,
    required this.questionIndex,
  });

  @override
  State<_QuestionEditBottomSheet> createState() =>
      _QuestionEditBottomSheetState();
}

class _QuestionEditBottomSheetState extends State<_QuestionEditBottomSheet> {
  final _questionController = TextEditingController();
  final _optionController = TextEditingController();
  String _selectedType = 'text';
  List<OptionModel> _options = [];

  @override
  void initState() {
    super.initState();
    if (widget.question != null) {
      _questionController.text = widget.question!.question;
      _selectedType = widget.question!.type;
      _options = List.from(widget.question!.options ?? []);
    }
  }

  @override
  void dispose() {
    _questionController.dispose();
    _optionController.dispose();
    super.dispose();
  }

  void _addOption() {
    if (_optionController.text.trim().isNotEmpty) {
      setState(() {
        _options.add(OptionModel(
          option: _optionController.text.trim(),
          optionLevel: 5,
        ));
        _optionController.clear();
      });
      HapticFeedback.lightImpact();
    }
  }

  void _removeOption(int index) {
    setState(() {
      _options.removeAt(index);
    });
    HapticFeedback.lightImpact();
  }

  void _updateOptionLevel(int index, int level) {
    setState(() {
      _options[index] = OptionModel(
        option: _options[index].option,
        optionLevel: level,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  widget.question != null ? 'Soruyu Düzenle' : 'Yeni Soru',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          const Divider(),
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Question Text
                  Text(
                    'Soru Metni',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _questionController,
                    decoration: InputDecoration(
                      hintText: 'Sorunuzu buraya yazın...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.help_outline),
                      filled: true,
                      fillColor: Theme.of(context)
                          .colorScheme
                          .surfaceVariant
                          .withOpacity(0.3),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),

                  // Question Type
                  Text(
                    'Soru Tipi',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Card(
                          elevation: 0,
                          color: _selectedType == 'text'
                              ? Theme.of(context).colorScheme.primaryContainer
                              : Theme.of(context)
                                  .colorScheme
                                  .surfaceVariant
                                  .withOpacity(0.3),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              setState(() {
                                _selectedType = 'text';
                                _options.clear();
                              });
                              HapticFeedback.selectionClick();
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.text_fields,
                                    color: _selectedType == 'text'
                                        ? Theme.of(context)
                                            .colorScheme
                                            .onPrimaryContainer
                                        : Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Metin',
                                    style: TextStyle(
                                      color: _selectedType == 'text'
                                          ? Theme.of(context)
                                              .colorScheme
                                              .onPrimaryContainer
                                          : Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Card(
                          elevation: 0,
                          color: _selectedType == 'multiple_choice'
                              ? Theme.of(context).colorScheme.primaryContainer
                              : Theme.of(context)
                                  .colorScheme
                                  .surfaceVariant
                                  .withOpacity(0.3),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              setState(() {
                                _selectedType = 'multiple_choice';
                              });
                              HapticFeedback.selectionClick();
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.radio_button_checked,
                                    color: _selectedType == 'multiple_choice'
                                        ? Theme.of(context)
                                            .colorScheme
                                            .onPrimaryContainer
                                        : Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Çoktan Seçmeli',
                                    style: TextStyle(
                                      color: _selectedType == 'multiple_choice'
                                          ? Theme.of(context)
                                              .colorScheme
                                              .onPrimaryContainer
                                          : Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Multiple Choice Options
                  if (_selectedType == 'multiple_choice') ...[
                    const SizedBox(height: 24),
                    Text(
                      'Seçenekler',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 12),

                    // Add Option
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _optionController,
                            decoration: InputDecoration(
                              hintText: 'Seçenek ekle...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: const Icon(Icons.add_circle_outline),
                              filled: true,
                              fillColor: Theme.of(context)
                                  .colorScheme
                                  .surfaceVariant
                                  .withOpacity(0.3),
                            ),
                            onFieldSubmitted: (_) => _addOption(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        FloatingActionButton.small(
                          onPressed: _addOption,
                          child: const Icon(Icons.add),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Options List
                    if (_options.isNotEmpty)
                      ...List.generate(_options.length, (index) {
                        final option = _options[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Card(
                            elevation: 0,
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceVariant
                                .withOpacity(0.3),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      option.option,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primaryContainer,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: DropdownButton<int>(
                                      value: option.optionLevel,
                                      underline: Container(),
                                      items: List.generate(10, (i) => i + 1)
                                          .map((level) => DropdownMenuItem(
                                                value: level,
                                                child: Text("$level"),
                                              ))
                                          .toList(),
                                      onChanged: (val) {
                                        if (val != null) {
                                          _updateOptionLevel(index, val);
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: Icon(
                                      Icons.delete_outline,
                                      color:
                                          Theme.of(context).colorScheme.error,
                                      size: 20,
                                    ),
                                    onPressed: () => _removeOption(index),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                  ],

                  const SizedBox(height: 100), // Space for FAB
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Extension method for FormModel
extension FormModelCopyWith on FormModel {
  FormModel copyWith({
    String? id,
    String? name,
    String? description,
    List<Question>? questions,
    String? type,
    String? fileId,
    int? level,
    DateTime? createdAt,
    String? repeat,
  }) {
    return FormModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      questions: questions ?? this.questions,
      type: type ?? this.type,
      fileId: fileId ?? this.fileId,
      level: level ?? this.level,
      createdAt: createdAt ?? this.createdAt,
      repeat: repeat ?? this.repeat,
    );
  }
}
