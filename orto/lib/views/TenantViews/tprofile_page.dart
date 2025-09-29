import 'package:flutter/material.dart';
import 'package:ortopedi_ai/services/tenant_service.dart';
import 'package:ortopedi_ai/utils/api_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TProfilePage extends StatefulWidget {
  const TProfilePage({super.key});

  @override
  State<TProfilePage> createState() => _TProfilePageState();
}

class _TProfilePageState extends State<TProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _storage = const FlutterSecureStorage();
  late final DioClient _dioClient;
  late final TenantService _tenantService;
  bool _isLoading = false;

  // Form controllers
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  String _selectedPlanType = 'basic';

  @override
  void initState() {
    super.initState();
    _dioClient = DioClient(storage: _storage);
    _tenantService =
        TenantService(dioClient: _dioClient, secureStorage: _storage);
    _loadTenantInfo();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadTenantInfo() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final tenantInfo = await _tenantService.getTenantInfo();
      if (tenantInfo != null) {
        _nameController.text = tenantInfo['name'] ?? '';
        _addressController.text = tenantInfo['address'] ?? '';
        _phoneController.text = tenantInfo['phone_number'] ?? '';
        _emailController.text = tenantInfo['email'] ?? '';
        _selectedPlanType = tenantInfo['plan_type'] ?? 'basic';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Bilgiler yüklenirken hata oluştu: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleUpdate() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final response = await _tenantService.updateTenant({
          'name': _nameController.text,
          'address': _addressController.text,
          'phone_number': _phoneController.text,
          'email': _emailController.text,
          'plan_type': _selectedPlanType,
        });

        if (response['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bilgileriniz başarıyla güncellendi')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(response['message'] ?? 'Güncelleme başarısız')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Güncelleme sırasında hata oluştu: ${e.toString()}')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Bilgileri'),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: colorScheme.primary),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Kurum Bilgileri',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                labelText: 'Kurum Adı',
                                prefixIcon: const Icon(Icons.business),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Lütfen kurum adını girin';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _addressController,
                              decoration: InputDecoration(
                                labelText: 'Adres',
                                prefixIcon: const Icon(Icons.location_on),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              maxLines: 2,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Lütfen adres girin';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _phoneController,
                              decoration: InputDecoration(
                                labelText: 'Telefon',
                                prefixIcon: const Icon(Icons.phone),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              keyboardType: TextInputType.phone,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Lütfen telefon numarası girin';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _emailController,
                              decoration: InputDecoration(
                                labelText: 'E-posta',
                                prefixIcon: const Icon(Icons.email),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Lütfen e-posta adresi girin';
                                }
                                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                    .hasMatch(value)) {
                                  return 'Geçerli bir e-posta adresi girin';
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
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              items: const [
                                DropdownMenuItem(
                                    value: 'basic', child: Text('Temel Plan')),
                                DropdownMenuItem(
                                    value: 'premium',
                                    child: Text('Premium Plan')),
                                DropdownMenuItem(
                                    value: 'enterprise',
                                    child: Text('Kurumsal Plan')),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedPlanType = value!;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _handleUpdate,
                        icon: const Icon(Icons.save),
                        label: _isLoading
                            ? const Text('Kaydediliyor...')
                            : const Text('Bilgileri Güncelle'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
