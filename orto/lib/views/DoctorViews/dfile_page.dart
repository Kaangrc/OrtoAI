import 'package:flutter/material.dart';
import 'package:ortopedi_ai/models/file_model.dart';
import 'package:ortopedi_ai/models/form_model.dart';
import 'package:ortopedi_ai/services/file_service.dart';
import 'package:ortopedi_ai/services/form_service.dart';
import 'package:ortopedi_ai/utils/api_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ortopedi_ai/views/DoctorViews/dformpage.dart';

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
  bool _isLoading = false;
  List<FileModel> _files = [];

  // Form controllers
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  List<Question> _questions = [];
  String _selectedFormType = 'for patients';

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
    _nameController.dispose();
    _descriptionController.dispose();
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
          'name': _nameController.text.trim(),
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
            _nameController.clear();
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yeni Dosya Ekle'),
        content: Form(
          key: _formKey,
          child: TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Dosya Adı',
              prefixIcon: Icon(Icons.file_present),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Lütfen dosya adını girin';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: _isLoading ? null : _handleAddFile,
            child: _isLoading
                ? const CircularProgressIndicator()
                : const Text('Ekle'),
          ),
        ],
      ),
    );
  }

  void _showAddFormDialog(String fileId) {
    _questions = []; // Reset questions
    _selectedFormType = 'for patients'; // Reset form type

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Yeni Form Ekle'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Form Adı',
                      prefixIcon: Icon(Icons.description),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Lütfen form adını girin';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Form Açıklaması',
                      prefixIcon: Icon(Icons.info),
                    ),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Lütfen form açıklamasını girin';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _showAddTextQuestionDialog(setState),
                          icon: const Icon(Icons.text_fields),
                          label: const Text('Metin Sorusu Ekle'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              _showAddMultipleChoiceQuestionDialog(setState),
                          icon: const Icon(Icons.check_box),
                          label: const Text('Çoktan Seçmeli Soru Ekle'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_questions.isNotEmpty) ...[
                    const Text('Eklenen Sorular:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ..._questions.map((q) => Card(
                          child: ListTile(
                            title: Text(q.question),
                            subtitle: q.options != null
                                ? Text('Seçenekler: ${q.options!.join(", ")}')
                                : null,
                            trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () {
                                setState(() {
                                  _questions.remove(q);
                                });
                              },
                            ),
                          ),
                        )),
                  ],
                  const SizedBox(height: 16),
                  const Text('Form Tipi:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  RadioListTile<String>(
                    title: const Text('Hastaya Gönder'),
                    value: 'for patients',
                    groupValue: _selectedFormType,
                    onChanged: (value) {
                      setState(() {
                        _selectedFormType = value!;
                      });
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('Kendin Doldur'),
                    value: 'for me',
                    groupValue: _selectedFormType,
                    onChanged: (value) {
                      setState(() {
                        _selectedFormType = value!;
                      });
                    },
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
              onPressed: _isLoading ? null : () => _handleAddForm(fileId),
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Form Oluştur'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTextQuestionDialog(StateSetter setState) {
    final questionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Metin Sorusu Ekle'),
        content: TextFormField(
          controller: questionController,
          decoration: const InputDecoration(
            labelText: 'Soru',
            prefixIcon: Icon(Icons.question_mark),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Lütfen soruyu girin';
            }
            return null;
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (questionController.text.isNotEmpty) {
                setState(() {
                  _questions.add(Question(
                    question: questionController.text,
                    type: 'text',
                    level: 10, // Sabit level değeri
                  ));
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Ekle'),
          ),
        ],
      ),
    );
  }

  void _showAddMultipleChoiceQuestionDialog(StateSetter setState) {
    final questionController = TextEditingController();
    final optionsController = TextEditingController();
    List<String> options = [];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, dialogSetState) => AlertDialog(
          title: const Text('Çoktan Seçmeli Soru Ekle'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: questionController,
                  decoration: const InputDecoration(
                    labelText: 'Soru',
                    prefixIcon: Icon(Icons.question_mark),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: optionsController,
                  decoration: const InputDecoration(
                    labelText: 'Seçenek',
                    prefixIcon: Icon(Icons.check_box),
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    if (optionsController.text.isNotEmpty) {
                      dialogSetState(() {
                        options.add(optionsController.text);
                        optionsController.clear();
                      });
                    }
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Seçenek Ekle'),
                ),
                if (options.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text('Eklenen Seçenekler:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  ...options.map((option) => ListTile(
                        title: Text(option),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            dialogSetState(() {
                              options.remove(option);
                            });
                          },
                        ),
                      )),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () {
                if (questionController.text.isNotEmpty && options.isNotEmpty) {
                  setState(() {
                    _questions.add(Question(
                      question: questionController.text,
                      options: options,
                      type: 'multiple_choice',
                      level: 10, // Sabit level değeri
                    ));
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Ekle'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAddForm(String fileId) async {
    if (_formKey.currentState!.validate() && _questions.isNotEmpty) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Form verisini hazırla
        final formData = {
          'name': _nameController.text.trim(),
          'description': _descriptionController.text.trim(),
          'questions': _questions
              .map((q) => {
                    'question': q.question,
                    'options': q.options,
                    'type': q.type,
                    'level': 10, // Sabit level değeri
                  })
              .toList(),
          'type': _selectedFormType,
          'file_id': fileId,
          'level': 10, // Sabit level değeri
        };

        print('Form verisi: $formData'); // Debug için

        final response = await _formService.addForm(formData);

        if (response['status'] == 'success') {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content:
                      Text(response['message'] ?? 'Form başarıyla eklendi')),
            );
            // Form alanlarını temizle
            _nameController.clear();
            _descriptionController.clear();
            _questions = [];
            // Dialog'u kapat
            Navigator.pop(context);
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(response['message'] ?? 'Form eklenemedi')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Form eklenirken hata oluştu: ${e.toString()}')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else if (_questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen en az bir soru ekleyin')),
      );
    }
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
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        automaticallyImplyLeading: false,
        title: const Text('Dosyalar'),
      ),
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
                                      // Form silme işlemi
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Formu Sil'),
                                          content: const Text(
                                              'Bu formu silmek istediğinizden emin misiniz?'),
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
                                          final response = await _formService
                                              .deleteForm(form.id);

                                          if (response['status'] == 'success') {
                                            if (mounted) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                    content: Text(response[
                                                            'message'] ??
                                                        'Form başarıyla silindi')),
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
                                                            'Form silinemedi')),
                                              );
                                            }
                                          }
                                        } catch (e) {
                                          if (mounted) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                  content: Text(
                                                      'Form silinirken hata oluştu: ${e.toString()}')),
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
      ),
    );
  }
}
