class PixChargeModel {
  final String chargeId;
  final String copyPasteCode;
  final double amount;
  final DateTime expiresAt;
  final String status;

  PixChargeModel({
    required this.chargeId,
    required this.copyPasteCode,
    required this.amount,
    required this.expiresAt,
    required this.status,
  });

  PixChargeModel copyWith({String? status}) {
    return PixChargeModel(
      chargeId: chargeId,
      copyPasteCode: copyPasteCode,
      amount: amount,
      expiresAt: expiresAt,
      status: status ?? this.status,
    );
  }
}