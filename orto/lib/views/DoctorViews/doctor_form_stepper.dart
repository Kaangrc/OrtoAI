import 'package:flutter/material.dart';
import 'package:ortopedi_ai/services/doctor_service.dart';
import 'package:ortopedi_ai/utils/api_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DoctorFormStepper extends StatefulWidget {
  final VoidCallback onDoctorAdded;

  const DoctorFormStepper({
    Key? key,
    required this.onDoctorAdded,
  }) : super(key: key);

  @override
  State<DoctorFormStepper> createState() => _DoctorFormStepperState();
}

class _DoctorFormStepperState extends State<DoctorFormStepper> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;
  bool _isLoading = false;

  // Form controllers
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _emailController = TextEditingController();
  final _specializationController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmationController = TextEditingController();

  // Services
  late final DioClient _dioClient;
  late final DoctorService _doctorService;

  @override
  void initState() {
    super.initState();
    const storage = FlutterSecureStorage();
    _dioClient = DioClient(storage: storage);
    _doctorService =
        DoctorService(dioClient: _dioClient, secureStorage: storage);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _emailController.dispose();
    _specializationController.dispose();
    _phoneNumberController.dispose();
    _passwordController.dispose();
    _passwordConfirmationController.dispose();
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

    setState(() {
      _isLoading = true;
    });

    try {
      final formData = {
        'name': _nameController.text.trim(),
        'surname': _surnameController.text.trim(),
        'email': _emailController.text.trim(),
        'specialization': _specializationController.text.trim(),
        'phone_number': _phoneNumberController.text.trim(),
        'password': _passwordController.text,
        'password_confirmation': _passwordConfirmationController.text,
      };

      final response = await _doctorService.registerDoctor(formData);

      if (response['status'] == 'success') {
        if (mounted) {
          // Önce loading durumunu kapat
          setState(() {
            _isLoading = false;
          });

          // Başarı mesajını göster
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Doktor başarıyla eklendi'),
              backgroundColor: Theme.of(context).colorScheme.primary,
              behavior: SnackBarBehavior.floating,
            ),
          );

          // Doktor listesini güncelle
          widget.onDoctorAdded();

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
              content: Text(response['error'] ?? 'Doktor eklenemedi'),
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
            content: Text('Doktor eklenirken hata oluştu: ${e.toString()}'),
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
              'Doktor Bilgileri Özeti',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildSummaryRow('Ad Soyad',
                '${_nameController.text} ${_surnameController.text}'),
            _buildSummaryRow('E-posta', _emailController.text),
            _buildSummaryRow('Uzmanlık Alanı', _specializationController.text),
            _buildSummaryRow('Telefon', _phoneNumberController.text),
            _buildSummaryRow('Şifre', '••••••••'),
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
            width: 120,
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
            _surnameController.text.trim().isNotEmpty &&
            _emailController.text.trim().isNotEmpty;
      case 1:
        return _specializationController.text.trim().isNotEmpty &&
            _phoneNumberController.text.trim().isNotEmpty;
      case 2:
        return _passwordController.text.isNotEmpty &&
            _passwordConfirmationController.text.isNotEmpty &&
            _passwordController.text == _passwordConfirmationController.text;
      default:
        return false;
    }
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 0:
        return 'Kişisel Bilgiler';
      case 1:
        return 'Mesleki Bilgiler';
      case 2:
        return 'Güvenlik Bilgileri';
      default:
        return '';
    }
  }

  String _getStepSubtitle() {
    switch (_currentStep) {
      case 0:
        return 'Doktorun temel kişisel bilgilerini girin';
      case 1:
        return 'Uzmanlık alanı ve iletişim bilgilerini girin';
      case 2:
        return 'Giriş için gerekli şifre bilgilerini girin';
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
          controller: _surnameController,
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
      ],
    );
  }

  Widget _buildStep1Content() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _specializationController,
          decoration: const InputDecoration(
            labelText: 'Uzmanlık Alanı *',
            prefixIcon: Icon(Icons.medical_services),
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Lütfen uzmanlık alanını girin';
            }
            return null;
          },
          onChanged: (value) {
            setState(() {}); // UI'ı güncelle
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _phoneNumberController,
          decoration: const InputDecoration(
            labelText: 'Telefon Numarası *',
            prefixIcon: Icon(Icons.phone),
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Lütfen telefon numarasını girin';
            }
            if (!RegExp(r'^[0-9]{10,11}$').hasMatch(value)) {
              return 'Geçerli bir telefon numarası girin';
            }
            return null;
          },
          onChanged: (value) {
            setState(() {}); // UI'ı güncelle
          },
        ),
      ],
    );
  }

  Widget _buildStep2Content() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _passwordController,
          decoration: const InputDecoration(
            labelText: 'Şifre *',
            prefixIcon: Icon(Icons.lock),
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          obscureText: true,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Lütfen şifre girin';
            }
            if (value.length < 6) {
              return 'Şifre en az 6 karakter olmalıdır';
            }
            return null;
          },
          onChanged: (value) {
            setState(() {}); // UI'ı güncelle
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _passwordConfirmationController,
          decoration: const InputDecoration(
            labelText: 'Şifre Tekrar *',
            prefixIcon: Icon(Icons.lock),
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          obscureText: true,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Lütfen şifre tekrarını girin';
            }
            if (value != _passwordController.text) {
              return 'Şifreler eşleşmiyor';
            }
            return null;
          },
          onChanged: (value) {
            setState(() {}); // UI'ı güncelle
          },
        ),
        const SizedBox(height: 24),
        _buildSummaryCard(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yeni Doktor Ekle'),
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
                                  _currentStep == 2 ? 'Doktor Ekle' : 'İleri'),
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

