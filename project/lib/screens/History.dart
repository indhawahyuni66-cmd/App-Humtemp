import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';

class History extends StatefulWidget {
  const History({super.key});
  @override
  HistoryState createState() => HistoryState();
}

class HistoryState extends State<History> {
  int _currentIndex = 1;
  int _selectedChartTab = 0;
  String _selectedFilter = 'ALL';

  int _selectedMainTab = 0;

  List<Map<String, dynamic>> _historyList = [];
  List<Map<String, dynamic>> _historyAirList = [];
  bool _isLoading = true;
  String? _errorMessage;

  String _selectedAirFilter = 'ALL';

  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref('history');
  final DatabaseReference _dbAirRef = FirebaseDatabase.instance.ref(
    'history_air',
  );

  @override
  void initState() {
    super.initState();
    _listenToHistory();
    _listenToHistoryAir();
  }

  void _listenToHistory() {
    _dbRef.onValue.listen(
      (DatabaseEvent event) {
        final data = event.snapshot.value;
        List<Map<String, dynamic>> list = [];
        if (data != null && data is Map) {
          final map = Map<String, dynamic>.from(data);
          map.forEach((key, value) {
            if (value is Map) {
              final entry = Map<String, dynamic>.from(value);
              entry['_timestampKey'] = key.toString();
              list.add(entry);
            }
          });
          list.sort(
            (a, b) => b['_timestampKey'].toString().compareTo(
              a['_timestampKey'].toString(),
            ),
          );
        }
        setState(() {
          _historyList = list;
          _isLoading = false;
          _errorMessage = null;
        });
      },
      onError: (error) {
        setState(() {
          _errorMessage = 'Gagal membaca data: $error';
          _isLoading = false;
        });
      },
    );
  }

  void _listenToHistoryAir() {
    _dbAirRef.onValue.listen((DatabaseEvent event) {
      final data = event.snapshot.value;
      List<Map<String, dynamic>> list = [];
      if (data != null && data is Map) {
        final map = Map<String, dynamic>.from(data);
        map.forEach((key, value) {
          if (value is Map) {
            final entry = Map<String, dynamic>.from(value);
            entry['_timestampKey'] = key.toString();
            list.add(entry);
          }
        });
        list.sort(
          (a, b) => b['_timestampKey'].toString().compareTo(
            a['_timestampKey'].toString(),
          ),
        );
      }
      setState(() {
        _historyAirList = list;
      });
    });
  }

  // nilai adc langsung dari firebase, gak diubah ke persen
  double _airValueAdc(dynamic value) {
    return _toDouble(value);
  }

  Color _airWarnaColor(String warna) {
    switch (warna.toLowerCase()) {
      case 'green':
        return const Color(0xFF3A9C4C);
      case 'yellow':
        return const Color(0xFFF59E0B);
      case 'orange':
        return const Color(0xFFEA580C);
      case 'red':
        return const Color(0xFFD54A4D);
      default:
        return const Color(0xFF0EA5E9);
    }
  }

  String _airWarnaLabel(String warna) {
    switch (warna.toLowerCase()) {
      case 'green':
        return 'SAFE';
      case 'yellow':
        return 'WARNING';
      case 'orange':
        return 'ALERT';
      case 'red':
        return 'DANGER';
      default:
        return warna.toUpperCase();
    }
  }

  List<Map<String, dynamic>> get _filteredAirList {
    if (_selectedAirFilter == 'ALL') return _historyAirList;
    return _historyAirList.where((e) {
      final warna = (e['warna'] ?? 'green').toString().toLowerCase();
      return warna == _selectedAirFilter.toLowerCase();
    }).toList();
  }

  int _countAirByWarna(String warna) {
    if (warna == 'ALL') return _historyAirList.length;
    return _historyAirList
        .where(
          (e) =>
              (e['warna'] ?? 'green').toString().toLowerCase() ==
              warna.toLowerCase(),
        )
        .length;
  }

  void _deleteOldData() async {
    final now = DateTime.now();
    final List<String> toDelete = [];
    final sourceList = _selectedMainTab == 0 ? _historyList : _historyAirList;
    final refPath = _selectedMainTab == 0 ? 'history' : 'history_air';

    for (final entry in sourceList) {
      final tsKey = entry['_timestampKey'] ?? '';
      try {
        final dt = DateTime.parse(tsKey.replaceAll('_', ' '));
        if (now.difference(dt).inDays >= 7) toDelete.add(tsKey);
      } catch (_) {}
    }

    if (toDelete.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No old data to delete'),
          backgroundColor: Color(0xFF3A9C4C),
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.delete_sweep_rounded, color: Color(0xFFD54A4D)),
            SizedBox(width: 8),
            Text(
              'Delete Old Data',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Text(
          '${toDelete.length} data older than 7 days will be permanently deleted.\n\nContinue?',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF94A3B8)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD54A4D),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    for (final key in toDelete) {
      await FirebaseDatabase.instance.ref('$refPath/$key').remove();
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${toDelete.length} data deleted successfully'),
          backgroundColor: const Color(0xFF3A9C4C),
        ),
      );
    }
  }

  List<Map<String, dynamic>> get _filteredList {
    if (_selectedFilter == 'ALL') return _historyList;
    return _historyList
        .where(
          (e) =>
              (e['status'] ?? 'SAFE').toString().toUpperCase() ==
              _selectedFilter,
        )
        .toList();
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'SAFE':
        return const Color(0xFF3A9C4C);
      case 'WARNING':
        return const Color(0xFFF59E0B);
      case 'DANGER':
        return const Color(0xFFD54A4D);
      default:
        return const Color(0xFF3A9C4C);
    }
  }

  String _getDayName(String tsKey) {
    try {
      final dt = DateTime.parse(tsKey.replaceAll('_', ' '));
      const days = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ];
      return days[dt.weekday - 1];
    } catch (_) {
      return '-';
    }
  }

  String _getDate(String tsKey) {
    try {
      final dt = DateTime.parse(tsKey.replaceAll('_', ' '));
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return tsKey;
    }
  }

  String _getTime(String tsKey) {
    try {
      final dt = DateTime.parse(tsKey.replaceAll('_', ' '));
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  int _countByStatus(String status) {
    if (status == 'ALL') return _historyList.length;
    return _historyList
        .where(
          (e) => (e['status'] ?? 'SAFE').toString().toUpperCase() == status,
        )
        .length;
  }

  List<Map<String, dynamic>> get _chartData {
    final recent = _historyList.take(50).toList();
    return recent.reversed.toList();
  }

  List<FlSpot> _buildSpots(bool isSuhu) {
    return _chartData.asMap().entries.map((e) {
      final val = isSuhu
          ? _toDouble(e.value['suhu'])
          : _toDouble(e.value['kelembapan']);
      return FlSpot(e.key.toDouble(), val);
    }).toList();
  }

  List<Map<String, dynamic>> get _airChartData {
    final recent = _historyAirList.take(50).toList();
    return recent.reversed.toList();
  }

  List<FlSpot> _buildAirSpots() {
    return _airChartData.asMap().entries.map((e) {
      final val = _toDouble(e.value['nilai']);
      return FlSpot(e.key.toDouble(), val);
    }).toList();
  }

  double get _airChartMinY {
    if (_airChartData.isEmpty) return 0;
    final values = _airChartData.map((e) => _toDouble(e['nilai']));
    return (values.reduce((a, b) => a < b ? a : b) - 50).clamp(
      0,
      double.infinity,
    );
  }

  double get _airChartMaxY {
    if (_airChartData.isEmpty) return 1024;
    final values = _airChartData.map((e) => _toDouble(e['nilai']));
    return values.reduce((a, b) => a > b ? a : b) + 50;
  }

  double get _chartMinY {
    if (_chartData.isEmpty) return 0;
    final isSuhu = _selectedChartTab == 0;
    final values = _chartData.map(
      (e) => _toDouble(isSuhu ? e['suhu'] : e['kelembapan']),
    );
    return (values.reduce((a, b) => a < b ? a : b) - 5).clamp(
      0,
      double.infinity,
    );
  }

  double get _chartMaxY {
    if (_chartData.isEmpty) return 100;
    final isSuhu = _selectedChartTab == 0;
    final values = _chartData.map(
      (e) => _toDouble(isSuhu ? e['suhu'] : e['kelembapan']),
    );
    return values.reduce((a, b) => a > b ? a : b) + 5;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF2563EB)),
                  )
                : _errorMessage != null
                ? _buildErrorState()
                : Column(
                    children: [
                      _buildMainTabBar(),
                      Expanded(
                        child: _selectedMainTab == 0
                            ? _buildSuhuContent()
                            : _buildAirContent(),
                      ),
                    ],
                  ),
          ),
          _buildBottomNav(),
        ],
      ),
    );
  }

  Widget _buildMainTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3629B7).withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildMainTab(0, 'Temp & Humidity', Icons.thermostat_rounded),
          _buildMainTab(1, 'Water Sensor', Icons.water_rounded),
        ],
      ),
    );
  }

  Widget _buildMainTab(int index, String label, IconData icon) {
    final isActive = _selectedMainTab == index;
    final color = index == 0
        ? const Color(0xFF2563EB)
        : const Color(0xFF0EA5E9);
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedMainTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isActive ? Colors.white : const Color(0xFF94A3B8),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.normal,
                  color: isActive ? Colors.white : const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuhuContent() {
    if (_historyList.isEmpty) return _buildEmptyState('suhu');
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        _buildChartSection(),
        const SizedBox(height: 20),
        _buildFilterSection(),
        const SizedBox(height: 16),
        if (_filteredList.isEmpty)
          _buildEmptyFilter(_selectedFilter, false)
        else
          ..._filteredList.map((e) => _buildHistoryCard(e)),
      ],
    );
  }

  Widget _buildAirContent() {
    if (_historyAirList.isEmpty) return _buildEmptyState('air');
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        _buildAirChartSection(),
        const SizedBox(height: 20),
        _buildAirFilterSection(),
        const SizedBox(height: 16),
        if (_filteredAirList.isEmpty)
          _buildEmptyFilter(_selectedAirFilter, true)
        else
          ..._filteredAirList.map((e) => _buildAirCard(e)),
      ],
    );
  }

  // grafik sensor air (adc)
  Widget _buildAirChartSection() {
    const chartColor = Color(0xFF0EA5E9);
    final latestVal = _historyAirList.isNotEmpty
        ? _toDouble(_historyAirList.first['nilai'])
        : 0.0;
    final latestWarna = _historyAirList.isNotEmpty
        ? (_historyAirList.first['warna'] ?? 'green').toString()
        : 'green';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0EA5E9).withOpacity(0.10),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Water Sensor Chart',
                    style: TextStyle(
                      color: Color(0xFF0C4A6E),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '${_airChartData.length} data · ADC value',
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: chartColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.water_rounded,
                          size: 14,
                          color: chartColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${latestVal.toInt()} ADC',
                          style: const TextStyle(
                            color: chartColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      _airWarnaLabel(latestWarna),
                      style: TextStyle(
                        color: _airWarnaColor(latestWarna),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: _airChartData.length < 2
                ? const Center(
                    child: Text(
                      'Need at least 2 data points for chart',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                    ),
                  )
                : LineChart(
                    LineChartData(
                      minY: _airChartMinY,
                      maxY: _airChartMaxY,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval:
                            ((_airChartMaxY - _airChartMinY) / 4).clamp(
                              1,
                              9999,
                            ),
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: const Color(0xFFF1F5F9),
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 50,
                            interval: ((_airChartMaxY - _airChartMinY) / 4)
                                .clamp(1, 9999),
                            getTitlesWidget: (value, meta) => Text(
                              '${value.toInt()}',
                              style: const TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            interval: (_airChartData.length / 5)
                                .clamp(1, 999)
                                .ceilToDouble(),
                            getTitlesWidget: (value, meta) {
                              final idx = value.toInt();
                              if (idx < 0 || idx >= _airChartData.length)
                                return const SizedBox();
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  _getTime(
                                    _airChartData[idx]['_timestampKey'] ?? '',
                                  ),
                                  style: const TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 9,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipItems: (spots) => spots.map((s) {
                            final idx = s.x.toInt();
                            final timeStr = idx < _airChartData.length
                                ? _getTime(
                                    _airChartData[idx]['_timestampKey'] ?? '',
                                  )
                                : '';
                            return LineTooltipItem(
                              '${s.y.toInt()} ADC\n$timeStr',
                              const TextStyle(
                                color: chartColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: _buildAirSpots(),
                          isCurved: true,
                          curveSmoothness: 0.35,
                          color: chartColor,
                          barWidth: 2.5,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, bar, index) {
                              final isEdge =
                                  index == 0 ||
                                  index == _airChartData.length - 1;
                              return FlDotCirclePainter(
                                radius: isEdge ? 4 : 2,
                                color: Colors.white,
                                strokeWidth: isEdge ? 2.5 : 1.5,
                                strokeColor: chartColor,
                              );
                            },
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                chartColor.withOpacity(0.18),
                                chartColor.withOpacity(0.0),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 24,
                height: 3,
                decoration: BoxDecoration(
                  color: chartColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Water Sensor ADC · ${_airChartData.length} points',
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // filter sensor air
  Widget _buildAirFilterSection() {
    final filters = [
      {
        'key': 'ALL',
        'label': 'All',
        'icon': Icons.list_rounded,
        'warna': 'all',
      },
      {
        'key': 'green',
        'label': 'Safe',
        'icon': Icons.check_circle_outline_rounded,
        'warna': 'green',
      },
      {
        'key': 'yellow',
        'label': 'Warning',
        'icon': Icons.warning_amber_rounded,
        'warna': 'yellow',
      },
      {
        'key': 'red',
        'label': 'Danger',
        'icon': Icons.dangerous_rounded,
        'warna': 'red',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Filter Water Status',
              style: TextStyle(
                color: Color(0xFF0C4A6E),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Text(
              '${_filteredAirList.length} data',
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: filters.map((f) {
            final key = f['key'] as String;
            final isActive = _selectedAirFilter == key;
            final count = _countAirByWarna(key);
            final color = key == 'ALL'
                ? const Color(0xFF0EA5E9)
                : _airWarnaColor(key);
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedAirFilter = key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: EdgeInsets.only(right: key != 'red' ? 8 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isActive ? color : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isActive ? color : const Color(0xFFE4E9F2),
                      width: 1.5,
                    ),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: color.withOpacity(0.25),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : [],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        f['icon'] as IconData,
                        size: 18,
                        color: isActive ? Colors.white : color,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        f['label'] as String,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isActive ? Colors.white : color,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: isActive
                              ? Colors.white.withOpacity(0.9)
                              : const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // card sensor air
  Widget _buildAirCard(Map<String, dynamic> entry) {
    final nilaiAdc = _airValueAdc(entry['nilai']);
    final warna = (entry['warna'] ?? 'green').toString();
    // ambil field kondisi dari firebase, kalau gak ada pakai status
    final kondisiRaw = (entry['kondisi'] ?? entry['status'] ?? '-').toString();
    final tsKey = entry['_timestampKey'] ?? '';

    final dayName = _getDayName(tsKey);
    final date = _getDate(tsKey);
    final time = _getTime(tsKey);
    final color = _airWarnaColor(warna);
    final warnaLabel = _airWarnaLabel(warna);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.15), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0EA5E9).withOpacity(0.07),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // baris 1: hari + waktu + tanggal
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dayName,
                style: const TextStyle(
                  color: Color(0xFF333333),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Row(
                children: [
                  if (time.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2FE),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.access_time_rounded,
                            size: 10,
                            color: Color(0xFF0EA5E9),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            time,
                            style: const TextStyle(
                              color: Color(0xFF0EA5E9),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F4FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      date,
                      style: const TextStyle(
                        color: Color(0xFF979797),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),
          // baris 2: nilai adc + status
          Row(
            children: [
              const Text(
                'ADC Value',
                style: TextStyle(color: Color(0xFF979797), fontSize: 12),
              ),
              const SizedBox(width: 8),
              Text(
                '${nilaiAdc.toInt()}',
                style: const TextStyle(
                  color: Color(0xFF0EA5E9),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              const Text(
                'Status',
                style: TextStyle(color: Color(0xFF979797), fontSize: 12),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: color.withOpacity(0.3), width: 1),
                ),
                child: Text(
                  warnaLabel,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // baris 3: condition, dari field kondisi di firebase
          Row(
            children: [
              const Text(
                'Condition',
                style: TextStyle(color: Color(0xFF979797), fontSize: 12),
              ),
              const SizedBox(width: 24),
              Text(
                kondisiRaw, // contoh isinya: "AIR TERDETEKSI" atau "TIDAK ADA AIR"
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    final filters = [
      {'key': 'ALL', 'label': 'All', 'icon': Icons.list_rounded},
      {
        'key': 'SAFE',
        'label': 'Safe',
        'icon': Icons.check_circle_outline_rounded,
      },
      {
        'key': 'WARNING',
        'label': 'Warning',
        'icon': Icons.warning_amber_rounded,
      },
      {'key': 'DANGER', 'label': 'Danger', 'icon': Icons.dangerous_rounded},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Filter Status',
              style: TextStyle(
                color: Color(0xFF1E3A8A),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Text(
              '${_filteredList.length} data',
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: filters.map((f) {
            final key = f['key'] as String;
            final isActive = _selectedFilter == key;
            final count = _countByStatus(key);
            Color color;
            switch (key) {
              case 'SAFE':
                color = const Color(0xFF3A9C4C);
                break;
              case 'WARNING':
                color = const Color(0xFFF59E0B);
                break;
              case 'DANGER':
                color = const Color(0xFFD54A4D);
                break;
              default:
                color = const Color(0xFF2563EB);
            }
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedFilter = key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: EdgeInsets.only(right: key != 'DANGER' ? 8 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isActive ? color : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isActive ? color : const Color(0xFFE4E9F2),
                      width: 1.5,
                    ),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: color.withOpacity(0.25),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : [],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        f['icon'] as IconData,
                        size: 18,
                        color: isActive ? Colors.white : color,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        f['label'] as String,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isActive ? Colors.white : color,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: isActive
                              ? Colors.white.withOpacity(0.9)
                              : const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildEmptyFilter(String filter, bool isAir) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 40,
            color: isAir ? const Color(0xFF0EA5E9) : _statusColor(filter),
          ),
          const SizedBox(height: 12),
          Text(
            'No ${isAir ? "water " : ""}$filter data found',
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartSection() {
    final isSuhu = _selectedChartTab == 0;
    final chartColor = isSuhu
        ? const Color(0xFFFF4267)
        : const Color(0xFF2563EB);
    final unit = isSuhu ? '°C' : '%';
    final label = isSuhu ? 'Temperature' : 'Humidity';
    final latestVal = _historyList.isNotEmpty
        ? _toDouble(
            isSuhu
                ? _historyList.first['suhu']
                : _historyList.first['kelembapan'],
          )
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3629B7).withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Realtime Chart',
                    style: TextStyle(
                      color: Color(0xFF1E3A8A),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '${_chartData.length} data · updates every 5s',
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: chartColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSuhu
                          ? Icons.thermostat_rounded
                          : Icons.water_drop_rounded,
                      size: 14,
                      color: chartColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${latestVal.toStringAsFixed(1)} $unit',
                      style: TextStyle(
                        color: chartColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F4FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _buildChartTab(0, 'Temperature', Icons.thermostat_rounded),
                _buildChartTab(1, 'Humidity', Icons.water_drop_rounded),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: _chartData.length < 2
                ? const Center(
                    child: Text(
                      'Need at least 2 data points for chart',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                    ),
                  )
                : LineChart(
                    LineChartData(
                      minY: _chartMinY,
                      maxY: _chartMaxY,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: ((_chartMaxY - _chartMinY) / 4)
                            .clamp(1, 999),
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: const Color(0xFFF1F5F9),
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            interval: ((_chartMaxY - _chartMinY) / 4).clamp(
                              1,
                              999,
                            ),
                            getTitlesWidget: (value, meta) => Text(
                              '${value.toInt()}$unit',
                              style: const TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            interval: (_chartData.length / 5)
                                .clamp(1, 999)
                                .ceilToDouble(),
                            getTitlesWidget: (value, meta) {
                              final idx = value.toInt();
                              if (idx < 0 || idx >= _chartData.length)
                                return const SizedBox();
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  _getTime(
                                    _chartData[idx]['_timestampKey'] ?? '',
                                  ),
                                  style: const TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 9,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipItems: (spots) => spots.map((s) {
                            final idx = s.x.toInt();
                            final timeStr = idx < _chartData.length
                                ? _getTime(
                                    _chartData[idx]['_timestampKey'] ?? '',
                                  )
                                : '';
                            return LineTooltipItem(
                              '${s.y.toStringAsFixed(1)} $unit\n$timeStr',
                              TextStyle(
                                color: chartColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: _buildSpots(isSuhu),
                          isCurved: true,
                          curveSmoothness: 0.35,
                          color: chartColor,
                          barWidth: 2.5,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, bar, index) {
                              final isEdge =
                                  index == 0 || index == _chartData.length - 1;
                              return FlDotCirclePainter(
                                radius: isEdge ? 4 : 2,
                                color: Colors.white,
                                strokeWidth: isEdge ? 2.5 : 1.5,
                                strokeColor: chartColor,
                              );
                            },
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                chartColor.withOpacity(0.18),
                                chartColor.withOpacity(0.0),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 24,
                height: 3,
                decoration: BoxDecoration(
                  color: chartColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '$label · ${_chartData.length} points · every 5s',
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartTab(int index, String label, IconData icon) {
    final isActive = _selectedChartTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedChartTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: isActive
                    ? (index == 0
                          ? const Color(0xFFFF4267)
                          : const Color(0xFF2563EB))
                    : const Color(0xFF94A3B8),
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.normal,
                  color: isActive
                      ? (index == 0
                            ? const Color(0xFFFF4267)
                            : const Color(0xFF2563EB))
                      : const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> entry) {
    final suhu = _toDouble(entry['suhu']);
    final kelembapan = _toDouble(entry['kelembapan']);
    final statusRaw = (entry['status'] ?? 'SAFE').toString().toUpperCase();
    final tsKey = entry['_timestampKey'] ?? '';
    final dayName = _getDayName(tsKey);
    final date = _getDate(tsKey);
    final time = _getTime(tsKey);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _statusColor(statusRaw).withOpacity(0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3629B7).withOpacity(0.07),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dayName,
                style: const TextStyle(
                  color: Color(0xFF333333),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Row(
                children: [
                  if (time.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.access_time_rounded,
                            size: 10,
                            color: Color(0xFF2563EB),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            time,
                            style: const TextStyle(
                              color: Color(0xFF2563EB),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F4FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      date,
                      style: const TextStyle(
                        color: Color(0xFF979797),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text(
                'Temperature',
                style: TextStyle(color: Color(0xFF979797), fontSize: 12),
              ),
              const SizedBox(width: 8),
              Text(
                '${suhu.toStringAsFixed(1)} °C',
                style: const TextStyle(
                  color: Color(0xFFFF4267),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              const Text(
                'Status',
                style: TextStyle(color: Color(0xFF979797), fontSize: 12),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _statusColor(statusRaw).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: _statusColor(statusRaw).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  statusRaw,
                  style: TextStyle(
                    color: _statusColor(statusRaw),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Text(
                'Humidity',
                style: TextStyle(color: Color(0xFF979797), fontSize: 12),
              ),
              const SizedBox(width: 36),
              Text(
                '${kelembapan.toStringAsFixed(1)} %',
                style: const TextStyle(
                  color: Color(0xFF3629B6),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String type) {
    final isAir = type == 'air';
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFFF0F4FF),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isAir ? Icons.water_rounded : Icons.history_rounded,
              size: 48,
              color: const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isAir ? 'No water sensor history yet' : 'No history data yet',
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isAir
                ? 'Data will appear once the water sensor\nsends data to Firebase'
                : 'Data will appear once the device\nsends data to Firebase',
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              size: 48,
              color: Color(0xFF94A3B8),
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final isAirTab = _selectedMainTab == 1;
    final headerColors = isAirTab
        ? const [Color(0xFF0C4A6E), Color(0xFF075985), Color(0xFF0EA5E9)]
        : const [Color(0xFF1E3A8A), Color(0xFF1E40AF), Color(0xFF2563EB)];
    final currentList = isAirTab ? _historyAirList : _historyList;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: headerColors,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x501E40AF),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    isAirTab ? 'Water Sensor History' : 'Data History',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              if (!_isLoading) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    GestureDetector(
                      onTap: _deleteOldData,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.delete_sweep_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Delete >7 days',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${currentList.length} data',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
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
            color: Colors.black.withOpacity(0.07),
            blurRadius: 20,
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
                  if (index == 0) {
                    Navigator.pushReplacementNamed(context, '/Dashboard');
                  } else if (index == 2) {
                    Navigator.pushNamed(context, '/Userprofile');
                  }
                },
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeInOut,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF2563EB).withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
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
                              ? FontWeight.w700
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