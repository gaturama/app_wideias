class UserModel {
  final String id;
  final String uid;
  final String nome;
  final String email;
  final String telefone;
  final String token;

  UserModel({
    required this.id,
    required this.uid,
    required this.nome,
    required this.email,
    required this.telefone, 
    required this.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> json, String token) {
    return UserModel(
      id: json['IDCliente']?.toString() ?? '',
      uid: json['UID']?.toString() ?? '',
      nome: json['Nome']?.toString() ?? '',
      email: json['Email']?.toString() ?? '',
      telefone: json['Telefone']?.toString() ?? '',
      token: 
        token ??
        json['Token']?.toString() ??
        json['token']?.toString() ?? 
        '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'uid': uid,
    'nome': nome,
    'email': email,
    'telefone': telefone,
    'token': token,
  };
}