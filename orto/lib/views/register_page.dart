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

  void _handleNext() {
    if (_activeStep < _steps.length - 1) {
      setState(() {
        _activeStep++;
      });
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

    if (_formKey.currentState!.validate()) {
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
              backgroundColor: Colors.teal,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );

          Future.delayed(const Duration(seconds: 1), () {
            Navigator.pushReplacementNamed(context, '/login');
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['message'] ?? 'Kayıt başarısız')),
          );
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kayıt sırasında bir hata oluştu')),
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
          const Text('Kurum Adı', style: TextStyle(fontSize: 14)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              hintText: 'Kurum Adı',
              prefixIcon: const Icon(Icons.business),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.teal.shade300),
              ),
            ),
            validator: (value) =>
                value?.isEmpty ?? true ? 'Kurum adı gerekli' : null,
          ),
          const SizedBox(height: 24),
          const Text('Adres', style: TextStyle(fontSize: 14)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _addressController,
            decoration: InputDecoration(
              hintText: 'Adres',
              prefixIcon: const Icon(Icons.location_on),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.teal.shade300),
              ),
            ),
            maxLines: 2,
            validator: (value) =>
                value?.isEmpty ?? true ? 'Adres gerekli' : null,
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
          const Text('Telefon Numarası', style: TextStyle(fontSize: 14)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _phoneController,
            decoration: InputDecoration(
              hintText: '5XX XXX XX XX',
              prefixIcon: const Icon(Icons.phone),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.teal.shade300),
              ),
            ),
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value?.isEmpty ?? true) return 'Telefon gerekli';
              if (value!.length < 10)
                return 'Geçerli bir telefon numarası giriniz';
              return null;
            },
          ),
          const SizedBox(height: 24),
          const Text('E-posta', style: TextStyle(fontSize: 14)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(
              hintText: 'ornek@sirket.com',
              prefixIcon: const Icon(Icons.email),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.teal.shade300),
              ),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value?.isEmpty ?? true) return 'E-posta gerekli';
              if (!value!.contains('@')) return 'Geçerli bir e-posta giriniz';
              return null;
            },
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
          const Text('Şifre', style: TextStyle(fontSize: 14)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _passwordController,
            decoration: InputDecoration(
              hintText: '********',
              prefixIcon: const Icon(Icons.lock),
              suffixIcon: IconButton(
                icon: Icon(
                    _showPassword ? Icons.visibility_off : Icons.visibility),
                onPressed: () {
                  setState(() {
                    _showPassword = !_showPassword;
                  });
                },
              ),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.teal.shade300),
              ),
            ),
            obscureText: !_showPassword,
            validator: (value) {
              if (value?.isEmpty ?? true) return 'Şifre gerekli';
              if (value!.length < 6) return 'Şifre en az 6 karakter olmalı';
              return null;
            },
          ),
          const SizedBox(height: 24),
          const Text('Şifre Tekrar', style: TextStyle(fontSize: 14)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _confirmPasswordController,
            decoration: InputDecoration(
              hintText: '********',
              prefixIcon: const Icon(Icons.lock),
              suffixIcon: IconButton(
                icon: Icon(_showPasswordConfirm
                    ? Icons.visibility_off
                    : Icons.visibility),
                onPressed: () {
                  setState(() {
                    _showPasswordConfirm = !_showPasswordConfirm;
                  });
                },
              ),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.teal.shade300),
              ),
            ),
            obscureText: !_showPasswordConfirm,
            validator: (value) {
              if (value != _passwordController.text) {
                return 'Şifreler eşleşmiyor';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedPlanType,
            decoration: InputDecoration(
              labelText: 'Plan Tipi',
              prefixIcon: const Icon(Icons.card_membership),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.teal.shade300),
              ),
            ),
            items: const [
              DropdownMenuItem(value: 'Basic', child: Text('Temel Plan')),
              DropdownMenuItem(value: 'Premium', child: Text('Premium Plan')),
              DropdownMenuItem(
                  value: 'Enterprise', child: Text('Kurumsal Plan')),
            ],
            onChanged: (value) {
              setState(() {
                _selectedPlanType = value!;
              });
            },
          ),
        ]),
      ],
    );
  }

  Widget _buildAnimatedContainer(List<Widget> children) {
    return AnimatedOpacity(
      opacity: 1.0,
      duration: const Duration(milliseconds: 500),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.teal.shade700,
              Colors.teal.shade500,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          Card(
                            elevation: 8,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Gradient Title
                                  ShaderMask(
                                    shaderCallback: (Rect bounds) {
                                      return LinearGradient(
                                        colors: [
                                          Colors.teal.shade500,
                                          Colors.blue.shade400,
                                        ],
                                      ).createShader(bounds);
                                    },
                                    child: const Text(
                                      'Kurumsal Kayıt',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  // Stepper
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(
                                      _steps.length,
                                      (index) => Expanded(
                                        child: Column(
                                          children: [
                                            CircleAvatar(
                                              radius: 16,
                                              backgroundColor:
                                                  _activeStep >= index
                                                      ? Colors.teal.shade500
                                                      : Colors.grey.shade300,
                                              child: _activeStep > index
                                                  ? const Icon(Icons.check,
                                                      color: Colors.white,
                                                      size: 16)
                                                  : Text(
                                                      '${index + 1}',
                                                      style: TextStyle(
                                                        color:
                                                            _activeStep >= index
                                                                ? Colors.white
                                                                : Colors.grey
                                                                    .shade700,
                                                      ),
                                                    ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              _steps[index],
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: _activeStep >= index
                                                    ? Colors.teal.shade500
                                                    : Colors.grey.shade600,
                                                fontWeight: _activeStep == index
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                              ),
                                            ),
                                            if (index < _steps.length - 1)
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 8),
                                                child: Container(
                                                  height: 1,
                                                  color: _activeStep > index
                                                      ? Colors.teal.shade500
                                                      : Colors.grey.shade300,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  // Step Content
                                  _buildStepContent(),

                                  // Buttons
                                  Padding(
                                    padding: const EdgeInsets.only(top: 24),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        OutlinedButton(
                                          onPressed: _activeStep == 0
                                              ? null
                                              : _handleBack,
                                          style: OutlinedButton.styleFrom(
                                            side: BorderSide(
                                                color: Colors.teal.shade500),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                          child: const Text('Geri'),
                                        ),
                                        ElevatedButton(
                                          onPressed: _handleSubmit,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                Colors.teal.shade500,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                          child: Text(
                                              _activeStep == _steps.length - 1
                                                  ? 'Kaydı Tamamla'
                                                  : 'İleri'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () => Navigator.pushReplacementNamed(
                                context, '/login'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Zaten üye misin? Giriş Yap'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
