import 'dart:async';

import 'package:ballistics_wallet_flutter/models/product_info.dart';
import 'package:ballistics_wallet_flutter/repository/product_image_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'auth_repository_test.mocks.dart';

void main() {
  test(
    'rejects an oversized download from Content-Length before buffering',
    () {
      final client = _RecordingClient(
        http.StreamedResponse(
          const Stream<List<int>>.empty(),
          200,
          contentLength: 5 * 1024 * 1024 + 1,
          headers: {'content-type': 'image/png'},
        ),
      );
      final repository = ProductImageRepository(
        MockAuthRepository(),
        httpClient: client,
      );

      expect(
        repository.saveProductImageFromUrl(
          product: ProductInfo.empty(),
          imageUrl: 'https://example.com/image.png',
        ),
        throwsA(isA<FormatException>()),
      );
    },
  );

  test('closes its reusable HTTP client', () {
    final client = _RecordingClient(
      http.StreamedResponse(const Stream.empty(), 200),
    );
    ProductImageRepository(MockAuthRepository(), httpClient: client).dispose();

    expect(client.closed, true);
  });
}

class _RecordingClient extends http.BaseClient {
  _RecordingClient(this.response);

  final http.StreamedResponse response;
  bool closed = false;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async =>
      response;

  @override
  void close() {
    closed = true;
    super.close();
  }
}
