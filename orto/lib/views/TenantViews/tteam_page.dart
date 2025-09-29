import 'package:flutter/material.dart';
import 'package:ortopedi_ai/services/tenant_service.dart';
import 'package:ortopedi_ai/services/doctor_service.dart';
import 'package:ortopedi_ai/utils/api_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ortopedi_ai/views/TenantViews/tenant_doctor_stepper.dart';

class TTeamPage extends StatefulWidget {
  const TTeamPage({super.key});

  @override
  State<TTeamPage> createState() => _TTeamPageState();
}

class _TTeamPageState extends State<TTeamPage> {
  final _formKey = GlobalKey<FormState>();
  final _storage = const FlutterSecureStorage();
  late final DioClient _dioClient;
  late final TenantService _tenantService;
  late final DoctorService _doctorService;
  bool _isLoading = false;
  List<Map<String, dynamic>> _doctors = [];

  // Form controllers
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _emailController = TextEditingController();
  final _specializationController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _dioClient = DioClient(storage: _storage);
    _tenantService =
        TenantService(dioClient: _dioClient, secureStorage: _storage);
    _doctorService =
        DoctorService(dioClient: _dioClient, secureStorage: _storage);
    _loadDoctors();
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

  Future<void> _loadDoctors() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final doctors = await _tenantService.getAllDoctorsForTenant();
      setState(() {
        _doctors = doctors.map((doctor) {
          if (doctor is Map) {
            return Map<String, dynamic>.from(doctor);
          }
          return <String, dynamic>{};
        }).toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Doktorlar yüklenirken hata oluştu: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleAddDoctor() async {
    if (_formKey.currentState!.validate()) {
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

        print('Form verileri:');
        print('Ad: ${formData['name']}');
        print('Soyad: ${formData['surname']}');
        print('Email: ${formData['email']}');
        print('Uzmanlık: ${formData['specialization']}');
        print('Telefon: ${formData['phone_number']}');
        print('Şifre: ${formData['password']}');
        print('Şifre Tekrar: ${formData['password_confirmation']}');

        final response = await _doctorService.registerAdminDoctor(formData);

        print('API Yanıtı: $response');

        if (response['status'] == 'success') {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    Text(response['message'] ?? 'Doktor başarıyla eklendi'),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.all(16),
              ),
            );
            // Form alanlarını temizle
            _nameController.clear();
            _surnameController.clear();
            _emailController.clear();
            _specializationController.clear();
            _phoneNumberController.clear();
            _passwordController.clear();
            _passwordConfirmationController.clear();
            // Doktorları yeniden yükle
            await _loadDoctors();
            // Dialog'u kapat
            Navigator.pop(context);
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(response['error'] ?? 'Doktor eklenemedi'),
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
      } catch (e) {
        print('Hata: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text('Doktor eklenirken hata oluştu: ${e.toString()}')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  void _showAddDoctorDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TenantDoctorStepper(
          onDoctorAdded: () async {
            await _loadDoctors();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        automaticallyImplyLeading: false,
        title: const Text('Ekip Yönetimi'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _doctors.isEmpty
              ? const Center(
                  child: Text('Henüz doktor eklenmemiş'),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.8,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: _doctors.length,
                  itemBuilder: (context, index) {
                    final doctor = _doctors[index];
                    return Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircleAvatar(
                              radius: 40,
                              child: Icon(Icons.person, size: 40),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '${doctor['name']} ${doctor['surname']}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              doctor['specialization'] ??
                                  'Uzmanlık Alanı Belirtilmemiş',
                              style: const TextStyle(
                                color: Colors.grey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              doctor['email'] ?? '',
                              style: const TextStyle(
                                color: Colors.blue,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDoctorDialog,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Doktor Ekle'),
      ),
    );
  }
}
