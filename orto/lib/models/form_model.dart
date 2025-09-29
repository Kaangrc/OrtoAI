import 'option_model.dart';

class FormModel {
  final String id;
  final String name;
  final String description;
  final String type;
  final List<Question>? questions;
  final String? fileId;
  final int? level;
  final String? tenantId;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? repeat;

  FormModel({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    this.questions,
    this.fileId,
    this.level,
    this.tenantId,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
    this.repeat,
  });

  factory FormModel.fromJson(Map<String, dynamic> json) {
    List<Question>? questionsList;
    if (json['questions'] != null) {
      try {
        questionsList = (json['questions'] as List)
            .map((q) => Question.fromJson(q))
            .toList();
      } catch (e) {
        print('Soru dönüşüm hatası: $e');
        questionsList = null;
      }
    }

    return FormModel(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      type: json['type'],
      questions: questionsList,
      fileId: json['file_id'],
      level: json['level'],
      tenantId: json['tenant_id'],
      createdBy: json['created_by'],
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      repeat: json['repeat'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type,
      'questions': questions?.map((q) => q.toJson()).toList(),
      'file_id': fileId,
      'level': level,
      'tenant_id': tenantId,
      'created_by': createdBy,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'repeat': repeat,
    };
  }
}

class Question {
  final String question;
  final List<OptionModel>? options;
  final String type;
  final int level;

  Question({
    required this.question,
    this.options,
    required this.type,
    required this.level,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      question: json['question'],
      options: json['options'] != null
          ? (json['options'] as List)
              .map((option) => OptionModel.fromJson(option))
              .toList()
          : null,
      type: json['type'],
      level: json['level'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'question': question,
      'options': options?.map((option) => option.toJson()).toList(),
      'type': type,
      'level': level,
    };
  }
}
