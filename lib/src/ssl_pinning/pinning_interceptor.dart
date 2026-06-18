import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import '../threat_event.dart';
import '../fortress_guard.dart';
import '../utils/fortress_logger.dart';

class PinningInterceptor extends Interceptor {
  final List<String> pinnedKeys;

  PinningInterceptor({required this.pinnedKeys});

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _validateResponseCertificate(response);
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response != null) {
      _validateResponseCertificate(err.response!);
    }
    super.onError(err, handler);
  }

  void _validateResponseCertificate(Response response) {
    // If certificates can be retrieved from connection info (on HTTP/1.x, some clients support this)
    // We can also perform validating during connection initiation using the badCertificateCallback
  }

  /// Verifies a DER encoded certificate byte array against the set pins
  bool verifyCertificate(List<int> derBytes) {
    try {
      final spkiBytes = _extractSPKI(derBytes);
      if (spkiBytes.isEmpty) {
        FortressLogger.warn('SPKI extraction returned empty payload');
        return false;
      }
      final hash = sha256.convert(spkiBytes);
      final hashBase64 = base64.encode(hash.bytes);
      final pin = 'sha256/$hashBase64';

      FortressLogger.info('Verifying pin: $pin');
      for (final pinned in pinnedKeys) {
        if (pinned == pin) {
          FortressLogger.info('SSL certificate pin match successful!');
          return true;
        }
      }
    } catch (e) {
      FortressLogger.error('SSL pinning verification failed with error', e);
    }

    // Mismatch triggered
    FortressGuard().handleThreat(ThreatEvent(
      type: ThreatType.sslPinningMismatch,
      message: 'SSL Certificate Pin validation failure. Intercepting network traffic.',
    ));
    return false;
  }

  /// Extracts the Subject Public Key Info (SPKI) sequence from the DER ASN.1 structure.
  /// Standard X509Certificate structure in ASN.1:
  /// Certificate ::= SEQUENCE {
  ///   tbsCertificate      TBSCertificate,
  ///   signatureAlgorithm  AlgorithmIdentifier,
  ///   signatureValue      BIT STRING
  /// }
  /// TBSCertificate ::= SEQUENCE {
  ///   version         [0] EXPLICIT Version DEFAULT v1,
  ///   serialNumber        CertificateSerialNumber,
  ///   signature           AlgorithmIdentifier,
  ///   issuer              Name,
  ///   validity            Validity,
  ///   subject             Name,
  ///   subjectPublicKeyInfo SubjectPublicKeyInfo,
  ///   ...
  /// }
  List<int> _extractSPKI(List<int> der) {
    try {
      int offset = 0;

      // Outer sequence header
      if (der[offset++] != 0x30) return [];
      final certLenObj = _readLength(der, offset);
      offset = certLenObj.nextOffset;

      // TBSCertificate sequence header
      if (der[offset++] != 0x30) return [];
      final tbsLenObj = _readLength(der, offset);
      offset = tbsLenObj.nextOffset;

      // Check version tag [0]
      if (der[offset] == 0xA0) {
        final verLenObj = _readLength(der, offset + 1);
        offset = verLenObj.nextOffset + verLenObj.length;
      }

      // SerialNumber (INTEGER)
      if (der[offset++] != 0x02) return [];
      final serialLenObj = _readLength(der, offset);
      offset = serialLenObj.nextOffset + serialLenObj.length;

      // Signature AlgorithmIdentifier (SEQUENCE)
      if (der[offset++] != 0x30) return [];
      final sigLenObj = _readLength(der, offset);
      offset = sigLenObj.nextOffset + sigLenObj.length;

      // Issuer Name (SEQUENCE)
      if (der[offset++] != 0x30) return [];
      final issuerLenObj = _readLength(der, offset);
      offset = issuerLenObj.nextOffset + issuerLenObj.length;

      // Validity (SEQUENCE)
      if (der[offset++] != 0x30) return [];
      final validityLenObj = _readLength(der, offset);
      offset = validityLenObj.nextOffset + validityLenObj.length;

      // Subject Name (SEQUENCE)
      if (der[offset++] != 0x30) return [];
      final subjectLenObj = _readLength(der, offset);
      offset = subjectLenObj.nextOffset + subjectLenObj.length;

      // Now we should be at SubjectPublicKeyInfo sequence
      final spkiStart = offset;
      if (der[offset++] != 0x30) return [];
      final spkiLenObj = _readLength(der, offset);
      final spkiTotalLen = (spkiLenObj.nextOffset - spkiStart) + spkiLenObj.length;

      if (spkiStart + spkiTotalLen > der.length) return [];

      return der.sublist(spkiStart, spkiStart + spkiTotalLen);
    } catch (e) {
      FortressLogger.error('Error parsing certificate ASN.1 structure', e);
    }
    return [];
  }

  _AsnLength _readLength(List<int> bytes, int offset) {
    final first = bytes[offset++];
    if ((first & 0x80) == 0) {
      return _AsnLength(length: first, nextOffset: offset);
    }
    final count = first & 0x7F;
    int len = 0;
    for (int i = 0; i < count; i++) {
      len = (len << 8) | bytes[offset++];
    }
    return _AsnLength(length: len, nextOffset: offset);
  }
}

class _AsnLength {
  final int length;
  final int nextOffset;
  const _AsnLength({required this.length, required this.nextOffset});
}
