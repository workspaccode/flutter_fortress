import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'pinning_interceptor.dart';

class FortressHttpClient {
  /// Factory method to return a pre-configured [Dio] client with SSL Public Key pinning.
  static Dio create({
    required List<String> pinnedKeys,
    bool allowBadCertificates = false,
  }) {
    final dio = Dio();
    final interceptor = PinningInterceptor(pinnedKeys: pinnedKeys);

    dio.interceptors.add(interceptor);

    // Attach HttpClientAdapter certificate override
    dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        final client = HttpClient();
        
        client.badCertificateCallback = (X509Certificate cert, String host, int port) {
          if (allowBadCertificates) return true;
          // Validate self-signed/expired/custom CA certificates via pinning hash verification
          return interceptor.verifyCertificate(cert.der);
        };

        // Standard connection check
        client.keyLog = (line) {}; // empty debug logs

        return client;
      },
      validateCertificate: (cert, host, port) {
        if (cert == null) return false;
        return interceptor.verifyCertificate(cert.der);
      },
    );

    return dio;
  }
}
