import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:ortopedi_ai/models/file_model.dart';
import 'package:ortopedi_ai/utils/api_client.dart';

class FileService {
  final DioClient _dioClient;
  final FlutterSecureStorage _storage;

  FileService({
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

  Future<List<FileModel>> getAllFiles() async {
    try {
      final token = await _getToken();
      _dioClient.setToken(token);

      final response = await _dioClient.dio.get('/files');

      if (response.statusCode == 200) {
        final List<dynamic> files = response.data;
        print('Dosya verisi: $files'); // Debug için
        return files.map((file) => FileModel.fromJson(file)).toList();
      } else {
        throw Exception('Dosyalar alınamadı: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('DioException: ${e.response?.data}'); // Debug için
      throw Exception(
          e.response?.data?['message'] ?? 'Dosyaları alırken hata oluştu');
    } catch (e) {
      print('Genel hata: $e'); // Debug için
      throw Exception('Dosyaları alırken beklenmeyen bir hata oluştu: $e');
    }
  }

  Future<List<FileModel>> getAllFilesForTenant() async {
    try {
      final token = await _getToken();
      _dioClient.setToken(token);

      final response = await _dioClient.dio.get('/files/tenant/all');

      if (response.statusCode == 200) {
        final List<dynamic> files = response.data;
        return files.map((file) => FileModel.fromJson(file)).toList();
      } else {
        throw Exception('Tenant dosyaları alınamadı');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ??
          'Tenant dosyalarını alırken hata oluştu');
    }
  }

  Future<Map<String, dynamic>> addFile(Map<String, dynamic> data) async {
    try {
      final token = await _getToken();
      _dioClient.setToken(token);

      final response = await _dioClient.dio.post('/files', data: data);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'status': 'success',
          'message': 'Dosya başarıyla eklendi',
          'data': response.data
        };
      } else {
        return {
          'status': 'error',
          'message':
              response.data['message'] ?? 'Dosya eklenirken bir hata oluştu'
        };
      }
    } on DioException catch (e) {
      return {
        'status': 'error',
        'message':
            e.response?.data?['message'] ?? 'Dosya eklenirken bir hata oluştu'
      };
    }
  }

  Future<Map<String, dynamic>> updateFile(
      String fileId, Map<String, dynamic> data) async {
    try {
      final token = await _getToken();
      _dioClient.setToken(token);

      final response = await _dioClient.dio.put('/files/$fileId', data: data);

      if (response.statusCode == 200) {
        return {
          'status': 'success',
          'message': 'Dosya başarıyla güncellendi',
          'data': response.data
        };
      } else {
        return {
          'status': 'error',
          'message':
              response.data['message'] ?? 'Dosya güncellenirken bir hata oluştu'
        };
      }
    } on DioException catch (e) {
      return {
        'status': 'error',
        'message': e.response?.data?['message'] ??
            'Dosya güncellenirken bir hata oluştu'
      };
    }
  }

  Future<Map<String, dynamic>> updateFileTenant(
      String fileId, Map<String, dynamic> data) async {
    try {
      final token = await _getToken();
      _dioClient.setToken(token);

      final response =
          await _dioClient.dio.put('/files/tenant/$fileId', data: data);

      if (response.statusCode == 200) {
        return {
          'status': 'success',
          'message': 'Tenant dosyası başarıyla güncellendi',
          'data': response.data
        };
      } else {
        return {
          'status': 'error',
          'message': response.data['message'] ??
              'Tenant dosyası güncellenirken bir hata oluştu'
        };
      }
    } on DioException catch (e) {
      return {
        'status': 'error',
        'message': e.response?.data?['message'] ??
            'Tenant dosyası güncellenirken bir hata oluştu'
      };
    }
  }

  Future<Map<String, dynamic>> deleteFile(String fileId) async {
    try {
      final token = await _getToken();
      _dioClient.setToken(token);

      final response = await _dioClient.dio.delete('/files/$fileId');

      if (response.statusCode == 200) {
        return {
          'status': 'success',
          'message': 'Dosya başarıyla silindi',
          'data': response.data
        };
      } else {
        return {
          'status': 'error',
          'message':
              response.data['message'] ?? 'Dosya silinirken bir hata oluştu'
        };
      }
    } on DioException catch (e) {
      return {
        'status': 'error',
        'message':
            e.response?.data?['message'] ?? 'Dosya silinirken bir hata oluştu'
      };
    }
  }

  Future<Map<String, dynamic>> deleteFileTenant(String fileId) async {
    try {
      final token = await _getToken();
      _dioClient.setToken(token);

      final response = await _dioClient.dio.delete('/files/tenant/$fileId');

      if (response.statusCode == 200) {
        return {
          'status': 'success',
          'message': 'Tenant dosyası başarıyla silindi',
          'data': response.data
        };
      } else {
        return {
          'status': 'error',
          'message': response.data['message'] ??
              'Tenant dosyası silinirken bir hata oluştu'
        };
      }
    } on DioException catch (e) {
      return {
        'status': 'error',
        'message': e.response?.data?['message'] ??
            'Tenant dosyası silinirken bir hata oluştu'
      };
    }
  }
}
