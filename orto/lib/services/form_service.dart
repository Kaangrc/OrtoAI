import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:ortopedi_ai/models/form_model.dart';
import 'package:ortopedi_ai/utils/api_client.dart';

class FormService {
  final DioClient _dioClient;
  final FlutterSecureStorage _storage;

  FormService({
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

  Future<List<FormModel>> getAllForms() async {
    try {
      final token = await _getToken();
      _dioClient.setToken(token);

      final response = await _dioClient.dio.get('/forms');

      if (response.statusCode == 200) {
        final List<dynamic> forms = response.data;
        return forms.map((form) => FormModel.fromJson(form)).toList();
      } else {
        throw Exception('Formlar alınamadı');
      }
    } on DioException catch (e) {
      throw Exception(
          e.response?.data?['message'] ?? 'Formları alırken hata oluştu');
    }
  }

  Future<FormModel> getFormInfo(String formId) async {
    try {
      final token = await _getToken();
      _dioClient.setToken(token);

      final response = await _dioClient.dio.get('/forms/$formId');

      if (response.statusCode == 200) {
        return FormModel.fromJson(response.data);
      } else {
        throw Exception('Form bilgisi alınamadı');
      }
    } on DioException catch (e) {
      throw Exception(
          e.response?.data?['message'] ?? 'Form bilgisi alınırken hata oluştu');
    }
  }

  Future<List<FormModel>> getFormsForTenant() async {
    try {
      final token = await _getToken();
      _dioClient.setToken(token);

      final response = await _dioClient.dio.get('/forms/tenant/all');

      if (response.statusCode == 200) {
        final List<dynamic> forms = response.data;
        return forms.map((form) => FormModel.fromJson(form)).toList();
      } else {
        throw Exception('Tenant formları alınamadı');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ??
          'Tenant formlarını alırken hata oluştu');
    }
  }

  Future<Map<String, dynamic>> addForm(Map<String, dynamic> data) async {
    try {
      final token = await _getToken();
      _dioClient.setToken(token);

      // Form verisini hazırla
      final formData = {
        'name': data['name'],
        'description': data['description'],
        'questions': data['questions']
            .map((q) => {
                  'question': q['question'],
                  'options': q['options'],
                  'type': q['type'],
                  'level': 10, // Sabit level değeri
                })
            .toList(),
        'type': data['type'],
        'file_id': data['file_id'],
        'level': 10, // Sabit level değeri
      };

      print('Form verisi: $formData'); // Debug için

      final response = await _dioClient.dio.post('/forms', data: formData);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'status': 'success',
          'message': 'Form başarıyla eklendi',
          'data': response.data
        };
      } else {
        return {
          'status': 'error',
          'message':
              response.data['message'] ?? 'Form eklenirken bir hata oluştu'
        };
      }
    } on DioException catch (e) {
      print('DioException: ${e.response?.data}'); // Debug için
      return {
        'status': 'error',
        'message':
            e.response?.data?['message'] ?? 'Form eklenirken bir hata oluştu'
      };
    }
  }

  Future<Map<String, dynamic>> updateForm(
      String formId, Map<String, dynamic> data) async {
    try {
      final token = await _getToken();
      _dioClient.setToken(token);

      final response = await _dioClient.dio.put('/forms/$formId', data: data);

      if (response.statusCode == 200) {
        return {
          'status': 'success',
          'message': 'Form başarıyla güncellendi',
          'data': response.data
        };
      } else {
        return {
          'status': 'error',
          'message':
              response.data['message'] ?? 'Form güncellenirken bir hata oluştu'
        };
      }
    } on DioException catch (e) {
      return {
        'status': 'error',
        'message': e.response?.data?['message'] ??
            'Form güncellenirken bir hata oluştu'
      };
    }
  }

  Future<Map<String, dynamic>> updateFormTenant(
      String formId, Map<String, dynamic> data) async {
    try {
      final token = await _getToken();
      _dioClient.setToken(token);

      final response =
          await _dioClient.dio.put('/forms/tenant/$formId', data: data);

      if (response.statusCode == 200) {
        return {
          'status': 'success',
          'message': 'Tenant formu başarıyla güncellendi',
          'data': response.data
        };
      } else {
        return {
          'status': 'error',
          'message': response.data['message'] ??
              'Tenant formu güncellenirken bir hata oluştu'
        };
      }
    } on DioException catch (e) {
      return {
        'status': 'error',
        'message': e.response?.data?['message'] ??
            'Tenant formu güncellenirken bir hata oluştu'
      };
    }
  }

  Future<Map<String, dynamic>> deleteForm(String formId) async {
    try {
      final token = await _getToken();
      _dioClient.setToken(token);

      final response = await _dioClient.dio.delete('/forms/$formId');

      if (response.statusCode == 200) {
        return {
          'status': 'success',
          'message': 'Form başarıyla silindi',
          'data': response.data
        };
      } else {
        return {
          'status': 'error',
          'message':
              response.data['message'] ?? 'Form silinirken bir hata oluştu'
        };
      }
    } on DioException catch (e) {
      return {
        'status': 'error',
        'message':
            e.response?.data?['message'] ?? 'Form silinirken bir hata oluştu'
      };
    }
  }

  Future<Map<String, dynamic>> deleteFormTenant(String formId) async {
    try {
      final token = await _getToken();
      _dioClient.setToken(token);

      final response = await _dioClient.dio.delete('/forms/tenant/$formId');

      if (response.statusCode == 200) {
        return {
          'status': 'success',
          'message': 'Tenant formu başarıyla silindi',
          'data': response.data
        };
      } else {
        return {
          'status': 'error',
          'message': response.data['message'] ??
              'Tenant formu silinirken bir hata oluştu'
        };
      }
    } on DioException catch (e) {
      return {
        'status': 'error',
        'message': e.response?.data?['message'] ??
            'Tenant formu silinirken bir hata oluştu'
      };
    }
  }
}
