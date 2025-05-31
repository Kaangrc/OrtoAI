import 'package:ortopedi_ai/models/form_model.dart';

class FileModel {
  final String id;
  final String name;
  final List<FormModel>? forms;

  FileModel({
    required this.id,
    required this.name,
    this.forms,
  });

  factory FileModel.fromJson(Map<String, dynamic> json) {
    List<FormModel>? formsList;
    if (json['Forms'] != null) {
      try {
        formsList = (json['Forms'] as List)
            .map((form) => FormModel.fromJson(form))
            .toList();
      } catch (e) {
        print('Form dönüşüm hatası: $e');
        formsList = null;
      }
    }

    return FileModel(
      id: json['id'],
      name: json['name'],
      forms: formsList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'Forms': forms?.map((f) => f.toJson()).toList(),
    };
  }
}
