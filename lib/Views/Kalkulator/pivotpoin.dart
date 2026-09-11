import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:pdf/pdf.dart' as pdf;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import '../../Models/historidata_model.dart';
import '../../Services/api_services.dart';
import '../../Services/history_service.dart';
import 'detail_pivotpoin.dart';

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
  String _selectedCategory = 'LGD';
  double _pp = 0, _r1 = 0, _r2 = 0, _r3 = 0, _r4 = 0;
  double _s1 = 0, _s2 = 0, _s3 = 0, _s4 = 0;
  bool _resultsVisible = true;
  String? _lastSavedPivotInputs;
  final GlobalKey _resultsKey = GlobalKey();

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

  String _formatResultDate() {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    final date = DateTime.now();
    return '${date.day} ${months[date.month - 1]} ${date.year}';
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
      final records = await ApiService.getGoldHistory(
        maxPages: 10,
        category: _selectedCategory,
      );
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
      _highController.text = _formatNumber(selected.high);
      _lowController.text = _formatNumber(selected.low);
      _closeController.text = _formatNumber(selected.close);
      try {
        final realtimeOpen = await ApiService.getTradingViewOpen(
          _selectedCategory,
        );
        _openController.text = _formatNumber(realtimeOpen);
      } catch (_) {
        _openController.text = _formatNumber(selected.open);
      }
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
    final open = _parseNumber(_openController.text);
    final high = _parseNumber(_highController.text);
    final low = _parseNumber(_lowController.text);
    final close = _parseNumber(_closeController.text);
    if (!_isAutoFromYesterday &&
        (open == 0 || high == 0 || low == 0 || close == 0)) {
      _clearPivotResults();
      return;
    }

    final range = high - low;
    if (!mounted) return;
    setState(() {
      _resultsVisible = true;
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

  void _clearPivotResults() {
    if (!mounted) return;
    setState(() {
      _resultsVisible = false;
      _pp = 0;
      _r1 = 0;
      _r2 = 0;
      _r3 = 0;
      _r4 = 0;
      _s1 = 0;
      _s2 = 0;
      _s3 = 0;
      _s4 = 0;
    });
  }

  Future<void> _savePivotHistory() async {
    final open = _parseNumber(_openController.text);
    final high = _parseNumber(_highController.text);
    final low = _parseNumber(_lowController.text);
    final close = _parseNumber(_closeController.text);
    if (high == 0 || low == 0 || close == 0) return;

    final inputKey = '$_selectedCategory|$open|$high|$low|$close';
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
        indikasi: _indication,
      );
    } catch (_) {
      _lastSavedPivotInputs = null;
    }
  }

  void _toggleAuto(bool enabled) {
    setState(() {
      _isAutoFromYesterday = enabled;
      _resultsVisible = enabled;
    });
    if (enabled) {
      _loadYesterdayData();
    } else {
      _openController.clear();
      _lastSavedPivotInputs = null;
      _clearPivotResults();
    }
  }

  void _resetToYesterday() {
    setState(() => _isAutoFromYesterday = true);
    _loadYesterdayData();
  }

  Future<void> _downloadAndShareResults() async {
    if (!mounted) return;
    final format = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text(
                'Download hasil',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.image_outlined),
              title: const Text('PNG'),
              subtitle: const Text('Simpan tampilan hasil sebagai gambar'),
              onTap: () => Navigator.pop(context, 'png'),
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined),
              title: const Text('PDF'),
              subtitle: const Text('Simpan ringkasan hasil sebagai PDF'),
              onTap: () => Navigator.pop(context, 'pdf'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || format == null) return;

    final directory = await getTemporaryDirectory();
    File file;
    if (format == 'png') {
      final boundary =
          _resultsKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 6);
      final exportImage = await _addPngBackground(image);
      final bytes = await exportImage.toByteData(
        format: ui.ImageByteFormat.png,
      );
      image.dispose();
      exportImage.dispose();
      if (bytes == null) return;
      file = File('${directory.path}/hasil_pivot_point.png');
      await file.writeAsBytes(bytes.buffer.asUint8List());
    } else {
      final document = pw.Document();
      document.addPage(
        pw.Page(
          margin: const pw.EdgeInsets.all(28),
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Hasil Pivot Point ORVIX',
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                  color: pdf.PdfColors.deepOrange,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                'Kategori: $_selectedCategory   |   ${DateTime.now().toLocal()}',
                style: const pw.TextStyle(fontSize: 10),
              ),
              pw.SizedBox(height: 18),
              _pdfTable('Input Data', [
                ['Open', _formatNumber(_openValue)],
                ['High', _formatNumber(_parseNumber(_highController.text))],
                ['Low', _formatNumber(_parseNumber(_lowController.text))],
                ['Close', _formatNumber(_parseNumber(_closeController.text))],
              ]),
              pw.SizedBox(height: 14),
              _pdfTable('Indikasi', [
                ['Hasil Pivot Point', _formatNumber(_pp)],
                ['Indikasi', _indication],
              ]),
              pw.SizedBox(height: 14),
              _pdfTable('Formula & Hasil', [
                ['Level', 'Formula', 'Hasil', 'Midpoint'],
                [
                  'R4',
                  'PP + (High - Low) x 3',
                  _formatNumber(_r4),
                  _formatNumber((_r4 + _r3) / 2),
                ],
                [
                  'R3',
                  'PP + (High - Low) x 2',
                  _formatNumber(_r3),
                  _formatNumber((_r3 + _r2) / 2),
                ],
                [
                  'R2',
                  'PP + (High - Low)',
                  _formatNumber(_r2),
                  _formatNumber((_r2 + _r1) / 2),
                ],
                [
                  'R1',
                  '2 x PP - Low',
                  _formatNumber(_r1),
                  _formatNumber((_r1 + _pp) / 2),
                ],
                [
                  'PP',
                  '(High + Low + Close) / 3',
                  _formatNumber(_pp),
                  _formatNumber((_pp + _s1) / 2),
                ],
                [
                  'S1',
                  '2 x PP - High',
                  _formatNumber(_s1),
                  _formatNumber((_s1 + _s2) / 2),
                ],
                [
                  'S2',
                  'PP - (High - Low)',
                  _formatNumber(_s2),
                  _formatNumber((_s2 + _s3) / 2),
                ],
                [
                  'S3',
                  'PP - (High - Low) x 2',
                  _formatNumber(_s3),
                  _formatNumber((_s3 + _s4) / 2),
                ],
                [
                  'S4',
                  'PP - (High - Low) x 3',
                  _formatNumber(_s4),
                  _formatNumber((_s4 + _s3) / 2),
                ],
              ]),
            ],
          ),
        ),
      );
      file = File('${directory.path}/hasil_pivot_point.pdf');
      await file.writeAsBytes(await document.save());
    }

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Hasil Pivot Point ${format.toUpperCase()}',
      text: 'Hasil kalkulasi Pivot Point ORVIX',
    );
  }

  Future<ui.Image> _addPngBackground(ui.Image image) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final size = Size(image.width.toDouble(), image.height.toDouble());
    final paint = Paint()
      ..shader = ui.Gradient.linear(
        Offset.zero,
        Offset(0, size.height),
        const [Color(0xFFEA8648), Color(0xFFFDF7F2)],
        const [0.0, 0.6],
      );
    canvas.drawRect(Offset.zero & size, paint);
    canvas.drawImage(image, Offset.zero, Paint());
    return recorder.endRecording().toImage(image.width, image.height);
  }

  pw.Widget _pdfTable(String title, List<List<String>> rows) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: double.infinity,
          color: pdf.PdfColors.deepOrange,
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: pw.Text(
            title,
            style: pw.TextStyle(
              color: pdf.PdfColors.white,
              fontWeight: pw.FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        pw.Table(
          border: pw.TableBorder.all(color: pdf.PdfColors.orange, width: 0.8),
          columnWidths: rows.first.length == 4
              ? {
                  0: const pw.FlexColumnWidth(0.8),
                  1: const pw.FlexColumnWidth(3),
                  2: const pw.FlexColumnWidth(1.4),
                  3: const pw.FlexColumnWidth(1.4),
                }
              : null,
          children: rows.asMap().entries.map((entry) {
            final isHeader = rows.first.length == 4 && entry.key == 0;
            return pw.TableRow(
              decoration: pw.BoxDecoration(
                color: isHeader
                    ? pdf.PdfColors.orange100
                    : entry.key.isEven
                    ? pdf.PdfColors.orange50
                    : pdf.PdfColors.white,
              ),
              children: entry.value
                  .map(
                    (value) => pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                        value,
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: isHeader
                              ? pw.FontWeight.bold
                              : pw.FontWeight.normal,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.zero,
      child: RepaintBoundary(
        key: _resultsKey,
        child: Container(
          color: Colors.transparent,
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 10, top: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Hasil Pivot Point',
                      style: TextStyle(
                        color: Color(0xFF8B2500),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _formatResultDate(),
                      style: const TextStyle(
                        color: Color(0xFF8B2500),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
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
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.red,
                            ),
                          ),
                        _buildCategorySelector(),
                        const SizedBox(height: 12),
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

              if (_resultsVisible) ...[
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
                          _indication,
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
                  onDownload: _downloadAndShareResults,
                ),
              ],
            ],
          ),
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

  String get _indication {
    final isOpenBelowPivot = _openValue < _pp;
    final isBuy = _selectedCategory == 'HSI'
        ? !isOpenBelowPivot
        : isOpenBelowPivot;
    return isBuy ? 'BUY' : 'SELL';
  }

  double get _openValue => _parseNumber(_openController.text);

  Widget _buildCategorySelector() {
    return Row(
      children: [
        const SizedBox(
          width: 60,
          child: Text(
            'Kategori',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: DropdownButtonFormField<String>(
            initialValue: _selectedCategory,
            isDense: true,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              filled: true,
              fillColor: Colors.white,
              constraints: const BoxConstraints.tightFor(height: 42),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF888888)),
              ),
            ),
            items: const [
              DropdownMenuItem(value: 'LGD', child: Text('LGD')),
              DropdownMenuItem(value: 'HSI', child: Text('HSI')),
            ],
            onChanged: _isLoadingHistorical
                ? null
                : (value) {
                    if (value == null || value == _selectedCategory) return;
                    setState(() {
                      _selectedCategory = value;
                      _isAutoFromYesterday = true;
                    });
                    _loadYesterdayData();
                  },
          ),
        ),
      ],
    );
  }
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
