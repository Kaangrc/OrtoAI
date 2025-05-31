import 'package:ortopedi_ai/models/file_model.dart';

class PatientModel {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final DateTime dateOfBirth;
  final String gender;
  final String primaryPhone;
  final String? secondaryPhone;
  final List<String>? fileIds;
  final String doctorId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? fileId;
  final DoctorInfo? doctor;
  final List<FileModel>? files;

  PatientModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.dateOfBirth,
    required this.gender,
    required this.primaryPhone,
    this.secondaryPhone,
    this.fileIds,
    required this.doctorId,
    required this.createdAt,
    required this.updatedAt,
    this.fileId,
    this.doctor,
    this.files,
  });

  factory PatientModel.fromJson(Map<String, dynamic> json) {
    return PatientModel(
      id: json['id'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.parse(json['dateOfBirth'])
          : DateTime.now(),
      gender: json['gender'] ?? 'Male',
      primaryPhone: json['primaryPhone'] ?? '',
      secondaryPhone: json['secondaryPhone'],
      fileIds:
          json['fileIds'] != null ? List<String>.from(json['fileIds']) : null,
      doctorId: json['doctorId'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      fileId: json['fileId'],
      doctor:
          json['Doctor'] != null ? DoctorInfo.fromJson(json['Doctor']) : null,
      files: json['Files'] != null
          ? List<FileModel>.from(
              json['Files'].map((x) => FileModel.fromJson(x)))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'dateOfBirth': dateOfBirth.toIso8601String(),
      'gender': gender,
      'primaryPhone': primaryPhone,
      'secondaryPhone': secondaryPhone,
      'fileIds': fileIds,
      'doctorId': doctorId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'fileId': fileId,
      'Doctor': doctor?.toJson(),
      'Files': files?.map((x) => x.toJson()).toList(),
    };
  }
}

class DoctorInfo {
  final String id;
  final String name;
  final String surname;
  final String email;
  final String role;
  final String specialization;
  final String phoneNumber;
  final String tenantId;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  DoctorInfo({
    required this.id,
    required this.name,
    required this.surname,
    required this.email,
    required this.role,
    required this.specialization,
    required this.phoneNumber,
    required this.tenantId,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DoctorInfo.fromJson(Map<String, dynamic> json) {
    return DoctorInfo(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      surname: json['surname'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      specialization: json['specialization'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      tenantId: json['tenant_id'] ?? '',
      createdBy: json['created_by'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'surname': surname,
      'email': email,
      'role': role,
      'specialization': specialization,
      'phone_number': phoneNumber,
      'tenant_id': tenantId,
      'created_by': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
