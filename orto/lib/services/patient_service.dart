// lib/services/patient_service.dart
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:ortopedi_ai/models/patientmodel.dart';
import 'package:ortopedi_ai/utils/api_client.dart';

class PatientService {
  final DioClient _dioClient;
  final FlutterSecureStorage _storage;

  PatientService({
    required DioClient dioClient,
    FlutterSecureStorage? secureStorage,
  })  : _dioClient = dioClient,
        _storage = secureStorage ?? const FlutterSecureStorage();

  Future<String> _getToken() async {
    final token = await _storage.read(key: 'auth_token');
    if (token == null) {
      throw Exception('Token bulunamadı');
    }
    return token;
  }

  Future<String> _getTenantId() async {
    final token = await _getToken();
    final decodedToken = JwtDecoder.decode(token);
    return decodedToken['tenant_id'];
  }

  Future<List<PatientModel>> getAllPatients() async {
    try {
      final response = await _dioClient.dio.get('/patients/all');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = response.data;
        if (responseData['status'] == 'success' &&
            responseData['patients'] != null) {
          final List<dynamic> patients = responseData['patients'];
          return patients
              .map((patient) => PatientModel.fromJson(patient))
              .toList();
        } else {
          throw Exception('Hasta verisi bulunamadı');
        }
      } else {
        throw Exception('Hastalar alınamadı');
      }
    } on DioException catch (e) {
      throw Exception(
          e.response?.data?['message'] ?? 'Hastaları alırken hata oluştu');
    }
  }

  Future<List<PatientModel>> getAllPatientsTenant() async {
    try {
      final response = await _dioClient.dio.get('/patients/tenant/all');

      if (response.statusCode == 200) {
        final List<dynamic> patients = response.data;
        return patients
            .map((patient) => PatientModel.fromJson(patient))
            .toList();
      } else {
        throw Exception('Tenant hastaları alınamadı');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ??
          'Tenant hastalarını alırken hata oluştu');
    }
  }

  Future<PatientModel> getPatientInfo(String patientId) async {
    try {
      final response = await _dioClient.dio.get('/patients/$patientId');

      if (response.statusCode == 200) {
        return PatientModel.fromJson(response.data);
      } else {
        throw Exception('Hasta bilgisi alınamadı');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ??
          'Hasta bilgisi alınırken hata oluştu');
    }
  }

  Future<PatientModel> getPatientInfoTenant(String patientId) async {
    try {
      final response = await _dioClient.dio.get('/patients/tenant/$patientId');

      if (response.statusCode == 200) {
        return PatientModel.fromJson(response.data);
      } else {
        throw Exception('Tenant hasta bilgisi alınamadı');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ??
          'Tenant hasta bilgisi alınırken hata oluştu');
    }
  }

  Future<Map<String, dynamic>> addPatient(Map<String, dynamic> data) async {
    try {
      final response = await _dioClient.dio.post('/patients/add', data: data);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'status': 'success',
          'message': 'Hasta başarıyla eklendi',
          'data': response.data
        };
      } else {
        return {
          'status': 'error',
          'message':
              response.data['message'] ?? 'Hasta eklenirken bir hata oluştu'
        };
      }
    } on DioException catch (e) {
      return {
        'status': 'error',
        'message':
            e.response?.data?['message'] ?? 'Hasta eklenirken bir hata oluştu'
      };
    }
  }

  Future<Map<String, dynamic>> addPatientTenant(
      Map<String, dynamic> data) async {
    try {
      final response =
          await _dioClient.dio.post('/patients/tenant', data: data);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'status': 'success',
          'message': 'Tenant hasta başarıyla eklendi',
          'data': response.data
        };
      } else {
        return {
          'status': 'error',
          'message': response.data['message'] ??
              'Tenant hasta eklenirken bir hata oluştu'
        };
      }
    } on DioException catch (e) {
      return {
        'status': 'error',
        'message': e.response?.data?['message'] ??
            'Tenant hasta eklenirken bir hata oluştu'
      };
    }
  }

  Future<Map<String, dynamic>> updatePatient(
      String patientId, Map<String, dynamic> data) async {
    try {
      final response =
          await _dioClient.dio.put('/patients/$patientId', data: data);

      if (response.statusCode == 200) {
        return {
          'status': 'success',
          'message': 'Hasta başarıyla güncellendi',
          'data': response.data
        };
      } else {
        return {
          'status': 'error',
          'message':
              response.data['message'] ?? 'Hasta güncellenirken bir hata oluştu'
        };
      }
    } on DioException catch (e) {
      return {
        'status': 'error',
        'message': e.response?.data?['message'] ??
            'Hasta güncellenirken bir hata oluştu'
      };
    }
  }

  Future<Map<String, dynamic>> updatePatientTenant(
      String patientId, Map<String, dynamic> data) async {
    try {
      final response =
          await _dioClient.dio.put('/patients/tenant/$patientId', data: data);

      if (response.statusCode == 200) {
        return {
          'status': 'success',
          'message': 'Tenant hasta başarıyla güncellendi',
          'data': response.data
        };
      } else {
        return {
          'status': 'error',
          'message': response.data['message'] ??
              'Tenant hasta güncellenirken bir hata oluştu'
        };
      }
    } on DioException catch (e) {
      return {
        'status': 'error',
        'message': e.response?.data?['message'] ??
            'Tenant hasta güncellenirken bir hata oluştu'
      };
    }
  }

  Future<Map<String, dynamic>> deletePatient(String patientId) async {
    try {
      final response = await _dioClient.dio.delete('/patients/$patientId');

      if (response.statusCode == 200) {
        return {
          'status': 'success',
          'message': 'Hasta başarıyla silindi',
          'data': response.data
        };
      } else {
        return {
          'status': 'error',
          'message':
              response.data['message'] ?? 'Hasta silinirken bir hata oluştu'
        };
      }
    } on DioException catch (e) {
      return {
        'status': 'error',
        'message':
            e.response?.data?['message'] ?? 'Hasta silinirken bir hata oluştu'
      };
    }
  }

  Future<Map<String, dynamic>> deletePatientTenant(String patientId) async {
    try {
      final response =
          await _dioClient.dio.delete('/patients/tenant/$patientId');

      if (response.statusCode == 200) {
        return {
          'status': 'success',
          'message': 'Tenant hasta başarıyla silindi',
          'data': response.data
        };
      } else {
        return {
          'status': 'error',
          'message': response.data['message'] ??
              'Tenant hasta silinirken bir hata oluştu'
        };
      }
    } on DioException catch (e) {
      return {
        'status': 'error',
        'message': e.response?.data?['message'] ??
            'Tenant hasta silinirken bir hata oluştu'
      };
    }
  }
}
