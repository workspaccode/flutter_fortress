import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'pinning_interceptor.dart';

class FortressHttpClient {
  final Dio _dio;

  Dio get dio => _dio;

  FortressHttpClient._(this._dio);

  factory FortressHttpClient({
    required List<String> pinnedKeys,
    bool allowBadCertificates = false,
  }) {
    final dio = Dio();
    final interceptor = PinningInterceptor(pinnedKeys: pinnedKeys);

    dio.interceptors.add(interceptor);

    dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        final client = HttpClient();

        client.badCertificateCallback = (X509Certificate cert, String host, int port) {
          if (allowBadCertificates) return true;
          return interceptor.verifyCertificate(cert.der);
        };

        client.keyLog = (line) {};

        return client;
      },
      validateCertificate: (cert, host, port) {
        if (cert == null) return false;
        return interceptor.verifyCertificate(cert.der);
      },
    );

    return FortressHttpClient._(dio);
  }

  static Dio create({
    required List<String> pinnedKeys,
    bool allowBadCertificates = false,
  }) =>
      FortressHttpClient(
        pinnedKeys: pinnedKeys,
        allowBadCertificates: allowBadCertificates,
      ).dio;

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) =>
      _dio.get<T>(path, queryParameters: queryParameters, options: options);

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) =>
      _dio.post<T>(path, data: data, queryParameters: queryParameters, options: options);

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) =>
      _dio.put<T>(path, data: data, queryParameters: queryParameters, options: options);

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) =>
      _dio.delete<T>(path, data: data, queryParameters: queryParameters, options: options);
}
