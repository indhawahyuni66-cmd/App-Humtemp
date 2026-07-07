import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_database/firebase_database.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> with TickerProviderStateMixin {
  int _currentIndex = 0;

  // ── Sensor Suhu & Kelembapan ──
  double _temperature = 0.0;
  double _humidity = 0.0;
  String _statusRaw = 'SAFE';
  String _previousStatus = 'SAFE';

  // ── Sensor Air (dari node sensor_air) ──
  String _airKondisi = 'KONDISI KERING';
  int _airNilai = 0;
  String _airStatus = 'SAFE';
  String _airWarna = 'green';
  String _prevAirStatus = 'SAFE';
  bool _airPopupShown = false;

  bool _isLoading = true;
  String? _errorMessage;
  bool _popupShown = false;

  // ── Animation Controllers ──
  late AnimationController _pulseController;
  late AnimationController _thermometerController;
  late AnimationController _dropController;
  late AnimationController _waveController;

  late Animation<double> _pulseAnimation;
  late Animation<double> _thermometerAnimation;
  late Animation<double> _dropAnimation;
  late Animation<double> _waveAnimation;

  // ── Firebase Refs ──
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref('MD02');
  final DatabaseReference _sensorAirRef = FirebaseDatabase.instance.ref(
    'sensor_air',
  );

  // ── OneSignal ──
  static const String _oneSignalAppId = 'f2c1a619-50be-4deb-b3d1-7602cac3f8e1';
  static const String _oneSignalApiKey =
      'os_v2_app_6la2mgkqxzg6xm6roybmvq7y4e5umaacklseqffqoofjmijrhr2kpn7rfpnbn4cuxzm4thhymioh7xm26sbx4ugffydz24tw6ozkgry';

  static const int _adcMax = 1023;
  double get _airFill => (_airNilai / _adcMax).clamp(0.0, 1.0);

  //  INIT & DISPOSE
  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _thermometerController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..forward();

    _dropController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _waveController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _thermometerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _thermometerController, curve: Curves.easeOut),
    );
    _dropAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _dropController, curve: Curves.easeInOut),
    );
    _waveAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _waveController, curve: Curves.linear));

    _listenToFirebase();
    _listenToSensorAir();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _thermometerController.dispose();
    _dropController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  //  FIREBASE LISTENERS
  void _listenToFirebase() {
    _dbRef.onValue.listen(
      (DatabaseEvent event) {
        final data = event.snapshot.value;
        if (data != null && data is Map) {
          final map = Map<String, dynamic>.from(data);
          final newStatus = (map['status'] ?? 'SAFE').toString().toUpperCase();

          setState(() {
            _temperature = _toDouble(map['suhu']);
            _humidity = _toDouble(map['kelembapan']);
            _previousStatus = _statusRaw;
            _statusRaw = newStatus;
            _isLoading = false;
            _errorMessage = null;
          });

          _thermometerController
            ..reset()
            ..forward();

          if (newStatus != _previousStatus) _popupShown = false;

          if (!_popupShown &&
              (newStatus == 'WARNING' || newStatus == 'DANGER')) {
            _popupShown = true;
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) {
                _showStatusPopup(newStatus);
                _sendTempHumidNotification(newStatus);
              }
            });
          }
        }
      },
      onError: (error) {
        setState(() {
          _errorMessage = 'Gagal membaca data: $error';
          _isLoading = false;
        });
      },
    );
  }

  void _listenToSensorAir() {
    _sensorAirRef.onValue.listen(
      (DatabaseEvent event) {
        final data = event.snapshot.value;
        if (data != null && data is Map) {
          final map = Map<String, dynamic>.from(data);
          final newAirStatus = (map['status'] ?? 'SAFE')
              .toString()
              .toUpperCase();

          setState(() {
            _airKondisi = (map['kondisi'] ?? 'KONDISI KERING').toString();
            // Simpan nilai ADC langsung
            _airNilai = map['nilai'] is int
                ? map['nilai'] as int
                : _toDouble(map['nilai']).toInt();
            _airStatus = newAirStatus;
            _airWarna = (map['warna'] ?? 'green').toString();
            _isLoading = false;
          });

          if (newAirStatus != _prevAirStatus) _airPopupShown = false;
          _prevAirStatus = newAirStatus;

          if (!_airPopupShown &&
              (newAirStatus == 'WARNING' || newAirStatus == 'DANGER')) {
            _airPopupShown = true;
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) {
                _showAirStatusPopup(newAirStatus);
                _sendWaterNotification(newAirStatus);
              }
            });
          }
        }
      },
      onError: (error) {
        debugPrint('Error sensor_air: $error');
      },
    );
  }

  //  ONESIGNAL NOTIFICATIONS
  Future<void> _sendTempHumidNotification(String status) async {
    final isWarning = status == 'WARNING';
    final String title = isWarning
        ? '⚠️ Peringatan Sistem'
        : '🚨 Bahaya! Status Kritis';
    final String body = isWarning
        ? 'Suhu: ${_temperature.toStringAsFixed(1)}°C  |  '
              'Kelembapan: ${_humidity.toStringAsFixed(1)}%\n'
              'Perangkat perlu segera diperhatikan.'
        : 'Suhu: ${_temperature.toStringAsFixed(1)}°C  |  '
              'Kelembapan: ${_humidity.toStringAsFixed(1)}%\n'
              'Perangkat dalam kondisi BERBAHAYA!';

    await _postOneSignal(
      title: title,
      body: body,
      accentColor: isWarning ? 'FFF59E0B' : 'FFDC2626',
      channelId: 'temp_humid_channel',
      data: {
        'type': 'temp_humid',
        'status': status,
        'suhu': _temperature,
        'kelembapan': _humidity,
      },
    );
  }

  Future<void> _sendWaterNotification(String status) async {
    final isDanger = status == 'DANGER';
    final String title = isDanger
        ? '🚨 Bahaya! Genangan Kritis'
        : '⚠️ Peringatan Genangan Air';
    final String body = isDanger
        ? 'ODC terancam banjir! ADC: $_airNilai\n'
              'Kondisi: $_airKondisi — Segera ambil tindakan!'
        : 'Air mulai naik di area ODC. ADC: $_airNilai\n'
              'Kondisi: $_airKondisi — Pantau segera.';

    await _postOneSignal(
      title: title,
      body: body,
      accentColor: isDanger ? 'FFDC2626' : 'FFF59E0B',
      channelId: 'sensor_air_channel',
      data: {
        'type': 'sensor_air',
        'status': status,
        'nilai_adc': _airNilai,
        'kondisi': _airKondisi,
      },
    );
  }

  Future<void> _postOneSignal({
    required String title,
    required String body,
    required String accentColor,
    required String channelId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('https://onesignal.com/api/v1/notifications'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Key $_oneSignalApiKey',
        },
        body: jsonEncode({
          'app_id': _oneSignalAppId,
          'included_segments': ['All'],
          'headings': {'en': title, 'id': title},
          'contents': {'en': body, 'id': body},
          'android_accent_color': accentColor,
          'android_led_color': accentColor,
          'android_channel_id': channelId,
          'priority': 10,
          'ttl': 86400,
          'data': data,
        }),
      );
      if (response.statusCode == 200) {
        debugPrint('✅ Notif terkirim [$channelId]: $title');
      } else {
        debugPrint(
          '❌ OneSignal error [${response.statusCode}]: ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('❌ Gagal kirim notif: $e');
    }
  }

  //  COMPUTED GETTERS
  Color get _statusColor {
    switch (_statusRaw) {
      case 'WARNING':
        return const Color(0xFFF59E0B);
      case 'DANGER':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF16A34A);
    }
  }

  List<Color> get _statusGradient {
    switch (_statusRaw) {
      case 'WARNING':
        return [const Color(0xFFD97706), const Color(0xFFF59E0B)];
      case 'DANGER':
        return [const Color(0xFFB91C1C), const Color(0xFFDC2626)];
      default:
        return [const Color(0xFF16A34A), const Color(0xFF22C55E)];
    }
  }

  String get _statusText {
    switch (_statusRaw) {
      case 'WARNING':
        return 'WARNING';
      case 'DANGER':
        return 'DANGER';
      default:
        return 'SAFE';
    }
  }

  String get _statusDescription {
    switch (_statusRaw) {
      case 'SAFE':
        return 'Perangkat sistem dalam\nkondisi aman';
      case 'WARNING':
        return 'Perangkat perlu\ndiperhatikan';
      case 'DANGER':
        return 'Perangkat dalam\nkondisi berbahaya';
      default:
        return 'Status tidak diketahui';
    }
  }

  IconData get _statusIcon {
    switch (_statusRaw) {
      case 'WARNING':
        return Icons.warning_amber_rounded;
      case 'DANGER':
        return Icons.dangerous_outlined;
      default:
        return Icons.shield_outlined;
    }
  }

  Color get _airColor {
    switch (_airWarna.toLowerCase()) {
      case 'red':
        return const Color(0xFFDC2626);
      case 'yellow':
        return const Color(0xFFF59E0B);
      case 'orange':
        return const Color(0xFFEA580C);
      default:
        return const Color(0xFF0EA5E9);
    }
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  //  DIALOGS & POPUPS
  void _showStatusPopup(String status) {
    final isWarning = status == 'WARNING';
    final primaryColor = isWarning
        ? const Color(0xFFF59E0B)
        : const Color(0xFFDC2626);
    final bgColor = isWarning
        ? const Color(0xFFFFFBEB)
        : const Color(0xFFFEF2F2);
    final icon = isWarning
        ? Icons.warning_amber_rounded
        : Icons.dangerous_rounded;
    final title = isWarning ? '⚠️  Peringatan!' : '🚨  Bahaya!';
    final subtitle = isWarning
        ? 'Sistem mendeteksi kondisi yang perlu diperhatikan.'
        : 'Sistem mendeteksi kondisi BERBAHAYA! Segera ambil tindakan.';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(0.25),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 28),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: primaryColor, size: 38),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      title,
                      style: TextStyle(
                        color: primaryColor,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                child: Column(
                  children: [
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 14,
                        height: 1.6,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _dataChip(
                            icon: Icons.thermostat_rounded,
                            label: 'Suhu',
                            value: '${_temperature.toStringAsFixed(1)} °C',
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _dataChip(
                            icon: Icons.water_drop_outlined,
                            label: 'Kelembapan',
                            value: '${_humidity.toStringAsFixed(1)} %',
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: primaryColor.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        'STATUS: $status',
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: primaryColor.withOpacity(0.4),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          'Abaikan',
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _showStatusDialog();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          'Pantau',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAirStatusPopup(String status) {
    final isDanger = status == 'DANGER';
    final primary = isDanger
        ? const Color(0xFFDC2626)
        : const Color(0xFFF59E0B);
    final bgColor = isDanger
        ? const Color(0xFFFEF2F2)
        : const Color(0xFFFFFBEB);
    final icon = isDanger ? Icons.flood_rounded : Icons.water_damage_outlined;
    final title = isDanger ? '🚨  Bahaya Genangan!' : '⚠️  Air Mulai Naik!';
    final subtitle = isDanger
        ? 'Genangan kritis terdeteksi di area ODC!\nSegera lakukan penanganan.'
        : 'Tingkat air mulai naik di area ODC.\nPantau kondisi secara berkala.';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: primary.withOpacity(0.25),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 28),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: primary.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: primary, size: 38),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      title,
                      style: TextStyle(
                        color: primary,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                child: Column(
                  children: [
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 14,
                        height: 1.6,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _dataChip(
                            icon: Icons.water_rounded,
                            label: 'Nilai ADC',
                            value: '$_airNilai', // ← ADC langsung
                            color: primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _dataChip(
                            icon: Icons.water_drop_outlined,
                            label: 'Kondisi',
                            value: status == 'DANGER'
                                ? 'GENANGAN AIR TERDETEKSI'
                                : status == 'WARNING'
                                ? 'AIR TERDETEKSI'
                                : 'KONDISI KERING',
                            color: primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: primary.withOpacity(0.3)),
                      ),
                      child: Text(
                        'STATUS AIR: $status',
                        style: TextStyle(
                          color: primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: primary.withOpacity(0.4)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          'Abaikan',
                          style: TextStyle(
                            color: primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          'Pantau',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showStatusDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.info_outline, color: _statusColor),
            const SizedBox(width: 8),
            const Text('Status Sistem'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow('Status Sistem', _statusText),
            _infoRow('Suhu', '${_temperature.toStringAsFixed(1)} °C'),
            _infoRow('Kelembapan', '${_humidity.toStringAsFixed(1)} %'),
            const Divider(height: 20),
            _infoRow('Status Air', _airStatus),
            _infoRow('Nilai ADC', '$_airNilai'), // ← ADC langsung
            _infoRow('Kondisi', _airKondisi),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  //  REUSABLE WIDGETS
  Widget _dataChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF64748B))),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    ),
  );

  //  BUILD
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: Column(
                      children: [
                        _buildStatusCard(),
                        const SizedBox(height: 16),
                        _buildTemperatureCard(),
                        const SizedBox(height: 16),
                        _buildHumidityCard(),
                        const SizedBox(height: 16),
                        _buildWaterSensorCard(),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
          ),
          _buildBottomNav(),
        ],
      ),
    );
  }

  //  CARD WIDGETS
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E40AF), Color(0xFF2563EB), Color(0xFF3B82F6)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x402563EB),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Dashboard',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              GestureDetector(
                onTap: _showStatusDialog,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Stack(
                    children: [
                      const Icon(
                        Icons.notifications_outlined,
                        color: Colors.white,
                        size: 22,
                      ),
                      if (_statusRaw != 'SAFE' || _airStatus != 'SAFE')
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _statusRaw != 'SAFE'
                                  ? _statusColor
                                  : _airColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _statusGradient,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _statusColor.withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'STATUS',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) => Transform.scale(
                  scale: _statusRaw != 'SAFE' ? _pulseAnimation.value : 1.0,
                  child: Container(
                    width: 56,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(_statusIcon, color: Colors.white, size: 32),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        _statusText,
                        style: TextStyle(
                          color: _statusColor,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _statusDescription,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        height: 1.4,
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

  Widget _buildTemperatureCard() {
    final fillPercent = (_temperature / 50.0).clamp(0.0, 1.0);
    final tempColor = _temperature > 40
        ? const Color(0xFFEF4444)
        : _temperature > 30
        ? const Color(0xFFF97316)
        : const Color(0xFF3B82F6);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Temperature',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _temperature.toStringAsFixed(1),
                      style: TextStyle(
                        color: tempColor,
                        fontSize: 44,
                        fontWeight: FontWeight.bold,
                        height: 1.0,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 6),
                      child: Text(
                        ' °C',
                        style: TextStyle(
                          color: Color(0xFF1E293B),
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: fillPercent,
                    minHeight: 8,
                    backgroundColor: tempColor.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(tempColor),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Range: 0 – 50 °C',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          AnimatedBuilder(
            animation: _thermometerAnimation,
            builder: (context, child) => CustomPaint(
              size: const Size(48, 100),
              painter: ThermometerPainter(
                fillPercent: fillPercent * _thermometerAnimation.value,
                color: tempColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHumidityCard() {
    final fillPercent = (_humidity / 100.0).clamp(0.0, 1.0);
    final humidityColor = _humidity > 80
        ? const Color(0xFFEF4444)
        : const Color(0xFF0EA5E9);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Humidity',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _humidity.toStringAsFixed(1),
                      style: TextStyle(
                        color: humidityColor,
                        fontSize: 44,
                        fontWeight: FontWeight.bold,
                        height: 1.0,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 6),
                      child: Text(
                        ' %',
                        style: TextStyle(
                          color: Color(0xFF1E293B),
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: fillPercent,
                    minHeight: 8,
                    backgroundColor: humidityColor.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(humidityColor),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Range: 0 – 100 %',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          AnimatedBuilder(
            animation: _dropAnimation,
            builder: (context, child) => CustomPaint(
              size: const Size(72, 80),
              painter: HumidityPainter(
                animValue: _dropAnimation.value,
                color: humidityColor,
                humidity: fillPercent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Card Sensor Air — tampil nilai ADC langsung dari Firebase
  Widget _buildWaterSensorCard() {
    final Color wc = _airColor;

    Color badgeBg, badgeText;
    if (_airStatus == 'DANGER') {
      badgeBg = const Color(0xFFFEF2F2);
      badgeText = const Color(0xFFDC2626);
    } else if (_airStatus == 'WARNING') {
      badgeBg = const Color(0xFFFFFBEB);
      badgeText = const Color(0xFFD97706);
    } else {
      badgeBg = const Color(0xFFEFF6FF);
      badgeText = const Color(0xFF2563EB);
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: wc.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.water_rounded, color: wc, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sensor Air',
                        style: TextStyle(
                          color: Color(0xFF1E293B),
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Genangan ODC (manhole)',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Badge status
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: badgeText.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: badgeText,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _airStatus,
                      style: TextStyle(
                        color: badgeText,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Nilai ADC + water tank ──
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nilai ADC besar
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$_airNilai', // ← ADC langsung
                          style: TextStyle(
                            color: wc,
                            fontSize: 44,
                            fontWeight: FontWeight.bold,
                            height: 1.0,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(bottom: 6),
                          child: Text(
                            ' ADC',
                            style: TextStyle(
                              color: Color(0xFF1E293B),
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Nilai Sensor Air',
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Progress bar (visual saja, berdasar ADC/1023)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _airFill,
                        minHeight: 8,
                        backgroundColor: wc.withOpacity(0.15),
                        valueColor: AlwaysStoppedAnimation<Color>(wc),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Range: 0 – $_adcMax ADC',
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Chip kondisi
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: wc.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline_rounded, size: 14, color: wc),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _airKondisi,
                              style: TextStyle(
                                color: wc,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Animasi water tank (visual berdasar _airFill)
              AnimatedBuilder(
                animation: _waveAnimation,
                builder: (context, child) => CustomPaint(
                  size: const Size(72, 100),
                  painter: WaterTankPainter(
                    fillPercent: _airFill,
                    animValue: _waveAnimation.value,
                    color: wc,
                    adcValue: _airNilai, // ← tampilkan ADC di dalam tank
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    final items = [
      {'icon': Icons.grid_view_rounded, 'label': 'Home'},
      {'icon': Icons.history_rounded, 'label': 'History'},
      {'icon': Icons.person_outline_rounded, 'label': 'Profile'},
    ];
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              final isSelected = _currentIndex == index;
              return GestureDetector(
                onTap: () {
                  setState(() => _currentIndex = index);
                  if (index == 1) Navigator.pushNamed(context, '/History');
                  if (index == 2) Navigator.pushNamed(context, '/Userprofile');
                },
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF2563EB).withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        items[index]['icon'] as IconData,
                        color: isSelected
                            ? const Color(0xFF2563EB)
                            : const Color(0xFF94A3B8),
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        items[index]['label'] as String,
                        style: TextStyle(
                          color: isSelected
                              ? const Color(0xFF2563EB)
                              : const Color(0xFF94A3B8),
                          fontSize: 11,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  Custom Painters
// ══════════════════════════════════════════════════════════════════

class ThermometerPainter extends CustomPainter {
  final double fillPercent;
  final Color color;
  ThermometerPainter({required this.fillPercent, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const tubeWidth = 14.0;
    const bulbRadius = 14.0;
    final cx = size.width / 2;
    final bulbCy = size.height - bulbRadius;
    const tubeTop = 4.0;
    final tubeBottom = bulbCy - bulbRadius + 4;
    final tubeHeight = tubeBottom - tubeTop;

    final bgPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..style = PaintingStyle.fill;
    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final tubeRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(cx, tubeTop + tubeHeight / 2),
        width: tubeWidth,
        height: tubeHeight,
      ),
      Radius.circular(tubeWidth / 2),
    );
    canvas.drawRRect(tubeRect, bgPaint);

    final fillHeight = tubeHeight * fillPercent;
    if (fillHeight > 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(cx, tubeBottom - fillHeight / 2 + tubeWidth / 2 - 2),
            width: tubeWidth - 4,
            height: fillHeight,
          ),
          Radius.circular(tubeWidth / 2),
        ),
        fillPaint,
      );
    }
    canvas.drawRRect(tubeRect, strokePaint);

    final tickPaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..strokeWidth = 1.5;
    for (int i = 0; i <= 4; i++) {
      final y = tubeTop + (tubeHeight / 4) * i;
      canvas.drawLine(
        Offset(cx + tubeWidth / 2 + 2, y),
        Offset(cx + tubeWidth / 2 + 8, y),
        tickPaint,
      );
    }

    canvas.drawCircle(Offset(cx, bulbCy), bulbRadius, bgPaint);
    canvas.drawCircle(Offset(cx, bulbCy), bulbRadius - 2, fillPaint);
    canvas.drawCircle(Offset(cx, bulbCy), bulbRadius, strokePaint);
    canvas.drawCircle(
      Offset(cx - 3, bulbCy - 4),
      4,
      Paint()
        ..color = Colors.white.withOpacity(0.4)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(ThermometerPainter old) =>
      old.fillPercent != fillPercent || old.color != color;
}

class HumidityPainter extends CustomPainter {
  final double animValue;
  final Color color;
  final double humidity;
  HumidityPainter({
    required this.animValue,
    required this.color,
    required this.humidity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2 - 8;
    final dropPaint = Paint()
      ..color = color.withOpacity(0.15)
      ..style = PaintingStyle.fill;
    final dropFillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    _drawDrop(canvas, Offset(cx - 10, cy), 22, dropPaint);
    _drawDrop(canvas, Offset(cx - 10, cy), 22 * humidity, dropFillPaint);
    _drawDrop(canvas, Offset(cx + 16, cy + 8), 13, dropPaint);
    _drawDrop(canvas, Offset(cx + 16, cy + 8), 13 * humidity, dropFillPaint);
    _drawWave(canvas, size, animValue, color);
  }

  void _drawDrop(Canvas canvas, Offset center, double r, Paint paint) {
    if (r <= 0) return;
    final path = Path();
    final top = Offset(center.dx, center.dy - r * 1.4);
    path.moveTo(top.dx, top.dy);
    path.cubicTo(
      center.dx + r * 0.9,
      center.dy - r * 0.5,
      center.dx + r,
      center.dy + r * 0.2,
      center.dx,
      center.dy + r,
    );
    path.cubicTo(
      center.dx - r,
      center.dy + r * 0.2,
      center.dx - r * 0.9,
      center.dy - r * 0.5,
      top.dx,
      top.dy,
    );
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawWave(Canvas canvas, Size size, double t, Color color) {
    final waveY = size.height - 14.0;
    const amp = 4.0;
    final wl = size.width;

    final path1 = Path();
    path1.moveTo(0, waveY);
    for (double x = 0; x <= size.width; x++) {
      path1.lineTo(
        x,
        waveY + amp * math.sin((x / wl * 2 * math.pi) + t * 2 * math.pi),
      );
    }
    path1.lineTo(size.width, size.height);
    path1.lineTo(0, size.height);
    path1.close();
    canvas.drawPath(
      path1,
      Paint()
        ..color = color.withOpacity(0.25)
        ..style = PaintingStyle.fill,
    );

    final path2 = Path();
    path2.moveTo(0, waveY - 3);
    for (double x = 0; x <= size.width; x++) {
      path2.lineTo(
        x,
        waveY -
            3 +
            amp * math.sin((x / wl * 2 * math.pi) + (t + 0.5) * 2 * math.pi),
      );
    }
    path2.lineTo(size.width, size.height);
    path2.lineTo(0, size.height);
    path2.close();
    canvas.drawPath(
      path2,
      Paint()
        ..color = color.withOpacity(0.15)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(HumidityPainter old) =>
      old.animValue != animValue ||
      old.color != color ||
      old.humidity != humidity;
}

/// WaterTankPainter — menampilkan nilai ADC di dalam tank
class WaterTankPainter extends CustomPainter {
  final double fillPercent;
  final double animValue;
  final Color color;
  final int adcValue; // ← ADC langsung untuk label

  WaterTankPainter({
    required this.fillPercent,
    required this.animValue,
    required this.color,
    required this.adcValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    const rr = 10.0;

    final tankRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, w, h),
      const Radius.circular(rr),
    );
    canvas.drawRRect(
      tankRect,
      Paint()
        ..color = const Color(0xFFF1F5F9)
        ..style = PaintingStyle.fill,
    );

    if (fillPercent > 0) {
      canvas.save();
      canvas.clipRRect(tankRect);

      final waterTop = h * (1 - fillPercent);

      final path1 = Path();
      path1.moveTo(0, waterTop);
      for (double x = 0; x <= w; x++) {
        path1.lineTo(
          x,
          waterTop +
              math.sin((x / w * 2 * math.pi) + animValue * 2 * math.pi) * 4 +
              math.sin((x / w * math.pi) + animValue * 2 * math.pi * 0.7) * 2,
        );
      }
      path1.lineTo(w, h);
      path1.lineTo(0, h);
      path1.close();
      canvas.drawPath(
        path1,
        Paint()
          ..color = color.withOpacity(0.85)
          ..style = PaintingStyle.fill,
      );

      final path2 = Path();
      path2.moveTo(0, waterTop + 6);
      for (double x = 0; x <= w; x++) {
        path2.lineTo(
          x,
          waterTop +
              6 +
              math.sin(
                    (x / w * 2 * math.pi) + (animValue + 0.4) * 2 * math.pi,
                  ) *
                  3,
        );
      }
      path2.lineTo(w, h);
      path2.lineTo(0, h);
      path2.close();
      canvas.drawPath(
        path2,
        Paint()
          ..color = color.withOpacity(0.3)
          ..style = PaintingStyle.fill,
      );

      canvas.restore();
    }

    canvas.drawRRect(
      tankRect,
      Paint()
        ..color = const Color(0xFFCBD5E1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    final tickPaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..strokeWidth = 1.0;
    for (int i = 1; i <= 4; i++) {
      final y = (h / 4) * i;
      canvas.drawLine(Offset(w - 10, y), Offset(w - 4, y), tickPaint);
    }

    // Tampilkan nilai ADC di dalam tank
    final tp = TextPainter(
      text: TextSpan(
        text: '$adcValue',
        style: TextStyle(
          color: fillPercent > 0.45 ? Colors.white : color,
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset((w - tp.width) / 2, (h - tp.height) / 2));
  }

  @override
  bool shouldRepaint(WaterTankPainter old) =>
      old.fillPercent != fillPercent ||
      old.animValue != animValue ||
      old.color != color ||
      old.adcValue != adcValue;
}
