import 'dart:io';
import 'dart:ui' as ui;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../Models/gold_data.dart';
import '../../Services/api_services.dart';
import '../../Services/history_service.dart';
import 'detail_pivotpoin.dart';

const MethodChannel _downloadChannel = MethodChannel('pivot_point_downloader');

class PivotPointView extends StatefulWidget {
  const PivotPointView({super.key});

  @override
  State<PivotPointView> createState() => _PivotPointViewState();
}

class _PivotPointViewState extends State<PivotPointView> {
  final TextEditingController _openController = TextEditingController();
  final TextEditingController _highController = TextEditingController();
  final TextEditingController _lowController = TextEditingController();
  final TextEditingController _closeController = TextEditingController();
  bool _isAutoFromYesterday = true;
  bool _isLoadingHistorical = false;
  String? _historicalError;
  double _pp = 0, _r1 = 0, _r2 = 0, _r3 = 0, _r4 = 0;
  double _s1 = 0, _s2 = 0, _s3 = 0, _s4 = 0;
  String? _lastSavedPivotInputs;
  final GlobalKey _pivotReportKey = GlobalKey();

  Future<void> _downloadPivotReport() async {
    try {
      if (!Platform.isAndroid) {
        throw UnsupportedError('Fitur download saat ini hanya didukung untuk Android.');
      }

      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final sdkInt = androidInfo.version.sdkInt ?? 0;
      final permission = sdkInt >= 33 ? Permission.photos : Permission.storage;
      final status = await permission.status;

      if (!status.isGranted && !status.isLimited) {
        final requested = await permission.request();
        if (!requested.isGranted && !requested.isLimited) {
          if (!mounted) return;
          ScaffoldMessenger.maybeOf(context)?.showSnackBar(
            const SnackBar(
              content: Text(
                'Izin akses galeri ditolak. Silakan izinkan untuk menyimpan gambar.',
              ),
            ),
          );
          return;
        }
      }

      final renderObject = _pivotReportKey.currentContext?.findRenderObject();
      if (renderObject is! RenderRepaintBoundary) {
        throw Exception('Area hasil tidak dapat diproses.');
      }

      final image = await renderObject.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw Exception('File gambar gagal dibuat.');
      }

      final bytes = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final sourceFile = File(
        '${tempDir.path}/pivot_point_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await sourceFile.writeAsBytes(bytes);

      final saved = await _downloadChannel.invokeMethod<bool>(
        'saveImageToGallery',
        {'path': sourceFile.path},
      );

      if (saved == true) {
        if (!mounted) return;
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          const SnackBar(content: Text('Gambar pivot point berhasil disimpan ke galeri.')),
        );
        return;
      }

      throw Exception('Gagal menyimpan gambar ke galeri.');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text('Download gagal: $e')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    for (final controller in [
      _openController,
      _highController,
      _lowController,
      _closeController,
    ]) {
      controller.addListener(_calculatePivot);
    }
    _loadYesterdayData();
  }

  @override
  void dispose() {
    _openController.dispose();
    _highController.dispose();
    _lowController.dispose();
    _closeController.dispose();
    super.dispose();
  }

  double _parseNumber(String value) {
    final clean = value.trim();
    final commaCount = ','.allMatches(clean).length;
    final normalized =
        clean.contains('.') && clean.contains(',') || commaCount > 1
        ? clean.replaceAll(',', '')
        : clean.replaceAll(',', '.');
    return double.tryParse(normalized) ?? 0;
  }

  String _formatNumber(double value) {
    final parts = value.toStringAsFixed(2).split('.');
    final integer = parts[0].replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]},',
    );
    return '$integer.${parts[1]}';
  }

  DateTime? _parseDate(String value) {
    final clean = value.replaceAll('\u00a0', ' ').trim();
    try {
      if (clean.contains('-')) return DateTime.parse(clean);
      final parts = clean.split(RegExp(r'\s+'));
      if (parts.length != 3) return null;
      const months = {
        'jan': 1,
        'feb': 2,
        'mar': 3,
        'apr': 4,
        'may': 5,
        'jun': 6,
        'jul': 7,
        'aug': 8,
        'sep': 9,
        'oct': 10,
        'nov': 11,
        'dec': 12,
      };
      final month = months[parts[1].toLowerCase().substring(0, 3)];
      return month == null
          ? null
          : DateTime(int.parse(parts[2]), month, int.parse(parts[0]));
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadYesterdayData() async {
    setState(() {
      _isLoadingHistorical = true;
      _historicalError = null;
    });
    try {
      final records = await ApiService.getGoldHistory(maxPages: 10);
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      GoldHistory? selected;
      DateTime? selectedDate;
      for (final record in records) {
        final date = _parseDate(record.date);
        if (date == null || date.isAfter(yesterday)) continue;
        if (selectedDate == null || date.isAfter(selectedDate)) {
          selected = record;
          selectedDate = date;
        }
      }
      if (selected == null) throw Exception('Data kemarin tidak ditemukan');
      _openController.text = _formatNumber(selected.open);
      _highController.text = _formatNumber(selected.high);
      _lowController.text = _formatNumber(selected.low);
      _closeController.text = _formatNumber(selected.close);
      await _savePivotHistory();
      if (mounted) setState(() => _isLoadingHistorical = false);
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingHistorical = false;
          _historicalError = 'Data kemarin tidak dapat dimuat.';
        });
      }
    }
  }

  void _calculatePivot() {
    final high = _parseNumber(_highController.text);
    final low = _parseNumber(_lowController.text);
    final close = _parseNumber(_closeController.text);
    final range = high - low;
    if (!mounted) return;
    setState(() {
      _pp = (high + low + close) / 3;
      _r1 = 2 * _pp - low;
      _r2 = _pp + range;
      _r3 = _pp + range * 2;
      _r4 = _pp + range * 3;
      _s1 = 2 * _pp - high;
      _s2 = _pp - range;
      _s3 = _pp - range * 2;
      _s4 = _pp - range * 3;
    });
    if (!_isAutoFromYesterday) _savePivotHistory();
  }

  Future<void> _savePivotHistory() async {
    final open = _parseNumber(_openController.text);
    final high = _parseNumber(_highController.text);
    final low = _parseNumber(_lowController.text);
    final close = _parseNumber(_closeController.text);
    if (high == 0 || low == 0 || close == 0) return;

    final inputKey = '$open|$high|$low|$close';
    if (_lastSavedPivotInputs == inputKey) return;
    _lastSavedPivotInputs = inputKey;

    try {
      await HistoryService.saveCalculation(
        jenisKalkulator: 'Pivot Point',
        hasil: _pp,
        open: open,
        high: high,
        low: low,
        close: close,
        indikasi: close >= _pp ? 'BUY' : 'SELL',
      );
    } catch (_) {
      _lastSavedPivotInputs = null;
    }
  }

  void _toggleAuto(bool enabled) {
    setState(() => _isAutoFromYesterday = enabled);
    if (enabled) _loadYesterdayData();
  }

  void _resetToYesterday() {
    setState(() => _isAutoFromYesterday = true);
    _loadYesterdayData();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.zero,
      child: RepaintBoundary(
        key: _pivotReportKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Input Form Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    spreadRadius: 2,
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Transform.translate(
                        offset: const Offset(18, 0),
                        child: Opacity(
                          opacity: 0.50,
                          child: Image.asset(
                            'assets/ewf_logo.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            _isLoadingHistorical
                                ? 'Memuat data kemarin...'
                                : 'Otomatis kemarin',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Switch(
                            value: _isAutoFromYesterday,
                            onChanged: _toggleAuto,
                            activeThumbColor: const Color(0xFFD95B14),
                          ),
                        ],
                      ),
                      if (_historicalError != null)
                        Text(
                          _historicalError!,
                          style: const TextStyle(fontSize: 10, color: Colors.red),
                        ),
                      _buildInputField("Open", _openController),
                      const SizedBox(height: 12),
                      _buildInputField("High", _highController),
                      const SizedBox(height: 12),
                      _buildInputField("Low", _lowController),
                      const SizedBox(height: 12),
                      _buildInputField("Close", _closeController),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Indikasi / Hasil Akhir Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE8833A).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8833A),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      "Indikasi",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Hasil Pivot Point",
                    style: TextStyle(
                      color: Colors.brown,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 24,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFE8833A),
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      _formatNumber(_pp),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF8B2500),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.brown.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      _closeValue >= _pp ? "BUY" : "SELL",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF8B2500),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Tombol untuk memanggil Detail / Formula R4-S4
            DetailPivotPoint(
              pp: _pp,
              r1: _r1,
              r2: _r2,
              r3: _r3,
              r4: _r4,
              s1: _s1,
              s2: _s2,
              s3: _s3,
              s4: _s4,
              onReset: _resetToYesterday,
              onDownload: _downloadPivotReport,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller) {
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SizedBox(
            height: 42,
            child: TextField(
              controller: controller,
              enabled: !_isAutoFromYesterday,
              keyboardType: TextInputType.number,
              inputFormatters: [ThousandsDecimalFormatter()],
              textAlign: TextAlign.left,
              textAlignVertical: TextAlignVertical.center,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF888888)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF888888)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Color(0xFFD95B14),
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  double get _closeValue => _parseNumber(_closeController.text);
}

class ThousandsDecimalFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final value = newValue.text.replaceAll(',', '');
    if (value.isEmpty) return newValue.copyWith(text: '');

    final parts = value.split('.');
    if (parts.length > 2 || !RegExp(r'^\d*\.?\d*$').hasMatch(value)) {
      return oldValue;
    }

    final integer = parts.first;
    final formattedInteger = integer.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]},',
    );
    final formatted = parts.length == 1
        ? formattedInteger
        : '$formattedInteger.${parts[1]}';

    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
