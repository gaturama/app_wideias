class LocalizacaoModel {
  final String id;
  final String name;
  final String address;
  final String? description;
  final String tipo;

  LocalizacaoModel({
    required this.id,
    required this.name,
    required this.address,
    this.description,
    this.tipo = 'evento',
  });

  factory LocalizacaoModel.fromJson(Map<String, dynamic> json) {
    return LocalizacaoModel(
      id: json['ID']?.toString() ?? json['id']?.toString() ?? '',
      name: json['Evento']?.toString() ?? json['name']?.toString() ?? '',
      address: _buildAddress(json),
      description: json['Local']?.toString() ?? json['description']?.toString(),
      tipo: 'evento',
    );
  }

  static String _buildAddress(Map<String, dynamic> json) {
    final local = json['Local']?.toString() ?? '';
    final cidade = json['Cidade']?.toString() ?? '';
    final estado = json['Estado']?.toString() ?? '';
    final address = json['address']?.toString() ?? '';
    if (address.isNotEmpty) return address;
    if (cidade.isNotEmpty) return '$local — $cidade, $estado';
    return local;
  }
}
