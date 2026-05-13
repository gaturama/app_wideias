import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageProvider extends ChangeNotifier {
  String? _locationId;
  String? _locationName;
  String _tipoLocal = 'evento';
  double _credito = 0.0;

  String? get locationId => _locationId;
  String? get locationName => _locationName;
  String get tipoLocal => _tipoLocal;
  double get credito => _credito;

  Future<void> carregar() async {
    final prefs = await SharedPreferences.getInstance();
    _locationId = prefs.getString('location_id');
    _locationName = prefs.getString('location_name');
    _tipoLocal = prefs.getString('tipo_local') ?? 'evento';
    _credito = prefs.getDouble('credito') ?? 0.0;
    notifyListeners();
  }

  Future<void> setLocation(String id, String name, String tipo) async {
    _locationId = id;
    _locationName = name;
    _tipoLocal = tipo;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('location_id', id);
    await prefs.setString('location_name', name);
    await prefs.setString('tipo_local', tipo);
    notifyListeners();
  }

  Future<void> setCredito(double valor) async {
    _credito = valor;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('credito', valor);
    notifyListeners();
  }

  Future<void> limpar() async {
    _locationId = null;
    _locationName = null;
    _tipoLocal = 'evento';
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('location_id');
    await prefs.remove('location_name');
    await prefs.remove('tipo_local');
    notifyListeners();
  }
}
