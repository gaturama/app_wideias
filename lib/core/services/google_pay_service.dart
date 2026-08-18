import 'package:flutter/services.dart';

class GooglePayService {
  static const MethodChannel _channel = MethodChannel('wideias/google_pay');

  static const bool mockMode = true;

  Future<bool> isReadyToPay() async {
    if (mockMode) {
      return true;
    }

    try {
      final result = await _channel.invokeMethod<bool>('isReadyToPay');

      return result ?? false;
    } on PlatformException catch (e) {
      throw Exception('Erro ao verificar Google Pay: ${e.message}');
    }
  }

  Future<Map<String, dynamic>> pay({required double amount}) async {
    if (mockMode) {
      await Future.delayed(const Duration(seconds: 2));

      return {
        'status': 'PAID',
        'transactionId':
            'mock-google-pay-${DateTime.now().millisecondsSinceEpoch}',
        'amount': amount,
        'mock': true,
      };
    }

    throw UnimplementedError('Google Pay real ainda não configurado.');
  }
}
