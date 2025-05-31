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
    };
  }
}

class Question {
  final String question;
  final List<String>? options;
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
      options:
          json['options'] != null ? List<String>.from(json['options']) : null,
      type: json['type'],
      level: json['level'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'question': question,
      'options': options,
      'type': type,
      'level': level,
    };
  }
}
