class UserModel {
  final String id;
  final String nome;
  final String email;
  final String telefone;
  final String token;

  UserModel({
    required this.id,
    required this.nome,
    required this.email,
    required this.telefone, 
    required this.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> json, String token) {
    return UserModel(
      id: json['IDCliente']?.toString() ?? '',
      nome: json['Nome']?.toString() ?? '',
      email: json['Email']?.toString() ?? '',
      telefone: json['Telefone']?.toString() ?? '',
      token: token,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nome': nome,
    'email': email,
    'telefone': telefone,
    'token': token,
  };
}