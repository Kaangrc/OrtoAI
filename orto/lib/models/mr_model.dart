class MRModel {
  final String id;
  final String patientId;
  final String doctorId;
  final String imageUrl;
  final String? notes;
  final dynamic analysisResult;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  MRModel({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.imageUrl,
    this.notes,
    this.analysisResult,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MRModel.fromJson(Map<String, dynamic> json) {
    dynamic analysisResult = json['analysisResult'];
    if (analysisResult is String) {
      analysisResult = null;
    }

    return MRModel(
      id: json['id'],
      patientId: json['patientId'],
      doctorId: json['doctorId'],
      imageUrl: json['imageUrl'],
      notes: json['notes'],
      analysisResult: analysisResult,
      status: json['status'] ?? 'pending',
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientId': patientId,
      'doctorId': doctorId,
      'imageUrl': imageUrl,
      'notes': notes,
      'analysisResult': analysisResult,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
