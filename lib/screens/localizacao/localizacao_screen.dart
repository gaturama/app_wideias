import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/evento.service.dart';
import '../../models/localizacao_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/storage_provider.dart';
import '../../widgets/custom_alert.dart';

class LocalizacaoScreen extends StatefulWidget {
  const LocalizacaoScreen({super.key});

  @override
  State<LocalizacaoScreen> createState() => _LocalizacaoScreenState();
}

class _LocalizacaoScreenState extends State<LocalizacaoScreen> {
  List<LocalizacaoModel> _locais = [];
  bool _loading = true;
  bool _refreshing = false;
  String _enderecoAtual = 'Buscando localização...';
  String? _erro;

  @override
  void initState() {
    super.initState();
    _inicializar();
  }

  Future<void> _inicializar() async {
    await _buscarLocalizacaoUsuario();
    await _buscarEventos();
  }

  Future<void> _buscarLocalizacaoUsuario() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever ||
          perm == LocationPermission.denied) {
        setState(() => _enderecoAtual = 'Localização não disponível');
        return;
      }
      
      Position? pos;
      try {
        pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low,
          timeLimit: const Duration(seconds: 10),
        );
      } catch (_) {
        pos = await Geolocator.getLastKnownPosition();
      }

      if (pos == null) {
        setState(() => _enderecoAtual = 'Localização não disponível');
        return;
      }

      final placemarks = await placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
      );

      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        setState(
          () => _enderecoAtual = '${p.locality}, ${p.administrativeArea}',
        );
      }
    } catch (e) {
      print('Erro localização: $e');
      setState(() => _enderecoAtual = 'Localização não disponível');
    }
  }

  Future<void> _buscarEventos({bool refresh = false}) async {
    if (refresh) setState(() => _refreshing = true);

    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        setState(() {
          _erro = 'Permissão de localização negada.';
          _loading = false;
          _refreshing = false;
        });
        return;
      }

      Position? pos;
      try {
        pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low,
          timeLimit: const Duration(seconds: 10),
        );
      } catch (_) {
        pos = await Geolocator.getLastKnownPosition();
      }

      pos ??= Position(
        latitude: -27.0288295,
        longitude: -48.6355388,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );

      final auth = context.read<AuthProvider>();
      final token = auth.user?.token ?? '';
      final id = auth.user?.id ?? '';

      print('=== CHECK-IN DATA ===');
      print('Token: $token');
      print('ID: $id');
      print('Lat: ${pos.latitude} | Lng: ${pos.longitude}');

      final eventos = await EventoService.buscarEventos(
        token: token,
        idCliente: id,
        latitude: pos.latitude,
        longitude: pos.longitude,
      );

      setState(() {
        _locais = eventos;
        _erro = null;
        _loading = false;
        _refreshing = false;
      });
    } catch (e) {
      print('Erro em _buscarEventos: $e');
      setState(() {
        _erro = 'Não foi possível carregar os locais.';
        _loading = false;
        _refreshing = false;
      });
    }
  }

  void _handleCheckIn(LocalizacaoModel item) {
    CustomAlert.show(
      context,
      title: 'Confirme sua presença',
      message: 'Você selecionou: ${item.name}.\nConfirme para continuar.',
      confirmText: 'Confirmar',
      cancelText: 'Voltar',
      onConfirm: () async {
        final tipo = item.mesaObrigatoria ? 'restaurante' : 'evento';

        await context.read<StorageProvider>().setLocation(
          item.id,
          item.name,
          tipo,
        );
        if (!mounted) return;
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/home', (route) => false);
      },
      onCancel: () {},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'LOCAIS PRÓXIMOS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: AppColors.textSection,
                  ),
                ),
                GestureDetector(
                  onTap: () => _buscarEventos(refresh: true),
                  child: const Icon(
                    Icons.refresh,
                    color: AppColors.bluePrimary,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: AppColors.bluePrimary,
      padding: const EdgeInsets.fromLTRB(20, 52, 20, 20),
      child: Stack(
        children: [
          Positioned(
            top: -20,
            right: -30,
            child: _circle(140, AppColors.circleDeco1),
          ),
          Positioned(
            bottom: -20,
            left: -30,
            child: _circle(100, AppColors.circleDeco2),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Locais Disponíveis',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.navigation_outlined,
                      color: AppColors.bluePrimary,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Sua localização',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSection,
                            ),
                          ),
                          Text(
                            _enderecoAtual,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.bluePrimary),
            SizedBox(height: 12),
            Text(
              'Buscando locais...',
              style: TextStyle(color: AppColors.textEmpty),
            ),
          ],
        ),
      );
    }

    if (_erro != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.wifi_off_outlined,
              size: 48,
              color: AppColors.textEmpty,
            ),
            const SizedBox(height: 12),
            Text(
              _erro!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textEmpty),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _buscarEventos(refresh: true),
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    if (_locais.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.map_outlined, size: 48, color: AppColors.textEmpty),
            SizedBox(height: 12),
            Text(
              'Nenhum local disponível no momento',
              style: TextStyle(color: AppColors.textEmpty),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.bluePrimary,
      onRefresh: () => _buscarEventos(refresh: true),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        itemCount: _locais.length,
        itemBuilder: (_, i) => _buildCard(_locais[i]),
      ),
    );
  }

  Widget _buildCard(LocalizacaoModel item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: AppColors.badgeBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.location_on_outlined,
              color: AppColors.bluePrimary,
              size: 22,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  item.address,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSection,
                  ),
                ),
                if (item.description != null && item.description!.isNotEmpty)
                  Text(
                    item.description!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textEmpty,
                    ),
                  ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _handleCheckIn(item),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.bluePrimary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              elevation: 0,
            ),
            child: const Text(
              'Entrar',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _circle(double size, Color color) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}
