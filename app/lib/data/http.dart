import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Общий HTTP-клиент для внешних API.
///
/// `validateStatus` пропускает любой код: ответ 401 с телом
/// `{"Error": "Invalid API key!"}` — это данные, которые разбирает клиент
/// источника, а не исключение. Исключением остаются только сетевые сбои.
Dio createDio() => Dio(
  BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 20),
    responseType: ResponseType.json,
    validateStatus: (_) => true,
  ),
);

final dioProvider = Provider<Dio>((ref) {
  final dio = createDio();
  ref.onDispose(dio.close);
  return dio;
});

/// Сбой, при котором до сервиса не достучались: нет сети, таймаут, DNS.
/// Отличается от ответа сервиса, даже ответа-ошибки.
bool isNetworkFailure(DioException error) => switch (error.type) {
  DioExceptionType.connectionTimeout ||
  DioExceptionType.sendTimeout ||
  DioExceptionType.receiveTimeout ||
  DioExceptionType.transformTimeout ||
  DioExceptionType.connectionError => true,
  // `unknown` — сюда dio кладёт SocketException и прочее ниже HTTP.
  DioExceptionType.unknown => true,
  DioExceptionType.badCertificate ||
  DioExceptionType.badResponse ||
  DioExceptionType.cancel => false,
};
