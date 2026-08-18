import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/pix_charge_model.dart';

class PaymentService {
  static const String _sandboxToken = String.fromEnvironment(
    'PAGBANK_SANDBOX_TOKEN',
  );

  static const String _baseUrl = 'https://sandbox.api.pagseguro.com';

  Future<PixChargeModel> createPixCharge({
    required double amount,
    required String referenceId,
  }) async {
    if (_sandboxToken.isEmpty) {
      throw Exception(
        'Token Sandbox não configurado. '
        'Execute o app usando --dart-define=PAGBANK_SANDBOX_TOKEN=SEU_TOKEN',
      );
    }

    final amountInCents = (amount * 100).round();

    final expiracaoUtc = DateTime.now().toUtc().add(const Duration(minutes: 2));

    final expiracaoBrasil = expiracaoUtc.subtract(const Duration(hours: 3));

    final expirationDate =
        '${expiracaoBrasil.year.toString().padLeft(4, '0')}-'
        '${expiracaoBrasil.month.toString().padLeft(2, '0')}-'
        '${expiracaoBrasil.day.toString().padLeft(2, '0')}T'
        '${expiracaoBrasil.hour.toString().padLeft(2, '0')}:'
        '${expiracaoBrasil.minute.toString().padLeft(2, '0')}:'
        '${expiracaoBrasil.second.toString().padLeft(2, '0')}-03:00';

    final headers = {
      'Authorization': 'Bearer $_sandboxToken',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'x-idempotency-key': _generateIdempotencyKey(),
    };

    final body = {
      'reference_id': referenceId,
      'customer': {
        'name': 'Gabriel Teste',
        'email': 'teste@wideias.com.br',
        'tax_id': '12345678909',
      },
      'items': [
        {
          'reference_id': 'WIDEIAS-ITEM-001',
          'name': 'Produto Teste Wideias',
          'quantity': 1,
          'unit_amount': amountInCents,
        },
      ],
      'qr_codes': [
        {
          'amount': {'value': amountInCents},
          'expiration_date': expirationDate,
        },
      ],
    };

    final response = await http.post(
      Uri.parse('$_baseUrl/orders'),
      headers: headers,
      body: jsonEncode(body),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Erro ao criar PIX (${response.statusCode}): ${response.body}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    final orderId = data['id']?.toString();

    if (orderId == null || orderId.isEmpty) {
      throw Exception('PagBank não retornou o ID do pedido.');
    }

    final qrCodes = data['qr_codes'] as List<dynamic>?;

    if (qrCodes == null || qrCodes.isEmpty) {
      throw Exception('PagBank não retornou o QR Code PIX.');
    }

    final qrCode = qrCodes.first as Map<String, dynamic>;

    final copyPasteCode = qrCode['text']?.toString();

    if (copyPasteCode == null || copyPasteCode.isEmpty) {
      throw Exception('PagBank não retornou o código PIX copia e cola.');
    }

    DateTime expiresAt = DateTime.now().add(const Duration(minutes: 2));

    final expiration = qrCode['expiration_date']?.toString();

    if (expiration != null && expiration.isNotEmpty) {
      expiresAt = DateTime.tryParse(expiration) ?? expiresAt;
    }

    return PixChargeModel(
      chargeId: orderId,
      copyPasteCode: copyPasteCode,
      amount: amount,
      expiresAt: expiresAt,
      status: 'PENDING',
    );
  }

  Future<String> checkPixStatus(String orderId) async {
    if (_sandboxToken.isEmpty) {
      throw Exception('Token Sandbox não configurado.');
    }

    final response = await http.get(
      Uri.parse('$_baseUrl/orders/$orderId'),
      headers: {
        'Authorization': 'Bearer $_sandboxToken',
        'Accept': 'application/json',
      },
    );

    print('=== PAGBANK PIX STATUS ===');
    print('HTTP: ${response.statusCode}');
    print('BODY: ${response.body}');

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Erro ao consultar PIX (${response.statusCode}): ${response.body}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    print('=== PAGBANK CHARGES ===');
    print(data['charges']);
    print('=======================');

    final charges = data['charges'] as List<dynamic>?;

    if (charges == null || charges.isEmpty) {
      return 'PENDING';
    }

    final charge = charges.first as Map<String, dynamic>;

    return charge['status']?.toString().toUpperCase() ?? 'PENDING';
  }

  String _generateIdempotencyKey() {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    return 'wideias-$timestamp';
  }

  Future<Map<String, dynamic>> chargeCard({
    required String encryptedCard,
    required double amount,
    required int installments,
    required String referenceId,
  }) async {
    if (_sandboxToken.isEmpty) {
      throw Exception('Token Sandbox não configurado.');
    }

    final amountInCents = (amount * 100).round();

    final headers = {
      'Authorization': 'Bearer $_sandboxToken',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'x-idempotency-key': _generateIdempotencyKey(),
    };

    final body = {
      'reference_id': referenceId,
      'customer': {
        'name': 'Gabriel Teste',
        'email': 'teste@wideias.com.br',
        'tax_id': '12345678909',
      },
      'items': [
        {
          'reference_id': 'WIDEIAS-CARD-001',
          'name': 'Produto Teste Wideias',
          'quantity': 1,
          'unit_amount': amountInCents,
        },
      ],
      'charges': [
        {
          'reference_id': referenceId,
          'description': 'Pagamento Wideias',
          'amount': {'value': amountInCents, 'currency': 'BRL'},
          'payment_method': {
            'type': 'CREDIT_CARD',
            'installments': installments,
            'capture': true,
            'card': {'encrypted': encryptedCard},
          },
        },
      ],
    };

    final response = await http.post(
      Uri.parse('$_baseUrl/orders'),
      headers: headers,
      body: jsonEncode(body),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Erro ao processar cartão (${response.statusCode}): ${response.body}',
      );
    }

    final charges = data['charges'] as List<dynamic>?;

    if (charges == null || charges.isEmpty) {
      throw Exception('PagBank não retornou a cobrança do cartão.');
    }

    final charge = charges.first as Map<String, dynamic>;

    return {
      'status': charge['status']?.toString().toUpperCase() ?? 'UNKNOWN',
      'chargeId': charge['id']?.toString(),
      'responseCode': charge['payment_response']?['code']?.toString(),
      'responseMessage': charge['payment_response']?['message']?.toString(),
    };
  }
}
