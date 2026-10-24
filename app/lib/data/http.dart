import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The shared HTTP client for external APIs.
///
/// `validateStatus` lets every status through: a 401 with the body `{"Error":
/// "Invalid API key!"}` is data for the source's client to read, not an
/// exception. Only network failures remain exceptions.
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

/// A failure where the service was never reached: no network, timeout, DNS.
/// Different from any answer of the service, even an error answer.
bool isNetworkFailure(DioException error) => switch (error.type) {
  DioExceptionType.connectionTimeout ||
  DioExceptionType.sendTimeout ||
  DioExceptionType.receiveTimeout ||
  DioExceptionType.transformTimeout ||
  DioExceptionType.connectionError => true,
  // `unknown` is where dio puts SocketException and everything else below HTTP.
  DioExceptionType.unknown => true,
  DioExceptionType.badCertificate ||
  DioExceptionType.badResponse ||
  DioExceptionType.cancel => false,
};
