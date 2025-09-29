import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ortopedi_ai/models/file_model.dart';
import 'package:ortopedi_ai/services/patient_service.dart';
import 'package:ortopedi_ai/utils/api_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PatientFormStepper extends StatefulWidget {
  final List<FileModel> files;
  final VoidCallback onPatientAdded;

  const PatientFormStepper({
    Key? key,
    required this.files,
    required this.onPatientAdded,
  }) : super(key: key);

  @override
  State<PatientFormStepper> createState() => _PatientFormStepperState();
}

class _PatientFormStepperState extends State<PatientFormStepper> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;
  bool _isLoading = false;

  // Form controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _primaryPhoneController = TextEditingController();
  final _secondaryPhoneController = TextEditingController();

  // Form data
  DateTime? _selectedDate;
  String _selectedGender = 'Male';
  List<FileModel> _selectedFiles = [];

  // Services
  late final DioClient _dioClient;
  late final PatientService _patientService;

  @override
  void initState() {
    super.initState();
    const storage = FlutterSecureStorage();
    _dioClient = DioClient(storage: storage);
    _patientService =
        PatientService(dioClient: _dioClient, secureStorage: storage);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _primaryPhoneController.dispose();
    _secondaryPhoneController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ??
          DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      // Go to first step with errors
      setState(() {
        _currentStep = 0;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final patientData = {
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
        'primaryPhone': _primaryPhoneController.text.trim(),
        'secondaryPhone': _secondaryPhoneController.text.trim(),
        'dateOfBirth': _selectedDate?.toIso8601String(),
        'gender': _selectedGender,
        'fileIds': _selectedFiles.map((file) => file.id).toList(),
      };

      final response = await _patientService.addPatient(patientData);

      if (response['status'] == 'success') {
        if (mounted) {
          // Önce loading durumunu kapat
          setState(() {
            _isLoading = false;
          });

          // Başarı mesajını göster
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Hasta başarıyla eklendi'),
              backgroundColor: Theme.of(context).colorScheme.primary,
              behavior: SnackBarBehavior.floating,
            ),
          );

          // Hasta listesini güncelle
          widget.onPatientAdded();

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
              content: Text(response['message'] ?? 'Hasta eklenemedi'),
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
            content: Text('Hasta eklenirken hata oluştu: ${e.toString()}'),
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
              'Hasta Bilgileri Özeti',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildSummaryRow('Ad Soyad',
                '${_firstNameController.text} ${_lastNameController.text}'),
            _buildSummaryRow('E-posta', _emailController.text),
            _buildSummaryRow('Ana Telefon', _primaryPhoneController.text),
            if (_secondaryPhoneController.text.isNotEmpty)
              _buildSummaryRow(
                  'İkincil Telefon', _secondaryPhoneController.text),
            _buildSummaryRow(
              'Doğum Tarihi',
              _selectedDate != null
                  ? DateFormat('dd/MM/yyyy').format(_selectedDate!)
                  : 'Belirtilmemiş',
            ),
            _buildSummaryRow(
                'Cinsiyet', _selectedGender == 'Male' ? 'Erkek' : 'Kadın'),
            _buildSummaryRow(
                'Seçilen Dosyalar', '${_selectedFiles.length} dosya'),
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
        return _firstNameController.text.trim().isNotEmpty &&
            _lastNameController.text.trim().isNotEmpty &&
            _selectedDate != null;
      case 1:
        return _emailController.text.trim().isNotEmpty &&
            _primaryPhoneController.text.trim().isNotEmpty &&
            RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                .hasMatch(_emailController.text.trim());
      case 2:
        return true; // Özet ve dosya seçimi sayfası
      default:
        return false;
    }
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 0:
        return 'Kimlik Bilgileri';
      case 1:
        return 'İletişim Bilgileri';
      case 2:
        return 'Özet ve Dosyalar';
      default:
        return '';
    }
  }

  String _getStepSubtitle() {
    switch (_currentStep) {
      case 0:
        return 'Hastanın temel bilgilerini girin';
      case 1:
        return 'Telefon numaralarını girin';
      case 2:
        return 'Bilgileri kontrol edin ve dosya seçin';
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
          controller: _firstNameController,
          decoration: const InputDecoration(
            labelText: 'Ad *',
            prefixIcon: Icon(Icons.person),
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Lütfen adı girin';
            }
            return null;
          },
          onChanged: (value) {
            setState(() {}); // UI'ı güncelle
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _lastNameController,
          decoration: const InputDecoration(
            labelText: 'Soyad *',
            prefixIcon: Icon(Icons.person),
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Lütfen soyadı girin';
            }
            return null;
          },
          onChanged: (value) {
            setState(() {}); // UI'ı güncelle
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          readOnly: true,
          decoration: const InputDecoration(
            labelText: 'Doğum Tarihi *',
            prefixIcon: Icon(Icons.calendar_today),
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            suffixIcon: Icon(Icons.arrow_forward_ios),
          ),
          controller: TextEditingController(
            text: _selectedDate == null
                ? ''
                : DateFormat('dd/MM/yyyy').format(_selectedDate!),
          ),
          onTap: () => _selectDate(context),
        ),
        if (_selectedDate == null)
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 4),
            child: Text(
              'Lütfen doğum tarihini seçin',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            ),
          ),
        const SizedBox(height: 24),
        const Text(
          'Cinsiyet *',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: RadioListTile<String>(
                title: const Text('Erkek'),
                value: 'Male',
                groupValue: _selectedGender,
                onChanged: (value) {
                  setState(() {
                    _selectedGender = value!;
                  });
                },
              ),
            ),
            Expanded(
              child: RadioListTile<String>(
                title: const Text('Kadın'),
                value: 'Female',
                groupValue: _selectedGender,
                onChanged: (value) {
                  setState(() {
                    _selectedGender = value!;
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStep1Content() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _emailController,
          decoration: const InputDecoration(
            labelText: 'E-posta *',
            prefixIcon: Icon(Icons.email),
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Lütfen e-posta adresini girin';
            }
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
              return 'Geçerli bir e-posta adresi girin';
            }
            return null;
          },
          onChanged: (value) {
            setState(() {}); // UI'ı güncelle
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _primaryPhoneController,
          decoration: const InputDecoration(
            labelText: 'Ana Telefon *',
            prefixIcon: Icon(Icons.phone),
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Lütfen telefon numarasını girin';
            }
            return null;
          },
          onChanged: (value) {
            setState(() {}); // UI'ı güncelle
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _secondaryPhoneController,
          decoration: const InputDecoration(
            labelText: 'İkincil Telefon (Opsiyonel)',
            prefixIcon: Icon(Icons.phone),
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          keyboardType: TextInputType.phone,
        ),
      ],
    );
  }

  Widget _buildStep2Content() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSummaryCard(),
        const SizedBox(height: 24),
        const Text(
          'İlgili Dosyalar (Opsiyonel)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        if (widget.files.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Text('Henüz dosya eklenmemiş'),
              ),
            ),
          )
        else
          Card(
            child: Column(
              children: widget.files.map((file) {
                final isSelected = _selectedFiles.contains(file);
                return CheckboxListTile(
                  title: Text(file.name),
                  subtitle: file.forms != null && file.forms!.isNotEmpty
                      ? Text(
                          '${file.forms!.length} form',
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.7),
                          ),
                        )
                      : null,
                  value: isSelected,
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        _selectedFiles.add(file);
                      } else {
                        _selectedFiles.remove(file);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ),
        if (_selectedFiles.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text(
            'Seçilen Dosyalar:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          ..._selectedFiles.map((file) => Card(
                margin: const EdgeInsets.only(bottom: 4),
                child: ListTile(
                  leading: const Icon(Icons.folder),
                  title: Text(file.name),
                  trailing: IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: () {
                      setState(() {
                        _selectedFiles.remove(file);
                      });
                    },
                  ),
                ),
              )),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yeni Hasta Ekle'),
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
                              : Text(_currentStep == 2 ? 'Kaydet' : 'İleri'),
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
