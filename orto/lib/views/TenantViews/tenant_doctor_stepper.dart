import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ortopedi_ai/services/doctor_service.dart';
import 'package:ortopedi_ai/utils/api_client.dart';

class TenantDoctorStepper extends StatefulWidget {
  final VoidCallback onDoctorAdded;

  const TenantDoctorStepper({Key? key, required this.onDoctorAdded})
      : super(key: key);

  @override
  State<TenantDoctorStepper> createState() => _TenantDoctorStepperState();
}

class _TenantDoctorStepperState extends State<TenantDoctorStepper> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;
  bool _isLoading = false;

  // Controllers
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _emailController = TextEditingController();
  final _specializationController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmationController = TextEditingController();

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

  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return _nameController.text.trim().isNotEmpty &&
            _surnameController.text.trim().isNotEmpty &&
            _specializationController.text.trim().isNotEmpty;
      case 1:
        final email = _emailController.text.trim();
        final phoneRaw = _phoneNumberController.text.trim();
        final phoneDigits = phoneRaw.replaceAll(RegExp(r'\D'), '');
        final isEmailValid =
            RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
        final isPhoneValid = phoneDigits.startsWith('90')
            ? phoneDigits.length == 12
            : (phoneDigits.length == 10 || phoneDigits.length == 11);
        return email.isNotEmpty && isEmailValid && isPhoneValid;
      case 2:
        return _passwordController.text.length >= 6 &&
            _passwordController.text == _passwordConfirmationController.text;
      default:
        return false;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
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

      final response = await _doctorService.registerAdminDoctor(formData);

      if (response['status'] == 'success') {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Doktor başarıyla eklendi'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
        widget.onDoctorAdded();
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted) Navigator.pop(context);
        });
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Doktor eklenemedi'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Doktor eklenirken hata oluştu: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildStep0() {
    return Column(
      children: [
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Ad',
            prefixIcon: Icon(Icons.person),
          ),
          validator: (v) => v == null || v.isEmpty ? 'Lütfen adı girin' : null,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _surnameController,
          decoration: const InputDecoration(
            labelText: 'Soyad',
            prefixIcon: Icon(Icons.person_outline),
          ),
          validator: (v) =>
              v == null || v.isEmpty ? 'Lütfen soyadı girin' : null,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _specializationController,
          decoration: const InputDecoration(
            labelText: 'Uzmanlık Alanı',
            prefixIcon: Icon(Icons.medical_services),
          ),
          validator: (v) =>
              v == null || v.isEmpty ? 'Lütfen uzmanlığı girin' : null,
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  Widget _buildStep1() {
    return Column(
      children: [
        TextFormField(
          controller: _emailController,
          decoration: const InputDecoration(
            labelText: 'E-posta',
            prefixIcon: Icon(Icons.email),
          ),
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.isEmpty) return 'Lütfen e-posta girin';
            if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) {
              return 'Geçerli bir e-posta girin';
            }
            return null;
          },
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _phoneNumberController,
          decoration: const InputDecoration(
            labelText: 'Telefon Numarası',
            prefixIcon: Icon(Icons.phone),
          ),
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.isEmpty) return 'Telefon girin';
            final digits = value.replaceAll(RegExp(r'\D'), '');
            final ok = digits.startsWith('90')
                ? digits.length == 12
                : (digits.length == 10 || digits.length == 11);
            if (!ok) return 'Geçerli telefon girin';
            return null;
          },
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      children: [
        TextFormField(
          controller: _passwordController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Şifre',
            prefixIcon: Icon(Icons.lock),
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Şifre girin';
            if (v.length < 6) return 'En az 6 karakter';
            return null;
          },
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _passwordConfirmationController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Şifre Tekrar',
            prefixIcon: Icon(Icons.lock_outline),
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Şifre tekrarını girin';
            if (v != _passwordController.text) return 'Şifreler eşleşmiyor';
            return null;
          },
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final canProceed = _canProceed();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yeni Doktor Ekle'),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
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
                  children: [
                    if (_currentStep == 0) _buildStep0(),
                    if (_currentStep == 1) _buildStep1(),
                    if (_currentStep == 2) _buildStep2(),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton(
                    onPressed: _currentStep == 0
                        ? () => Navigator.pop(context)
                        : () => setState(() => _currentStep -= 1),
                    child: Text(_currentStep == 0 ? 'İptal' : 'Geri'),
                  ),
                  ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : (canProceed
                            ? () {
                                if (_currentStep < 2) {
                                  setState(() => _currentStep += 1);
                                } else {
                                  _submit();
                                }
                              }
                            : null),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_currentStep == 2 ? 'Kaydet' : 'İleri'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
