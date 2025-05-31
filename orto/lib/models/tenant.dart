// tenant_model.dart
class TenantModel {
  final String id;
  final String name;
  final String address;
  final String phoneNumber;
  final String email;
  final String planType;

  TenantModel({
    required this.id,
    required this.name,
    required this.address,
    required this.phoneNumber,
    required this.email,
    required this.planType,
  });

  factory TenantModel.fromJson(Map<String, dynamic> json) {
    return TenantModel(
      id: json['id'],
      name: json['name'],
      address: json['address'],
      phoneNumber: json['phone_number'],
      email: json['email'],
      planType: json['plan_type'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'phone_number': phoneNumber,
      'email': email,
      'plan_type': planType,
    };
  }
}
