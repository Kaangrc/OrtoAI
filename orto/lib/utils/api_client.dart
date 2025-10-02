import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DioClient {
  late Dio dio;
  final FlutterSecureStorage storage;

  final String baseUrl = 'http://localhost:3000/api';
  static const String tokenKey = 'token';

  DioClient({required this.storage}) {
    dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      validateStatus: (status) => status != null && status < 500,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        print('➡️ REQUEST PATH: ${options.path}');

        final token = await storage.read(key: tokenKey);
        final isAuthRoute = options.path.contains('/auth/tenant/login') ||
            (options.path.contains('/auth/tenant/register') &&
                !options.path.contains('/auth/tenant/register-doctor'));

        if (isAuthRoute) {
          options.headers.remove('Authorization');
          print('ℹ️ Authorization header removed for auth route');
        } else if (token != null) {
          // Eğer istek zaten Authorization içeriyorsa, üzerine yazma
          if (!options.headers.containsKey('Authorization')) {
            options.headers['Authorization'] = 'Bearer $token';
            print('🔐 Authorization header added: Bearer $token');
          }
        }

        print('📝 HEADERS: ${options.headers}');
        if (options.data != null) print('📦 DATA: ${options.data}');
        return handler.next(options);
      },
      onResponse: (response, handler) {
        print('✅ RESPONSE [${response.statusCode}]: ${response.data}');
        return handler.next(response);
      },
      onError: (DioException e, handler) {
        print('❌ ERROR [${e.response?.statusCode}]: ${e.message}');
        if (e.response != null) {
          print('🧾 ERROR BODY: ${e.response?.data}');
        }

        if (e.response?.statusCode == 500) {
          return handler.resolve(
            Response(
              requestOptions: e.requestOptions,
              data: {
                'status': 'error',
                'message': 'Sunucu hatası. Lütfen daha sonra tekrar deneyin.',
              },
            ),
          );
        }

        return handler.next(e);
      },
    ));
  }

  Future<void> setToken(String token) async {
    print('💾 Saving token...');
    await storage.write(key: tokenKey, value: token);
  }

  Future<void> clearToken() async {
    print('🧹 Clearing token...');
    await storage.delete(key: tokenKey);
  }
}
