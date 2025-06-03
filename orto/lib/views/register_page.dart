import 'package:flutter/material.dart';
import 'package:ortopedi_ai/utils/api_client.dart';
import '../services/tenant_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  // DioClient ve storage tanımlamaları
  final _storage = const FlutterSecureStorage();
  late final DioClient _dioClient;

  // Controllers
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _selectedPlanType = 'Basic';
  bool _showPassword = false;
  bool _showPasswordConfirm = false;
  int _activeStep = 0;

  // Steps from React component
  final List<String> _steps = [
    "Kurum Bilgileri",
    "İletişim Bilgileri",
    "Hesap Bilgileri"
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
    _dioClient = DioClient(storage: _storage);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _validateCurrentStep() {
    switch (_activeStep) {
      case 0:
        return _nameController.text.isNotEmpty &&
            _addressController.text.isNotEmpty;
      case 1:
        return _phoneController.text.length >= 10 &&
            _emailController.text.contains('@');
      case 2:
        return _passwordController.text.length >= 6 &&
            _passwordController.text == _confirmPasswordController.text;
      default:
        return false;
    }
  }

  void _handleNext() {
    if (_validateCurrentStep()) {
      if (_activeStep < _steps.length - 1) {
        setState(() {
          _activeStep++;
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Lütfen tüm alanları doldurun'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  void _handleBack() {
    if (_activeStep > 0) {
      setState(() {
        _activeStep--;
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (_activeStep != _steps.length - 1) {
      _handleNext();
      return;
    }

    if (_validateCurrentStep()) {
      try {
        final response =
            await TenantService(dioClient: _dioClient, secureStorage: _storage)
                .registerTenant({
          'name': _nameController.text,
          'address': _addressController.text,
          'phone_number': _phoneController.text,
          'email': _emailController.text,
          'plan_type': _selectedPlanType.toLowerCase(),
          'password': _passwordController.text,
          'password_confirmation': _confirmPasswordController.text,
        });

        if (!mounted) return;

        if (response['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                  'Kayıt başarılı! Giriş sayfasına yönlendiriliyorsunuz...'),
              backgroundColor: Theme.of(context).colorScheme.primary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );

          Future.delayed(const Duration(seconds: 1), () {
            Navigator.pushReplacementNamed(context, '/login');
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Kayıt başarısız'),
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
            content: const Text('Kayıt sırasında bir hata oluştu'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  Widget _buildStepContent() {
    switch (_activeStep) {
      case 0:
        return _buildCompanyInfoStep();
      case 1:
        return _buildContactInfoStep();
      case 2:
        return _buildAccountInfoStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildCompanyInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAnimatedContainer([
          Text(
            'Kurum Adı',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              hintText: 'Kurum Adı',
              prefixIcon: Icon(
                Icons.business,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Adres',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _addressController,
            decoration: InputDecoration(
              hintText: 'Adres',
              prefixIcon: Icon(
                Icons.location_on,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            maxLines: 2,
          ),
        ]),
      ],
    );
  }

  Widget _buildContactInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAnimatedContainer([
          Text(
            'Telefon Numarası',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _phoneController,
            decoration: InputDecoration(
              hintText: '5XX XXX XX XX',
              prefixIcon: Icon(
                Icons.phone,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 24),
          Text(
            'E-posta',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(
              hintText: 'ornek@sirket.com',
              prefixIcon: Icon(
                Icons.email,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
        ]),
      ],
    );
  }

  Widget _buildAccountInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAnimatedContainer([
          Text(
            'Şifre',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _passwordController,
            obscureText: !_showPassword,
            decoration: InputDecoration(
              hintText: 'Şifre',
              prefixIcon: Icon(
                Icons.lock,
                color: Theme.of(context).colorScheme.primary,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _showPassword ? Icons.visibility_off : Icons.visibility,
                  color: Theme.of(context).colorScheme.primary,
                ),
                onPressed: () {
                  setState(() {
                    _showPassword = !_showPassword;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Şifre Tekrar',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: !_showPasswordConfirm,
            decoration: InputDecoration(
              hintText: 'Şifre Tekrar',
              prefixIcon: Icon(
                Icons.lock_outline,
                color: Theme.of(context).colorScheme.primary,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _showPasswordConfirm
                      ? Icons.visibility_off
                      : Icons.visibility,
                  color: Theme.of(context).colorScheme.primary,
                ),
                onPressed: () {
                  setState(() {
                    _showPasswordConfirm = !_showPasswordConfirm;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Plan Tipi',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedPlanType,
                isExpanded: true,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                borderRadius: BorderRadius.circular(12),
                items: ['Basic', 'Premium', 'Enterprise'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedPlanType = newValue;
                    });
                  }
                },
              ),
            ),
          ),
        ]),
      ],
    );
  }

  Widget _buildAnimatedContainer(List<Widget> children) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kayıt Ol'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                Stepper(
                  currentStep: _activeStep,
                  onStepContinue: _handleNext,
                  onStepCancel: _handleBack,
                  controlsBuilder: (context, details) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Row(
                        children: [
                          if (_activeStep > 0)
                            Expanded(
                              child: OutlinedButton(
                                onPressed: details.onStepCancel,
                                style: OutlinedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  textStyle: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                child: const Text('Geri'),
                              ),
                            ),
                          if (_activeStep > 0) const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: details.onStepContinue,
                              style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                textStyle: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              child: Text(
                                _activeStep == _steps.length - 1
                                    ? 'Kayıt Ol'
                                    : 'İleri',
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  steps: List.generate(
                    _steps.length,
                    (index) => Step(
                      title: Text(
                        _steps[index],
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      content: _buildStepContent(),
                      isActive: _activeStep >= index,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
