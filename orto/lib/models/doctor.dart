// doctor_model.dart
class DoctorModel {
  final String id;
  final String name;
  final String surname;
  final String email;
  final String? specialization;
  final String? phoneNumber;

  DoctorModel({
    required this.id,
    required this.name,
    required this.surname,
    required this.email,
    this.specialization,
    this.phoneNumber,
  });

  factory DoctorModel.fromJson(Map<String, dynamic> json) {
    return DoctorModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      surname: json['surname']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      specialization: json['specialization']?.toString(),
      phoneNumber: json['phone_number']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'surname': surname,
      'email': email,
      'specialization': specialization,
      'phone_number': phoneNumber,
    };
  }
}
