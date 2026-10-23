import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Записанный ответ внешнего API из `test/fixtures/`.
String fixture(String path) => File('test/fixtures/$path').readAsStringSync();

/// Подменяет сеть: на каждый запрос отвечает [respond], а сами запросы
/// складывает в [requests] — чтобы проверять, как они собраны.
final class FakeHttpAdapter implements HttpClientAdapter {
  FakeHttpAdapter(this.respond);

  /// `null` вместо ответа — имитация отсутствия сети.
  final ({int status, String body})? Function(RequestOptions request) respond;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final reply = respond(options);
    if (reply == null) {
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'offline (fake)',
        error: const SocketException('offline (fake)'),
      );
    }
    return ResponseBody.fromBytes(
      utf8.encode(reply.body),
      reply.status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
