import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

import 'package:ortopedi_ai/utils/api_client.dart';

class DoctorService {
  final DioClient _dioClient;
  final FlutterSecureStorage _storage;

  DoctorService({
    required DioClient dioClient,
    FlutterSecureStorage? secureStorage,
  })  : _dioClient = dioClient,
        _storage = secureStorage ?? const FlutterSecureStorage();

  Future<Map<String, dynamic>> doctorLogin(
      Map<String, dynamic> doctorData) async {
    try {
      final response =
          await _dioClient.dio.post('/auth/login-doctor', data: doctorData);

      if (response.statusCode == 200 && response.data['token'] != null) {
        final token = response.data['token'];

        // Token'ı local'e yaz
        await _storage.write(key: 'auth_token', value: token);

        // Authorization header'ına token'ı setle
        _dioClient.setToken(token);

        return {
          'status': 'success',
          'token': token,
          'doctor': response.data['doctor'],
          'message': 'Giriş başarılı.'
        };
      }

      return {
        'status': 'error',
        'message': response.data['message'] ?? 'Giriş başarısız.'
      };
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> registerDoctor(Map<String, dynamic> data) async {
    try {
      // API'nin beklediği formata dönüştür
      final formattedData = {
        'name': data['name'],
        'surname': data['surname'],
        'email': data['email'],
        'specialization': data['specialization'],
        'phone_number': data['phone_number'],
        'password': data['password'],
        'confirm_password': data['password_confirmation'],
      };

      print('Gönderilen veri: $formattedData'); // Debug için

      final response = await _dioClient.dio
          .post('/auth/admin/register-doctor', data: formattedData);

      print('API Yanıtı: ${response.data}'); // Debug için

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'status': 'success',
          'message': 'Doktor başarıyla eklendi',
          'data': response.data
        };
      } else {
        return {
          'status': 'error',
          'error': response.data['error'] ?? 'Doktor eklenirken bir hata oluştu'
        };
      }
    } on DioException catch (e) {
      print('DioException: ${e.response?.data}'); // Debug için
      return {
        'status': 'error',
        'error':
            e.response?.data?['error'] ?? 'Doktor eklenirken bir hata oluştu'
      };
    }
  }

  Future<Map<String, dynamic>> registerAdminDoctor(
      Map<String, dynamic> data) async {
    try {
      // API'nin beklediği formata dönüştür
      // Not: Tenant kimliği ve Authorization için en güncel tenant token'ını
      // `DioClient.tokenKey` üzerinden okuyoruz.
      final String? tenantToken =
          await _storage.read(key: DioClient.tokenKey) ??
              await _storage.read(key: 'auth_token');
      if (tenantToken == null || JwtDecoder.isExpired(tenantToken)) {
        return {
          'status': 'error',
          'error': 'Geçerli oturum bulunamadı veya token süresi dolmuş'
        };
      }

      // Global client token'ını değiştirmeden yalnızca bu istekte tenant token kullan
      final perRequestOptions = Options(headers: {
        'Authorization': 'Bearer $tenantToken',
      });

      final formattedData = {
        'name': data['name'],
        'surname': data['surname'],
        'email': data['email'],
        'specialization': data['specialization'],
        'phone_number': data['phone_number'],
        'password': data['password'],
        'confirm_password': data['password_confirmation'],
        'role': 'admin',
        'tenant_id': await _getTenantId(),
      };

      print('Gönderilen veri: $formattedData'); // Debug için

      final response = await _dioClient.dio.post(
        '/auth/tenant/register-doctor',
        data: formattedData,
        options: perRequestOptions,
      );

      print('API Yanıtı: ${response.data}'); // Debug için

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'status': 'success',
          'message': 'Doktor başarıyla eklendi',
          'data': response.data
        };
      } else {
        return {
          'status': 'error',
          'error': response.data['error'] ?? 'Doktor eklenirken bir hata oluştu'
        };
      }
    } on DioException catch (e) {
      print('DioException: ${e.response?.data}'); // Debug için
      return {
        'status': 'error',
        'error':
            e.response?.data?['error'] ?? 'Doktor eklenirken bir hata oluştu'
      };
    }
  }

  Future<String> _getTenantId() async {
    // Tercihen tenant token'ını kullan
    final token = await _storage.read(key: DioClient.tokenKey) ??
        await _storage.read(key: 'auth_token');
    if (token == null) {
      throw Exception('Token bulunamadı');
    }
    final decodedToken = JwtDecoder.decode(token);
    return decodedToken['id'];
  }

  Future<Map<String, dynamic>?> getDoctorInfo() async {
    try {
      final token = await _storage.read(key: 'auth_token');

      if (token == null || JwtDecoder.isExpired(token)) {
        return null;
      }

      final doctorId = JwtDecoder.decode(token)['id'];

      final response = await _dioClient.dio.get('/doctors/$doctorId');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map && data.containsKey('doctor')) {
          return data['doctor'];
        }
      }

      return null;
    } on DioException catch (e) {
      print('Hata oluştu: ${e.message}');
      return null;
    }
  }

  Future<Map<String, dynamic>> updateDoctor(Map<String, dynamic> data) async {
    try {
      final doctorId = await _getDoctorId();
      final response = await _dioClient.dio.put(
        '/doctors/$doctorId',
        data: data,
      );
      return {
        'status': 'success',
        'data': response.data,
        'message': 'Doktor bilgileri güncellendi.'
      };
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Doktor bilgileri güncellenirken hata oluştu: $e'
      };
    }
  }

  Future<String> _getDoctorId() async {
    final token = await _storage.read(key: 'auth_token');
    if (token == null) {
      throw Exception('Token bulunamadı');
    }
    final decodedToken = JwtDecoder.decode(token);
    return decodedToken['id'];
  }

  Future<List<Map<String, dynamic>>> getAllDoctors() async {
    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) {
        throw Exception('Token bulunamadı');
      }

      _dioClient.setToken(token); // Header'a token'ı ekle

      final response = await _dioClient.dio.get('/doctors/all');

      print('API Yanıtı: ${response.data}'); // Debug için

      if (response.statusCode == 200) {
        final List<dynamic> doctors = response.data;
        return doctors
            .map((doctor) => Map<String, dynamic>.from(doctor))
            .toList();
      } else {
        throw Exception('Doktorlar alınamadı');
      }
    } on DioException catch (e) {
      print('DioException: ${e.response?.data}'); // Debug için
      throw Exception(
          e.response?.data?['message'] ?? 'Doktorları alırken hata oluştu');
    }
  }

  Map<String, dynamic> _handleDioError(DioException e) {
    return {
      'status': 'error',
      'message': e.response?.data['message'] ??
          'Bir hata oluştu: ${e.message ?? 'Bilinmeyen hata'}',
    };
  }
}
