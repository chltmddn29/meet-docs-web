import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../constants/api_constants.dart';

class DioClient {
  static final DioClient _instance = DioClient._internal();
  factory DioClient() => _instance;

  late final Dio dio;

  DioClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        // Render 무료 플랜은 유휴 15분 후 잠들어 첫 요청(콜드스타트)이 ~50초 걸림.
        // 30초 connectTimeout으로는 콜드스타트를 못 버텨 connection timeout 발생 → 넉넉히 상향.
        connectTimeout: const Duration(seconds: 90),
        receiveTimeout: const Duration(seconds: 120),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    // 콜드스타트·일시적 연결 끊김 자동 재시도.
    // 멱등 요청(GET/HEAD)만 재시도 → POST 중복 제출 방지.
    dio.interceptors.add(
      InterceptorsWrapper(
        onError: (e, handler) async {
          final method = e.requestOptions.method.toUpperCase();
          final isIdempotent = method == 'GET' || method == 'HEAD';
          final isTransient =
              e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.connectionError ||
              e.type == DioExceptionType.receiveTimeout;
          final attempt = (e.requestOptions.extra['retry'] as int?) ?? 0;

          if (isIdempotent && isTransient && attempt < 2) {
            e.requestOptions.extra['retry'] = attempt + 1;
            await Future.delayed(const Duration(seconds: 2));
            try {
              return handler.resolve(await dio.fetch(e.requestOptions));
            } on DioException catch (err) {
              return handler.next(err);
            }
          }
          return handler.next(e);
        },
      ),
    );

    if (kDebugMode) {
      dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
    }
  }
}
