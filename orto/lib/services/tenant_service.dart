import 'package:dio/dio.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/api_client.dart';

class TenantService {
  final DioClient dioClient;
  final FlutterSecureStorage secureStorage;

  TenantService({
    required this.dioClient,
    required this.secureStorage,
  });

  Future<Map<String, dynamic>> registerTenant(Map<String, dynamic> data) async {
    try {
      final response =
          await dioClient.dio.post('/auth/tenant/register', data: data);
      return response.data;
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> tenantLogin(Map<String, dynamic> data) async {
    try {
      final response =
          await dioClient.dio.post('/auth/tenant/login', data: data);

      if (response.statusCode == 200 && response.data['token'] != null) {
        dioClient.setToken(response.data['token']);
        return {
          'status': 'success',
          'token': response.data['token'],
          'tenant': response.data['tenant'],
          'message': 'Giriş başarılı.'
        };
      }
      return {
        'status': 'error',
        'message': response.data['message'] ?? 'Giriş başarısız.'
      };
    } on DioException catch (e) {
      return {
        'status': 'error',
        'message':
            e.response?.data?['message'] ?? 'Giriş sırasında bir hata oluştu.'
      };
    }
  }

  Future<Map<String, dynamic>?> getTenantInfo() async {
    try {
      final token = await secureStorage.read(key: 'auth_token');
      if (token == null) return null;

      final decodedToken = JwtDecoder.decode(token);
      final tenantId = decodedToken['id'];

      final response = await dioClient.dio.get('/tenants/$tenantId');
      return response.data;
    } on DioException catch (e) {
      return null;
    }
  }

  Future<List<dynamic>> getAllDoctorsForTenant() async {
    try {
      final token = await secureStorage.read(key: 'auth_token');
      if (token == null) {
        throw Exception('Token bulunamadı');
      }

      dioClient.setToken(token); // Header'a token'ı ekle

      final response = await dioClient.dio.get('/doctors/tenant/all');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map && data.containsKey('doctors')) {
          final doctors = data['doctors'];
          if (doctors is Map && doctors.containsKey('admins')) {
            return List<dynamic>.from(doctors['admins']);
          }
        }
        return [];
      } else {
        throw Exception('Doktorlar alınamadı');
      }
    } on DioException catch (e) {
      throw Exception(
          e.response?.data?['message'] ?? 'Doktorları alırken hata oluştu');
    }
  }

  Future<Map<String, dynamic>> updateTenant(
      Map<String, dynamic> updateData) async {
    try {
      final token = await secureStorage.read(key: 'auth_token');
      if (token == null) {
        return {'status': 'error', 'message': 'Oturum bulunamadı'};
      }

      final decodedToken = JwtDecoder.decode(token);
      final tenantId = decodedToken['id'];

      final response = await dioClient.dio.put(
        '/tenants/$tenantId',
        data: updateData,
      );

      return {
        'status': 'success',
        'message': 'Kurum bilgileri başarıyla güncellendi',
        'tenant': response.data
      };
    } on DioException catch (e) {
      return {
        'status': 'error',
        'message': e.response?.data?['message'] ??
            'Güncelleme sırasında bir hata oluştu.'
      };
    }
  }

  Future<bool> deleteTenant() async {
    try {
      final token = await secureStorage.read(key: 'auth_token');
      if (token == null) return false;

      final decodedToken = JwtDecoder.decode(token);
      final tenantId = decodedToken['id'];

      await dioClient.dio.delete('/tenants/$tenantId');
      await secureStorage.delete(key: 'auth_token');
      return true;
    } on DioException catch (e) {
      return true;
    }
  }

  Map<String, dynamic> _handleDioError(DioException e) {
    return {
      'status': 'error',
      'message': e.response?.data?['message'] ?? 'İşlem sırasında hata oluştu.'
    };
  }
}
