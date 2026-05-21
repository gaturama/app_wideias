class LocalizacaoModel {
  final String id;
  final String name;
  final String address;
  final String? description;
  final String tipo;
  final bool mesaObrigatoria;

  LocalizacaoModel({
    required this.id,
    required this.name,
    required this.address,
    this.description,
    this.tipo = 'evento',
    this.mesaObrigatoria = false,
  });

  factory LocalizacaoModel.fromJson(Map<String, dynamic> json) {
    final local = json['Local']?.toString() ?? '';
    final cidade = json['Cidade']?.toString() ?? '';
    final estado = json['Estado']?.toString() ?? '';

    String address = json['address']?.toString() ?? '';
    if (address.isEmpty) {
      if (cidade.isNotEmpty) {
        address = '$local - $cidade, $estado';
      } else {
        address = local;
      }
    }

    return LocalizacaoModel(
      id: json['ID']?.toString() ?? json['id']?.toString() ?? '',
      name: json['Evento']?.toString() ?? json['name']?.toString() ?? '',
      address: address,
      description: local.isNotEmpty ? local: null,
      tipo: 'evento',
      mesaObrigatoria: json['MesaObrigatoria']?.toString() == 'S',
    );
  }
}
