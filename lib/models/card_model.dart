class CardFormData {
  final String holder;
  final String number;
  final String expMonth;
  final String expYear;
  final String securityCode;
  final int installments;

  CardFormData({
    required this.holder,
    required this.number,
    required this.expMonth,
    required this.expYear,
    required this.securityCode,
    required this.installments,
  });
}