import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http_parser/http_parser.dart';
import 'package:ortopedi_ai/models/mr_model.dart';
import 'package:ortopedi_ai/utils/api_client.dart';

class MRService {
  final DioClient dioClient;
  final FlutterSecureStorage secureStorage;

  MRService({
    required this.dioClient,
    required this.secureStorage,
  });

  Future<Map<String, dynamic>> addMr({
    required String patientId,
    required File imageFile,
    String? notes,
  }) async {
    try {
      // Dosya formatı kontrolü
      final String fileExtension = imageFile.path.split('.').last.toLowerCase();
      if (!['png', 'jpg', 'jpeg'].contains(fileExtension)) {
        return {
          'status': 'error',
          'message': 'Sadece .png, .jpg ve .jpeg formatları desteklenmektedir.',
        };
      }

      // Dosya adını düzenle - timestamp ekle
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String originalFileName = imageFile.path.split('/').last;
      final String fileName = '$timestamp-$originalFileName';

      // MIME type kontrolü
      final String mimeType =
          'image/${fileExtension == 'jpg' ? 'jpeg' : fileExtension}';

      MultipartFile? multipartFile;
      try {
        multipartFile = await MultipartFile.fromFile(
          imageFile.path,
          filename: fileName,
          contentType: MediaType.parse(mimeType),
        );
      } catch (e) {
        print('⚠️ MultipartFile oluşturulurken hata: $e');
        return {
          'status': 'error',
          'message': 'Dosya okunamadı. Lütfen tekrar deneyin.'
        };
      }

      // Form verilerini hazırla
      final formData = FormData.fromMap({
        'patientId': patientId,
        'notes': notes ?? '',
        'mrImage': multipartFile,
      });

      // Debug bilgileri
      print('Form verisi: ${formData.fields}');
      print('Dosya: ${formData.files}');
      print('Dosya uzantısı: $fileExtension');
      print('Dosya adı: $fileName');
      print('MIME Type: $mimeType');
      print('Dosya yolu: ${imageFile.path}');

      // İsteği gönder
      final response = await dioClient.dio.post(
        '/mr/upload',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
            'Accept': 'application/json',
          },
          validateStatus: (status) {
            return status! < 500;
          },
        ),
      );

      print('Sunucu yanıtı: ${response.data}');
      print('Sunucu durum kodu: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data;
        if (responseData == null) {
          return {
            'status': 'error',
            'message': 'Sunucu yanıtı boş',
          };
        }

        return {
          'status': 'success',
          'message': 'MR başarıyla yüklendi',
          'data': responseData,
        };
      } else {
        final errorMessage = response.data is Map
            ? response.data['error'] ?? response.statusMessage
            : response.statusMessage ?? 'Bilinmeyen hata';

        return {
          'status': 'error',
          'message': 'MR yüklenirken bir hata oluştu: $errorMessage',
        };
      }
    } on DioException catch (e) {
      print('MR yükleme hatası: ${e.message}');
      print('Hata detayları: ${e.response?.data}');
      print('Hata tipi: ${e.type}');
      print('Hata durum kodu: ${e.response?.statusCode}');
      print('Hata yanıtı: ${e.response?.data}');
      print('Hata isteği: ${e.requestOptions.data}');

      final errorMessage = e.response?.data is Map
          ? e.response?.data['error'] ?? e.message
          : e.message ?? 'Bilinmeyen hata';

      return {
        'status': 'error',
        'message': errorMessage,
      };
    } catch (e) {
      print('Beklenmeyen hata: $e');
      return {
        'status': 'error',
        'message': 'Beklenmeyen bir hata oluştu: $e',
      };
    }
  }

  Future<List<MRModel>> getPatientMr(String patientId) async {
    try {
      final response = await dioClient.dio.get('/mr/patient/$patientId');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) {
          // Null kontrolü ekle
          if (json['analysisResult'] == null) {
            json['analysisResult'] = ''; // Boş string olarak ayarla
          }
          return MRModel.fromJson(json);
        }).toList();
      } else {
        throw Exception('MR verisi alınamadı');
      }
    } on DioException catch (e) {
      print('MR getirme hatası: ${e.message}');
      print('Hata detayı: ${e.response?.data}');
      throw Exception(e.response?.data?['message'] ??
          'MR verisi alınırken hata oluştu: ${e.message}');
    } catch (e) {
      print('Beklenmeyen hata: $e');
      throw Exception('Beklenmeyen bir hata oluştu: $e');
    }
  }

  Future<Map<String, dynamic>> segmentMr(
      String mrId, String segmentType) async {
    try {
      final response = await dioClient.dio.post(
        '/mr/$mrId/analyze',
        queryParameters: {'segmentType': segmentType},
        options: Options(
          headers: {
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        print('API Yanıtı: $responseData');

        // Görüntü URL'sini web tarafındaki gibi /output/ dizinini kullanacak şekilde güncelle
        if (responseData['analysis'] != null &&
            responseData['analysis']['output_image'] != null) {
          responseData['analysis']['output_image'] =
              'http://localhost:4000/output/${responseData['analysis']['output_image']}';
        }

        return {
          'status': 'success',
          'data': responseData['analysis'],
          'mr': responseData['mr'],
        };
      } else {
        return {
          'status': 'error',
          'message': response.data['message'] ?? 'Analiz başarısız oldu',
        };
      }
    } catch (e) {
      print('Segmentasyon hatası: $e');
      return {
        'status': 'error',
        'message': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> segmentMerged(String mrId) =>
      segmentMr(mrId, 'merged');
  Future<Map<String, dynamic>> segmentFemur(String mrId) =>
      segmentMr(mrId, 'femur');
  Future<Map<String, dynamic>> segmentFibula(String mrId) =>
      segmentMr(mrId, 'fibula');
  Future<Map<String, dynamic>> segmentTibia(String mrId) =>
      segmentMr(mrId, 'tibia');

  // Gerekirse diğer CRUD işlemleri burada eklenebilir.
}
