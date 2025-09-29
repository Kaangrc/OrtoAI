import 'package:flutter/material.dart';
import 'package:ortopedi_ai/models/patientmodel.dart';
import 'package:ortopedi_ai/models/file_model.dart';
import 'package:ortopedi_ai/services/patient_service.dart';
import 'package:ortopedi_ai/services/file_service.dart';
import 'package:ortopedi_ai/utils/api_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ortopedi_ai/views/DoctorViews/dpatient_detail_page.dart';
import 'package:ortopedi_ai/views/DoctorViews/patient_form_stepper.dart';

class DPatientPage extends StatefulWidget {
  const DPatientPage({super.key});

  @override
  State<DPatientPage> createState() => _DPatientPageState();
}

class _DPatientPageState extends State<DPatientPage> {
  final _scaffoldKey = GlobalKey<ScaffoldMessengerState>();
  final _storage = const FlutterSecureStorage();
  late final PatientService _patientService;
  late final FileService _fileService;
  bool _isLoading = true;
  List<PatientModel> _patients = [];
  List<PatientModel> _filteredPatients = [];
  List<FileModel> _files = [];
  String _searchQuery = '';
  String _filterGender = 'Tümü';
  RangeValues _ageRange = const RangeValues(0, 100);
  FileModel? _selectedFilterFile;

  @override
  void initState() {
    super.initState();
    _patientService = PatientService(
      dioClient: DioClient(storage: _storage),
    );
    _fileService = FileService(
      dioClient: DioClient(storage: _storage),
    );
    _loadPatients();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    try {
      final files = await _fileService.getAllFiles();
      setState(() {
        _files = files;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Dosyalar yüklenirken hata oluştu: $e')),
        );
      }
    }
  }

  Future<void> _loadPatients() async {
    try {
      final patients = await _patientService.getAllPatients();
      setState(() {
        _patients = patients;
        _filteredPatients = patients;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hastalar yüklenirken hata oluştu: $e')),
        );
      }
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredPatients = _patients.where((patient) {
        // İsim araması
        final fullName =
            '${patient.firstName} ${patient.lastName}'.toLowerCase();
        final matchesSearch = _searchQuery.isEmpty ||
            fullName.contains(_searchQuery.toLowerCase());

        // Cinsiyet filtresi
        final matchesGender =
            _filterGender == 'Tümü' || patient.gender == _filterGender;

        // Yaş filtresi
        final age =
            DateTime.now().difference(patient.dateOfBirth).inDays ~/ 365;
        final matchesAge = age >= _ageRange.start && age <= _ageRange.end;

        // Dosya filtresi
        final matchesFile = _selectedFilterFile == null ||
            (patient.fileIds?.contains(_selectedFilterFile!.id) ?? false);

        return matchesSearch && matchesGender && matchesAge && matchesFile;
      }).toList();
    });
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Filtreleme Seçenekleri'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Cinsiyet:'),
                RadioListTile<String>(
                  title: const Text('Tümü'),
                  value: 'Tümü',
                  groupValue: _filterGender,
                  onChanged: (value) {
                    setState(() {
                      _filterGender = value!;
                    });
                  },
                ),
                RadioListTile<String>(
                  title: const Text('Erkek'),
                  value: 'Male',
                  groupValue: _filterGender,
                  onChanged: (value) {
                    setState(() {
                      _filterGender = value!;
                    });
                  },
                ),
                RadioListTile<String>(
                  title: const Text('Kadın'),
                  value: 'Female',
                  groupValue: _filterGender,
                  onChanged: (value) {
                    setState(() {
                      _filterGender = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                const Text('Yaş Aralığı:'),
                RangeSlider(
                  values: _ageRange,
                  min: 0,
                  max: 100,
                  divisions: 100,
                  labels: RangeLabels(
                    '${_ageRange.start.round()} yaş',
                    '${_ageRange.end.round()} yaş',
                  ),
                  onChanged: (values) {
                    setState(() {
                      _ageRange = values;
                    });
                  },
                ),
                const SizedBox(height: 16),
                const Text('Dosya:'),
                DropdownButtonFormField<FileModel>(
                  decoration: const InputDecoration(
                    labelText: 'Dosya Seçin',
                    prefixIcon: Icon(Icons.folder),
                  ),
                  value: _selectedFilterFile,
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Tümü'),
                    ),
                    ..._files.map((file) {
                      return DropdownMenuItem(
                        value: file,
                        child: Text(
                          file.name,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      );
                    }).toList(),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedFilterFile = value;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _filterGender = 'Tümü';
                  _ageRange = const RangeValues(0, 100);
                  _selectedFilterFile = null;
                });
              },
              child: const Text('Filtreleri Temizle'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _applyFilters();
              },
              child: const Text('Uygula'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddPatientDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PatientFormStepper(
          files: _files,
          onPatientAdded: () {
            _loadPatients();
            // Navigator.pop çağrısı PatientFormStepper'da yapılıyor
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: _scaffoldKey,
      child: Scaffold(
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Hasta Ara...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                          _applyFilters();
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.filter_list),
                    onPressed: _showFilterDialog,
                    tooltip: 'Filtrele',
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredPatients.isEmpty
                      ? const Center(
                          child: Text('Henüz hasta eklenmemiş'),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredPatients.length,
                          itemBuilder: (context, index) {
                            final patient = _filteredPatients[index];
                            return Card(
                              elevation: 4,
                              margin: const EdgeInsets.only(bottom: 16),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor:
                                      Theme.of(context).colorScheme.primary,
                                  child: Text(
                                    '${patient.firstName[0]}${patient.lastName[0]}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  '${patient.firstName} ${patient.lastName}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(patient.email),
                                    Text(patient.primaryPhone),
                                  ],
                                ),
                                trailing: PopupMenuButton<String>(
                                  onSelected: (value) async {
                                    if (value == 'delete') {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Hastayı Sil'),
                                          content: Text(
                                              '${patient.firstName} ${patient.lastName} adlı hastayı silmek istediğinizden emin misiniz?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, false),
                                              child: const Text('İptal'),
                                            ),
                                            ElevatedButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, true),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    Theme.of(context)
                                                        .colorScheme
                                                        .error,
                                                foregroundColor:
                                                    Theme.of(context)
                                                        .colorScheme
                                                        .onError,
                                              ),
                                              child: const Text('Sil'),
                                            ),
                                          ],
                                        ),
                                      );

                                      if (confirm == true) {
                                        setState(() {
                                          _isLoading = true;
                                        });

                                        try {
                                          final response = await _patientService
                                              .deletePatient(patient.id);

                                          if (response['status'] == 'success') {
                                            if (mounted) {
                                              _scaffoldKey.currentState
                                                  ?.showSnackBar(
                                                SnackBar(
                                                  content: const Text(
                                                      'Hasta başarıyla silindi'),
                                                  backgroundColor:
                                                      Theme.of(context)
                                                          .colorScheme
                                                          .primary,
                                                ),
                                              );
                                              _loadPatients();
                                            }
                                          } else {
                                            if (mounted) {
                                              _scaffoldKey.currentState
                                                  ?.showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                      response['message'] ??
                                                          'Hasta silinemedi'),
                                                ),
                                              );
                                            }
                                          }
                                        } catch (e) {
                                          if (mounted) {
                                            _scaffoldKey.currentState
                                                ?.showSnackBar(
                                              SnackBar(
                                                  content: Text(
                                                      'Hasta silinirken hata oluştu: ${e.toString()}')),
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
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete, color: Colors.red),
                                          SizedBox(width: 8),
                                          Text('Sil',
                                              style:
                                                  TextStyle(color: Colors.red)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => PatientDetailPage(
                                        patient: patient,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showAddPatientDialog,
          child: const Icon(Icons.add),
          tooltip: 'Hasta Ekle',
          heroTag: "add_patient_fab",
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
