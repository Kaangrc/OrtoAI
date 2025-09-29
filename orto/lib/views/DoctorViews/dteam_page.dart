import 'package:flutter/material.dart';
import 'package:ortopedi_ai/services/doctor_service.dart';
import 'package:ortopedi_ai/utils/api_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ortopedi_ai/views/DoctorViews/doctor_form_stepper.dart';

class DTeamPage extends StatefulWidget {
  const DTeamPage({super.key});

  @override
  State<DTeamPage> createState() => _DTeamPageState();
}

class _DTeamPageState extends State<DTeamPage> {
  final _storage = const FlutterSecureStorage();
  late final DioClient _dioClient;
  late final DoctorService _doctorService;
  bool _isLoading = false;
  List<Map<String, dynamic>> _doctors = [];

  @override
  void initState() {
    super.initState();
    _dioClient = DioClient(storage: _storage);
    _doctorService =
        DoctorService(dioClient: _dioClient, secureStorage: _storage);
    _loadDoctors();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadDoctors() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final doctors = await _doctorService.getAllDoctors();
      setState(() {
        _doctors = doctors;
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

  void _showAddDoctorDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DoctorFormStepper(
          onDoctorAdded: () {
            _loadDoctors();
            // Navigator.pop çağrısı DoctorFormStepper'da yapılıyor
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDoctorDialog,
        child: const Icon(Icons.add),
        tooltip: 'Doktor Ekle',
        heroTag: "add_doctor_fab",
      ),
    );
  }
}
