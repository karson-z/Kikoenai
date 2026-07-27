import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoenai_sites/network/exception.dart';

void main() {
  group('SitesNetworkException', () {
    test('toString 包含 code 和 message', () {
      const exception = SitesNetworkException(
        '测试错误',
        code: SitesExceptionCode.networkError,
      );
      final str = exception.toString();
      expect(str, contains('SitesNetworkException'));
      expect(str, contains('测试错误'));
      expect(str, contains('networkError'));
    });

    test('toString 包含 originalError 和 context', () {
      final original = Exception('原始异常');
      final exception = SitesNetworkException(
        '测试错误',
        originalError: original,
        context: {'status': 500},
      );
      final str = exception.toString();
      expect(str, contains('原始异常'));
      expect(str, contains('status'));
    });
  });

  group('mapToSitesException', () {
    test('connectionTimeout 映射为 networkError', () {
      final dioErr = DioException(
        type: DioExceptionType.connectionTimeout,
        requestOptions: RequestOptions(path: '/test'),
      );
      final mapped = mapToSitesException(dioErr);
      expect(mapped.code, SitesExceptionCode.networkError);
      expect(mapped.message, contains('网络异常'));
    });

    test('badResponse 401 映射为 unauthorized', () {
      final response = Response<dynamic>(
        requestOptions: RequestOptions(path: '/test'),
        statusCode: 401,
        data: {'code': 401},
      );
      final dioErr = DioException(
        type: DioExceptionType.badResponse,
        requestOptions: RequestOptions(path: '/test'),
        response: response,
      );
      final mapped = mapToSitesException(dioErr);
      expect(mapped.code, SitesExceptionCode.unauthorized);
      expect(mapped.context?['status'], 401);
    });

    test('badResponse 404 映射为 notFound', () {
      final response = Response<dynamic>(
        requestOptions: RequestOptions(path: '/test'),
        statusCode: 404,
      );
      final dioErr = DioException(
        type: DioExceptionType.badResponse,
        requestOptions: RequestOptions(path: '/test'),
        response: response,
      );
      final mapped = mapToSitesException(dioErr);
      expect(mapped.code, SitesExceptionCode.notFound);
    });

    test('badResponse 403 映射为 forbidden', () {
      final response = Response<dynamic>(
        requestOptions: RequestOptions(path: '/test'),
        statusCode: 403,
      );
      final dioErr = DioException(
        type: DioExceptionType.badResponse,
        requestOptions: RequestOptions(path: '/test'),
        response: response,
      );
      final mapped = mapToSitesException(dioErr);
      expect(mapped.code, SitesExceptionCode.forbidden);
    });

    test('badResponse 500 映射为 serverError', () {
      final response = Response<dynamic>(
        requestOptions: RequestOptions(path: '/test'),
        statusCode: 500,
      );
      final dioErr = DioException(
        type: DioExceptionType.badResponse,
        requestOptions: RequestOptions(path: '/test'),
        response: response,
      );
      final mapped = mapToSitesException(dioErr);
      expect(mapped.code, SitesExceptionCode.serverError);
    });

    test('badCertificate 映射为 certificateError', () {
      final dioErr = DioException(
        type: DioExceptionType.badCertificate,
        requestOptions: RequestOptions(path: '/test'),
      );
      final mapped = mapToSitesException(dioErr);
      expect(mapped.code, SitesExceptionCode.certificateError);
    });

    test('cancel 映射为 cancelled', () {
      final dioErr = DioException(
        type: DioExceptionType.cancel,
        requestOptions: RequestOptions(path: '/test'),
      );
      final mapped = mapToSitesException(dioErr);
      expect(mapped.code, SitesExceptionCode.cancelled);
    });

    test('FormatException 映射为 parseError', () {
      const err = FormatException('解析失败');
      final mapped = mapToSitesException(err);
      expect(mapped.code, SitesExceptionCode.parseError);
    });

    test('SitesNetworkException 原样返回', () {
      const original = SitesNetworkException(
        '已包装',
        code: SitesExceptionCode.notFound,
      );
      final mapped = mapToSitesException(original);
      expect(identical(mapped, original), isTrue);
    });

    test('未知错误映射', () {
      final mapped = mapToSitesException('随机字符串');
      expect(mapped.code, SitesExceptionCode.unknown);
    });
  });
}
