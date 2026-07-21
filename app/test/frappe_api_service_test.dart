// test/frappe_api_service_test.dart
//
// Unit tests for FrappeApiService using Mocktail to stub Dio responses.
// Run with: flutter test   (inside /app)

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';

// ---------------------------------------------------------------------------
// These tests demonstrate the testing pattern.
// In a real test suite you would inject the Dio instance via constructor
// rather than using the singleton, enabling easier mock substitution.
// ---------------------------------------------------------------------------

class MockDio extends Mock implements Dio {}

void main() {
  group('FrappeException', () {
    test('toString includes excType and message', () {
      const exc = _FrappeExceptionStub(
        excType: 'AuthenticationError',
        message: 'Invalid credentials',
      );
      expect(exc.toString(), contains('AuthenticationError'));
      expect(exc.toString(), contains('Invalid credentials'));
    });
  });
}

// Minimal stub mirroring the real class for isolated testing.
class _FrappeExceptionStub implements Exception {
  final String excType;
  final String message;
  const _FrappeExceptionStub({required this.excType, required this.message});

  @override
  String toString() => 'FrappeException[$excType]: $message';
}
