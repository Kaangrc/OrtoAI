import 'package:dio/dio.dart';
import 'package:ortopedi_ai/models/form_model.dart';
import 'package:ortopedi_ai/utils/api_client.dart';

class FormAnswerService {
  final DioClient _dioClient;

  FormAnswerService({
    required DioClient dioClient,
  }) : _dioClient = dioClient;

  Future<Map<String, dynamic>> sendFormAnswer({
    required String formId,
    required String patientId,
    required FormModel formInfo,
    required List<Map<String, dynamic>> answers,
    required num totalScore,
  }) async {
    try {
      // Token interceptor tarafından otomatik ekleniyor, burada yalnızca body hazırlanıyor
      final payload = {
        'form_id': formId,
        'patient_id': patientId,
        'name': formInfo.name,
        'description': formInfo.description,
        'type': formInfo.type,
        'questions': List.generate(answers.length, (index) {
          final answer = answers[index];
          final question = formInfo.questions?[index];
          return {
            'question': question?.question,
            'answer': answer['value'],
            'type': question?.type,
            'option_level': answer['option_level'],
          };
        }),
        'total_form_score': totalScore,
      };

      final response =
          await _dioClient.dio.post('/form-answers', data: payload);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'status': 'success',
          'message': response.data is Map<String, dynamic>
              ? (response.data['message'] ?? 'Form yanıtı gönderildi')
              : 'Form yanıtı gönderildi',
          'data': response.data,
        };
      }

      return {
        'status': 'error',
        'message': response.data is Map<String, dynamic>
            ? (response.data['message'] ?? 'Form yanıtı gönderilemedi')
            : 'Form yanıtı gönderilemedi',
      };
    } on DioException catch (e) {
      return {
        'status': 'error',
        'message': e.response?.data is Map<String, dynamic>
            ? (e.response?.data['message'] ?? 'Form yanıtı gönderilirken hata')
            : 'Form yanıtı gönderilirken hata',
      };
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Beklenmeyen bir hata oluştu: $e',
      };
    }
  }

  Future<List<Map<String, dynamic>>> getAnswers({
    String? patientId,
    String? formId,
  }) async {
    try {
      final query = <String, dynamic>{};
      if (patientId != null) query['patient_id'] = patientId;
      if (formId != null) query['form_id'] = formId;

      final response = await _dioClient.dio.get(
        '/form-answers',
        queryParameters: query.isEmpty ? null : query,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is List) {
          return data.cast<Map<String, dynamic>>();
        }
        if (data is Map && data['data'] is List) {
          return (data['data'] as List).cast<Map<String, dynamic>>();
        }
        return [];
      }
      return [];
    } on DioException catch (_) {
      return [];
    } catch (_) {
      return [];
    }
  }
}
