import 'package:flutter/material.dart';
import 'package:ortopedi_ai/models/file_model.dart';
import 'package:ortopedi_ai/models/form_model.dart';
import 'package:ortopedi_ai/services/file_service.dart';
import 'package:ortopedi_ai/services/form_service.dart';
import 'package:ortopedi_ai/utils/api_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ortopedi_ai/views/DoctorViews/dformpage.dart';
import 'package:ortopedi_ai/views/DoctorViews/form_stepper.dart';
// import removed: form_fill_stepper.dart (hasta ile doldurma dosya ekranından kaldırıldı)

class DFilePage extends StatefulWidget {
  const DFilePage({super.key});

  @override
  State<DFilePage> createState() => _DFilePageState();
}

class _DFilePageState extends State<DFilePage> {
  final _formKey = GlobalKey<FormState>();
  final _storage = const FlutterSecureStorage();
  late final DioClient _dioClient;
  late final FileService _fileService;
  late final FormService _formService;
  // Hasta servisine burada ihtiyaç yok
  bool _isLoading = false;
  List<FileModel> _files = [];

  // File form controller
  final _fileNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _dioClient = DioClient(storage: _storage);
    _fileService = FileService(dioClient: _dioClient, secureStorage: _storage);
    _formService = FormService(dioClient: _dioClient, secureStorage: _storage);
    _loadFiles();
  }

  @override
  void dispose() {
    _fileNameController.dispose();
    super.dispose();
  }

  Future<void> _loadFiles() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final files = await _fileService.getAllFiles();
      setState(() {
        _files = files;
      });
    } catch (e) {
      print('Dosya yükleme hatası: $e'); // Debug için
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Dosyalar yüklenirken hata oluştu: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
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

  Future<void> _handleAddFile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final formData = {
          'name': _fileNameController.text.trim(),
        };

        final response = await _fileService.addFile(formData);

        if (response['status'] == 'success') {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content:
                      Text(response['message'] ?? 'Dosya başarıyla eklendi')),
            );
            // Form alanını temizle
            _fileNameController.clear();
            // Dosyaları yeniden yükle
            await _loadFiles();
            // Dialog'u kapat
            Navigator.pop(context);
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(response['message'] ?? 'Dosya eklenemedi')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Dosya eklenirken hata oluştu: ${e.toString()}')),
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

  void _showAddFileDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _AddFilePage(
          onFileAdded: () {
            _loadFiles();
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  void _showAddFormDialog(String fileId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FormStepper(
          fileId: fileId,
          onFormAdded: () {
            _loadFiles();
            // Navigator.pop çağrısı FormStepper'da yapılıyor
          },
        ),
      ),
    );
  }

  void _showFormDetails(FormModel form) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DFormPage(formId: form.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _files.isEmpty
              ? const Center(
                  child: Text('Henüz dosya eklenmemiş'),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _files.length,
                  itemBuilder: (context, index) {
                    final file = _files[index];
                    return Card(
                      elevation: 4,
                      child: ExpansionTile(
                        leading: const Icon(Icons.file_present),
                        title: Text(file.name),
                        children: [
                          if (file.forms != null && file.forms!.isNotEmpty)
                            ...file.forms!.map((form) => ListTile(
                                  leading: const Icon(Icons.description),
                                  title: Text(form.name),
                                  subtitle: Text(form.description),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () async {
                                      // Dosya silme işlemi
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Dosyayı Sil'),
                                          content: const Text(
                                              'Bu dosyayı ve içindeki tüm formları silmek istediğinizden emin misiniz?'),
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
                                        setState(() {
                                          _isLoading = true;
                                        });

                                        try {
                                          // Önce dosyaya ait formları sil
                                          if (file.forms != null) {
                                            for (var form in file.forms!) {
                                              await _formService
                                                  .deleteForm(form.id);
                                            }
                                          }

                                          // Sonra dosyayı sil
                                          final response = await _fileService
                                              .deleteFile(file.id);

                                          if (response['status'] == 'success') {
                                            if (mounted) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                    content: Text(response[
                                                            'message'] ??
                                                        'Dosya başarıyla silindi')),
                                              );
                                              // Dosyaları yeniden yükle
                                              await _loadFiles();
                                            }
                                          } else {
                                            if (mounted) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                    content: Text(response[
                                                            'message'] ??
                                                        'Dosya silinemedi')),
                                              );
                                            }
                                          }
                                        } catch (e) {
                                          if (mounted) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                  content: Text(
                                                      'Dosya silinirken hata oluştu: ${e.toString()}')),
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
                                  onTap: () => _showFormDetails(form),
                                ))
                          else
                            const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text('Bu dosyada henüz form bulunmuyor'),
                            ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.add_box),
                                  onPressed: () => _showAddFormDialog(file.id),
                                  tooltip: 'Form Ekle',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () async {
                                    // Dosya silme işlemi
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Dosyayı Sil'),
                                        content: const Text(
                                            'Bu dosyayı ve içindeki tüm formları silmek istediğinizden emin misiniz?'),
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
                                      setState(() {
                                        _isLoading = true;
                                      });

                                      try {
                                        // Önce dosyaya ait formları sil
                                        if (file.forms != null) {
                                          for (var form in file.forms!) {
                                            await _formService
                                                .deleteForm(form.id);
                                          }
                                        }

                                        // Sonra dosyayı sil
                                        final response = await _fileService
                                            .deleteFile(file.id);

                                        if (response['status'] == 'success') {
                                          if (mounted) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                  content: Text(response[
                                                          'message'] ??
                                                      'Dosya başarıyla silindi')),
                                            );
                                            // Dosyaları yeniden yükle
                                            await _loadFiles();
                                          }
                                        } else {
                                          if (mounted) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                  content: Text(
                                                      response['message'] ??
                                                          'Dosya silinemedi')),
                                            );
                                          }
                                        }
                                      } catch (e) {
                                        if (mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                                content: Text(
                                                    'Dosya silinirken hata oluştu: ${e.toString()}')),
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
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddFileDialog,
        child: const Icon(Icons.add),
        tooltip: 'Dosya Ekle',
        heroTag: "add_file_fab",
      ),
    );
  }
}

class _AddFilePage extends StatefulWidget {
  final VoidCallback onFileAdded;

  const _AddFilePage({
    Key? key,
    required this.onFileAdded,
  }) : super(key: key);

  @override
  State<_AddFilePage> createState() => _AddFilePageState();
}

class _AddFilePageState extends State<_AddFilePage> {
  final _formKey = GlobalKey<FormState>();
  final _fileNameController = TextEditingController();
  bool _isLoading = false;

  // Services
  late final DioClient _dioClient;
  late final FileService _fileService;

  @override
  void initState() {
    super.initState();
    const storage = FlutterSecureStorage();
    _dioClient = DioClient(storage: storage);
    _fileService = FileService(dioClient: _dioClient, secureStorage: storage);
  }

  @override
  void dispose() {
    _fileNameController.dispose();
    super.dispose();
  }

  Future<void> _handleAddFile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final formData = {
          'name': _fileNameController.text.trim(),
        };

        final response = await _fileService.addFile(formData);

        if (response['status'] == 'success') {
          if (mounted) {
            // Önce loading durumunu kapat
            setState(() {
              _isLoading = false;
            });

            // Başarı mesajını göster
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Dosya başarıyla oluşturuldu'),
                backgroundColor: Theme.of(context).colorScheme.primary,
                behavior: SnackBarBehavior.floating,
              ),
            );

            // Dosya listesini güncelle
            widget.onFileAdded();
          }
        } else {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(response['message'] ?? 'Dosya oluşturulamadı'),
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
              content:
                  Text('Dosya oluşturulurken hata oluştu: ${e.toString()}'),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yeni Dosya Oluştur'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Text(
                'Dosya Bilgileri',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Yeni bir dosya oluşturmak için aşağıdaki bilgileri doldurun',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 32),

              // Form Card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon and Title
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.create_new_folder,
                              color: Theme.of(context).colorScheme.primary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Text(
                              'Dosya Detayları',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // File Name Input
                      TextFormField(
                        controller: _fileNameController,
                        decoration: const InputDecoration(
                          labelText: 'Dosya Adı *',
                          hintText: 'Örn: Hasta Kayıtları, Raporlar, vb.',
                          prefixIcon: Icon(Icons.file_present),
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Lütfen dosya adını girin';
                          }
                          if (value.trim().length < 3) {
                            return 'Dosya adı en az 3 karakter olmalıdır';
                          }
                          return null;
                        },
                        onChanged: (value) {
                          setState(() {}); // UI'ı güncelle
                        },
                      ),
                      const SizedBox(height: 16),

                      // Info Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.blue[700],
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Bu dosya oluşturulduktan sonra içerisine formlar ekleyebilirsiniz.',
                                style: TextStyle(
                                  color: Colors.blue[700],
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'İptal',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleAddFile,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor:
                            _fileNameController.text.trim().isNotEmpty
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey,
                        foregroundColor:
                            _fileNameController.text.trim().isNotEmpty
                                ? Colors.white
                                : Colors.grey[600],
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Dosya Oluştur',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
