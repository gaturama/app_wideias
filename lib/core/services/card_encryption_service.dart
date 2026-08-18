import 'dart:async';
import 'dart:convert';
import 'package:webview_flutter/webview_flutter.dart';
import '../../models/card_model.dart';

class CardEncryptionResult {
  final bool success;
  final String? encryptedCard;
  final List<String> errors;

  CardEncryptionResult({
    required this.success,
    this.encryptedCard,
    this.errors = const [],
  });
}

class CardEncryptionService {
  static const _publicKey = 'MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAr+ZqgD892U9/HXsa7XqBZUayPquAfh9xx4iwUbTSUAvTlmiXFQNTp0Bvt/5vK2FhMj39qSv1zi2OuBjvW38q1E374nzx6NNBL5JosV0+SDINTlCG0cmigHuBOyWzYmjgca+mtQu4WczCaApNaSuVqgb8u7Bd9GCOL4YJotvV5+81frlSwQXralhwRzGhj/A57CGPgGKiuPT+AOGmykIGEZsSD9RKkyoKIoc0OS8CPIzdBOtTtQCIwrLn2FxI83Clcg55W8gkFSOS6rWNbG5qFZWMll6yl02HtunalHmUlRUL66YeGXdMDC2PuRcmZbGO5a/2tbVppW6mfSWG3NPRpgwIDAQAB';

  Completer<CardEncryptionResult>? _completer;
  late final WebViewController _controller;

  CardEncryptionService() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'FlutterChannel',
        onMessageReceived: (message) {
          final data = jsonDecode(message.message);
          final result = CardEncryptionResult(
            success: data['hasErrors'] == false,
            encryptedCard: data['encryptedCard'],
            errors: List<String>.from(data['errors'] ?? []),
          );
          _completer?.complete(result);
          _completer = null;
        },
      )
      ..loadHtmlString(_html);
  }

  Future<CardEncryptionResult> encryptCard(CardFormData card) async {
    _completer = Completer<CardEncryptionResult>();

    final js =
        '''
      (function() {
        var card = PagSeguro.encryptCard({
          publicKey: "$_publicKey",
          holder: "${card.holder}",
          number: "${card.number}",
          expMonth: "${card.expMonth}",
          expYear: "${card.expYear}",
          securityCode: "${card.securityCode}"
        });
        FlutterChannel.postMessage(JSON.stringify({
          encryptedCard: card.encryptedCard,
          hasErrors: card.hasErrors,
          errors: card.errors
        }));
      })();
    ''';

    await _controller.runJavaScript(js);

    return _completer!.future.timeout(
      const Duration(seconds: 15),
      onTimeout: () => CardEncryptionResult(
        success: false,
        errors: const ['Tempo esgotado ao criptografar o cartão'],
      ),
    );
  }

  static const _html = '''
    <!DOCTYPE html>
    <html>
      <head>
        <script src="https://assets.pagseguro.com.br/checkout-sdk-js/rc/dist/browser/pagseguro.min.js"></script>
      </head>
      <body></body>
    </html>
  ''';
}