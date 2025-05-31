import 'package:flutter/material.dart';
import 'package:ortopedi_ai/models/patientmodel.dart';
import 'package:ortopedi_ai/models/file_model.dart';
import 'package:ortopedi_ai/services/patient_service.dart';
import 'package:ortopedi_ai/services/file_service.dart';
import 'package:ortopedi_ai/utils/api_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:ortopedi_ai/views/DoctorViews/dpatient_detail_page.dart';

class DPatientPage extends StatefulWidget {
  const DPatientPage({super.key});

  @override
  State<DPatientPage> createState() => _DPatientPageState();
}

class _DPatientPageState extends State<DPatientPage> {
  final _formKey = GlobalKey<FormState>();
  final _scaffoldKey = GlobalKey<ScaffoldMessengerState>();
  final _storage = const FlutterSecureStorage();
  late final PatientService _patientService;
  late final FileService _fileService;
  bool _isLoading = true;
  List<PatientModel> _patients = [];
  List<PatientModel> _filteredPatients = [];
  List<FileModel> _files = [];
  List<FileModel> _selectedFiles = [];
  String _searchQuery = '';
  String _filterGender = 'Tümü';
  RangeValues _ageRange = const RangeValues(0, 100);
  FileModel? _selectedFilterFile;

  // Form controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _primaryPhoneController = TextEditingController();
  final _secondaryPhoneController = TextEditingController();
  DateTime? _selectedDate;
  String _selectedGender = 'Male';

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

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
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
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Tümü'),
                    ),
                    ..._files.map((file) {
                      return DropdownMenuItem(
                        value: file,
                        child: Text(file.name),
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
    _firstNameController.clear();
    _lastNameController.clear();
    _emailController.clear();
    _primaryPhoneController.clear();
    _secondaryPhoneController.clear();
    _selectedDate = null;
    _selectedGender = 'Male';
    _selectedFiles = [];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Yeni Hasta Ekle'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _firstNameController,
                    decoration: const InputDecoration(
                      labelText: 'Ad',
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Lütfen adı girin';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _lastNameController,
                    decoration: const InputDecoration(
                      labelText: 'Soyad',
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Lütfen soyadı girin';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'E-posta',
                      prefixIcon: Icon(Icons.email),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Lütfen e-posta adresini girin';
                      }
                      if (!value.contains('@')) {
                        return 'Geçerli bir e-posta adresi girin';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _primaryPhoneController,
                    decoration: const InputDecoration(
                      labelText: 'Telefon',
                      prefixIcon: Icon(Icons.phone),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Lütfen telefon numarasını girin';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _secondaryPhoneController,
                    decoration: const InputDecoration(
                      labelText: 'İkincil Telefon (Opsiyonel)',
                      prefixIcon: Icon(Icons.phone),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: Text(_selectedDate == null
                        ? 'Doğum Tarihi Seçin'
                        : 'Doğum Tarihi: ${DateFormat('dd/MM/yyyy').format(_selectedDate!)}'),
                    leading: const Icon(Icons.calendar_today),
                    onTap: () => _selectDate(context),
                  ),
                  const SizedBox(height: 16),
                  const Text('Cinsiyet:'),
                  RadioListTile<String>(
                    title: const Text('Erkek'),
                    value: 'Male',
                    groupValue: _selectedGender,
                    onChanged: (value) {
                      setState(() {
                        _selectedGender = value!;
                      });
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('Kadın'),
                    value: 'Female',
                    groupValue: _selectedGender,
                    onChanged: (value) {
                      setState(() {
                        _selectedGender = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text('Dosyalar:'),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_selectedFiles.isNotEmpty)
                          ..._selectedFiles.map((file) => ListTile(
                                title: Text(file.name),
                                trailing: IconButton(
                                  icon: const Icon(Icons.remove_circle_outline),
                                  onPressed: () {
                                    setState(() {
                                      _selectedFiles.remove(file);
                                    });
                                  },
                                ),
                              )),
                        ListTile(
                          leading: const Icon(Icons.add),
                          title: const Text('Dosya Ekle'),
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => Dialog(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      const Text(
                                        'Dosya Seç',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      SizedBox(
                                        height:
                                            MediaQuery.of(context).size.height *
                                                0.4,
                                        child: SingleChildScrollView(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: _files.map((file) {
                                              final isSelected =
                                                  _selectedFiles.contains(file);
                                              return CheckboxListTile(
                                                title: Text(file.name),
                                                value: isSelected,
                                                onChanged: (bool? value) {
                                                  setState(() {
                                                    if (value == true) {
                                                      _selectedFiles.add(file);
                                                    } else {
                                                      _selectedFiles
                                                          .remove(file);
                                                    }
                                                  });
                                                },
                                              );
                                            }).toList(),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            child: const Text('Tamam'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: _isLoading ? null : _handleAddPatient,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Ekle'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAddPatient() async {
    if (_formKey.currentState!.validate() &&
        _selectedDate != null &&
        _selectedFiles.isNotEmpty) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Telefon numarasını düzenle
        String primaryPhone = _primaryPhoneController.text.trim();
        if (primaryPhone.startsWith('0')) {
          primaryPhone = primaryPhone.substring(1);
        }

        // İkincil telefon numarasını kontrol et
        String? secondaryPhone = _secondaryPhoneController.text.trim();
        if (secondaryPhone.isEmpty) {
          secondaryPhone = null;
        } else if (secondaryPhone.startsWith('0')) {
          secondaryPhone = secondaryPhone.substring(1);
        }

        final patientData = {
          'firstName': _firstNameController.text.trim(),
          'lastName': _lastNameController.text.trim(),
          'email': _emailController.text.trim(),
          'dateOfBirth': _selectedDate!.toUtc().toIso8601String(),
          'gender': _selectedGender,
          'primaryPhone': primaryPhone,
          'secondaryPhone': secondaryPhone,
          'fileIds': _selectedFiles.map((file) => file.id).toList(),
        };

        final response = await _patientService.addPatient(patientData);

        if (response['status'] == 'success') {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content:
                      Text(response['message'] ?? 'Hasta başarıyla eklendi')),
            );
            Navigator.pop(context);
            await _loadPatients();
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(response['message'] ?? 'Hasta eklenemedi')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Hasta eklenirken hata oluştu: ${e.toString()}')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen doğum tarihi seçin')),
      );
    } else if (_selectedFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen en az bir dosya seçin')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: _scaffoldKey,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Hastalar'),
          actions: [
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: _showFilterDialog,
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
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
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredPatients.isEmpty
                      ? const Center(
                          child: Text('Hasta bulunamadı'),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredPatients.length,
                          itemBuilder: (context, index) {
                            final patient = _filteredPatients[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              child: ListTile(
                                leading: CircleAvatar(
                                  child: Text(
                                    patient.firstName[0] + patient.lastName[0],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                    '${patient.firstName} ${patient.lastName}'),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('E-posta: ${patient.email}'),
                                    Text('Telefon: ${patient.primaryPhone}'),
                                    Text(
                                        'Doğum Tarihi: ${DateFormat('dd/MM/yyyy').format(patient.dateOfBirth)}'),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Hastayı Sil'),
                                        content: const Text(
                                            'Bu hastayı silmek istediğinizden emin misiniz?'),
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
                                                backgroundColor: Colors.red),
                                            child: const Text('Sil'),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (confirm == true) {
                                      try {
                                        setState(() {
                                          _isLoading = true;
                                        });

                                        final response = await _patientService
                                            .deletePatient(patient.id);

                                        if (response['status'] == 'success') {
                                          await _loadPatients();
                                          if (mounted) {
                                            _scaffoldKey.currentState
                                                ?.showSnackBar(
                                              SnackBar(
                                                  content: Text(response[
                                                          'message'] ??
                                                      'Hasta başarıyla silindi')),
                                            );
                                          }
                                        } else {
                                          if (mounted) {
                                            _scaffoldKey.currentState
                                                ?.showSnackBar(
                                              SnackBar(
                                                  content: Text(
                                                      response['message'] ??
                                                          'Hasta silinemedi')),
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
                                  },
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
        ),
      ),
    );
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
}
