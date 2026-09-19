import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart' as pdf;
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import '../main_screen.dart';
import '../../Models/historidata_model.dart';
import '../../Services/api_services.dart';
import '../../Services/history_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ORVIX Kalkulator',
      theme: ThemeData(fontFamily: 'Sans-Serif'),
      home: const OrvixKalkulatorScreen(),
    );
  }
}

class OrvixKalkulatorScreen extends StatefulWidget {
  final bool showBottomNavigation;

  const OrvixKalkulatorScreen({super.key, this.showBottomNavigation = true});

  @override
  State<OrvixKalkulatorScreen> createState() => _OrvixKalkulatorScreenState();
}

class _OrvixKalkulatorScreenState extends State<OrvixKalkulatorScreen> {
  int _selectedTopTab = 2; // 0: Emas Fisik, 1: Pivot Point, 2: Nest
  final int _selectedNavIndex =
      1; // 0: Home, 1: Calculate, 2: History, 3: Profil
  bool _isAuto = true;
  bool _isLoadingAuto = false;

  final TextEditingController _openController = TextEditingController();
  final TextEditingController _closeController = TextEditingController();
  double _nestValue = 0;
  String _action = '-';
  String? _saveError;
  String? _lastSavedNestInput;
  final GlobalKey _resultsKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadAutomaticData();
  }

  @override
  void dispose() {
    _openController.dispose();
    _closeController.dispose();
    super.dispose();
  }

  double _parseNumber(String value) {
    return double.tryParse(value.replaceAll(',', '').trim()) ?? 0;
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
    final parsed = DateTime.tryParse(value);
    if (parsed != null) return parsed;
    final parts = value.trim().split(RegExp(r'[-/]'));
    if (parts.length != 3) return null;
    final first = int.tryParse(parts[0]);
    final second = int.tryParse(parts[1]);
    final third = int.tryParse(parts[2]);
    if (first == null || second == null || third == null) return null;
    return first > 31
        ? DateTime(first, second, third)
        : DateTime(third, second, first);
  }

  Future<void> _loadAutomaticData() async {
    if (!_isAuto) return;
    setState(() {
      _isLoadingAuto = true;
      _saveError = null;
    });
    try {
      final records = await ApiService.getGoldHistory(category: 'LGD');
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      GoldHistory? latest;
      DateTime? latestDate;
      for (final record in records) {
        final date = _parseDate(record.date);
        if (date == null || date.isAfter(yesterday)) continue;
        if (latestDate == null || date.isAfter(latestDate)) {
          latest = record;
          latestDate = date;
        }
      }
      if (latest == null || latest.close <= 0) {
        throw Exception('Close historical tidak tersedia');
      }
      final liveOpen = await ApiService.getTodayOpenFromNewsMaker('LGD');
      if (!mounted || !_isAuto) return;
      _openController.text = _formatNumber(liveOpen);
      _closeController.text = _formatNumber(latest.close);
      _calculateNest();
    } catch (_) {
      if (mounted) {
        setState(() => _saveError = 'Data otomatis Open/Close belum tersedia.');
      }
    } finally {
      if (mounted) setState(() => _isLoadingAuto = false);
    }
  }

  void _toggleAutomatic(bool enabled) {
    setState(() {
      _isAuto = enabled;
      _saveError = null;
      if (!enabled) _lastSavedNestInput = null;
    });
    if (enabled) _loadAutomaticData();
  }

  void _calculateNest() {
    final open = _parseNumber(_openController.text);
    final close = _parseNumber(_closeController.text);
    final action = open == 0 || close == 0
        ? '-'
        : close > open
        ? 'BUY'
        : 'SELL';
    setState(() {
      _nestValue = close;
      _action = action;
      _saveError = null;
    });
    if (action != '-') _saveNestHistory(open, close, action);
  }

  Future<void> _saveNestHistory(
    double open,
    double close,
    String action,
  ) async {
    final inputKey = '$open|$close|$action';
    if (_lastSavedNestInput == inputKey) return;
    _lastSavedNestInput = inputKey;
    try {
      await HistoryService.saveCalculation(
        jenisKalkulator: 'NEST',
        hasil: close,
        open: open,
        close: close,
        indikasi: action,
      );
    } catch (_) {
      _lastSavedNestInput = null;
      if (mounted) {
        setState(
          () => _saveError =
              'Histori NEST belum tersimpan. Pastikan sudah login.',
        );
      }
    }
  }

  Future<void> _downloadAndShareResults() async {
    final open = _parseNumber(_openController.text);
    final close = _parseNumber(_closeController.text);
    if (open == 0 || close == 0 || _action == '-') {
      setState(() => _saveError = 'Isi Open dan Close terlebih dahulu.');
      return;
    }
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
              onTap: () => Navigator.pop(context, 'png'),
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined),
              title: const Text('PDF'),
              onTap: () => Navigator.pop(context, 'pdf'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || format == null) return;

    final directory = await getTemporaryDirectory();
    late File file;
    if (format == 'png') {
      final boundary =
          _resultsKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (bytes == null) return;
      file = File('${directory.path}/hasil_nest.png');
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
                'Hasil NEST ORVIX',
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                  color: pdf.PdfColors.deepOrange,
                ),
              ),
              pw.SizedBox(height: 18),
              pw.Table(
                border: pw.TableBorder.all(
                  color: pdf.PdfColors.deepOrange,
                  width: 0.8,
                ),
                columnWidths: {
                  0: const pw.FlexColumnWidth(1.4),
                  1: const pw.FlexColumnWidth(2),
                },
                children: [
                  _pdfTableRow('Data', 'Hasil', isHeader: true),
                  _pdfTableRow(
                    'Open',
                    _formatNumber(_parseNumber(_openController.text)),
                  ),
                  _pdfTableRow(
                    'Close',
                    _formatNumber(_parseNumber(_closeController.text)),
                  ),
                  _pdfTableRow('Hasil NEST', _formatNumber(_nestValue)),
                  _pdfTableRow('Action', _action),
                ],
              ),
            ],
          ),
        ),
      );
      file = File('${directory.path}/hasil_nest.pdf');
      await file.writeAsBytes(await document.save());
    }

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        subject: 'Hasil NEST ${format.toUpperCase()}',
        text: 'Hasil kalkulasi NEST ORVIX',
      ),
    );
  }

  pw.TableRow _pdfTableRow(
    String label,
    String value, {
    bool isHeader = false,
  }) {
    return pw.TableRow(
      decoration: pw.BoxDecoration(
        color: isHeader ? pdf.PdfColors.orange100 : pdf.PdfColors.white,
      ),
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE57B43), // Oranye bagian atas
              Color(0xFFF7DAC9), // Transisi lembut
              Color(0xFFFFF7F2), // Krem bagian bawah
            ],
            stops: [0.0, 0.4, 0.85],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      RepaintBoundary(
                        key: _resultsKey,
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color(0xFFE57B43),
                                Color(0xFFF7DAC9),
                                Color(0xFFFFF7F2),
                              ],
                              stops: [0.0, 0.4, 0.85],
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          child: Column(
                            children: [
                              const SizedBox(height: 10),
                              // 1. Title Header
                              _buildHeaderTitle(),
                              const SizedBox(height: 24),

                              // 2. Top Tab Selector
                              _buildTopTabBar(),
                              const SizedBox(height: 20),

                              Padding(
                                padding: const EdgeInsets.only(
                                  bottom: 10,
                                  top: 4,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Hasil Nest',
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
                              const SizedBox(height: 10),

                              // 3. Input Card (Open & Close)
                              _buildInputCard(),
                              if (_saveError != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  _saveError!,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 28),

                              // 4. Result Card (Indikasi Nest)
                              _buildResultCard(),
                              const SizedBox(height: 28),
                            ],
                          ),
                        ),
                      ),
                      _buildActionButtons(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              // 6. Floating Bottom Navigation Bar
              if (widget.showBottomNavigation) ...[
                _buildBottomNavigationBar(),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // --- 1. HEADER TITLE ---
  Widget _buildHeaderTitle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset('assets/text_logo.png', height: 28, fit: BoxFit.contain),
        const SizedBox(width: 8),
        const Text(
          'Kalkulator',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  // --- 2. TOP TAB BAR ---
  Widget _buildTopTabBar() {
    final List<String> tabs = ['Emas Fisik', 'Pivot Point', 'Nest'];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = _selectedTopTab == index;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                if (index == 0) {
                  Navigator.of(context).pushReplacement(
                    PageRouteBuilder<void>(
                      transitionDuration: Duration.zero,
                      reverseTransitionDuration: Duration.zero,
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          const MainScreen(initialIndex: 1, calculatorTab: 0),
                    ),
                  );
                } else if (index == 1) {
                  Navigator.of(context).pushReplacement(
                    PageRouteBuilder<void>(
                      transitionDuration: Duration.zero,
                      reverseTransitionDuration: Duration.zero,
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          const MainScreen(initialIndex: 1, calculatorTab: 1),
                    ),
                  );
                } else {
                  setState(() => _selectedTopTab = index);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFD8531D)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Center(
                  child: Text(
                    tabs[index],
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFFD8531D),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // --- 3. INPUT CARD ---
  Widget _buildInputCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Otomatis',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF555555),
                ),
              ),
              Switch(
                value: _isAuto,
                onChanged: _isLoadingAuto ? null : _toggleAutomatic,
                activeThumbColor: const Color(0xFFD95B14),
              ),
            ],
          ),
          // Open Field Row
          Row(
            children: [
              const SizedBox(
                width: 60,
                child: Text(
                  'Open',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF555555),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(child: _buildInputField(_openController)),
            ],
          ),
          const SizedBox(height: 16),
          // Close Field Row
          Row(
            children: [
              const SizedBox(
                width: 60,
                child: Text(
                  'Close',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF555555),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(child: _buildInputField(_closeController)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(TextEditingController controller) {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: controller,
        onChanged: (_) => _calculateNest(),
        enabled: !_isAuto,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textAlign: TextAlign.left,
        textAlignVertical: TextAlignVertical.center,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        decoration: const InputDecoration(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
            borderSide: BorderSide(color: Color(0xFF888888)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
            borderSide: BorderSide(color: Color(0xFF888888)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
            borderSide: BorderSide(color: Color(0xFFD95B14), width: 1.5),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 12),
        ),
      ),
    );
  }

  // --- 4. RESULT CARD (INDIKASI NEST) ---
  Widget _buildResultCard() {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        // Main Cream Card
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 16),
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
          decoration: BoxDecoration(
            color: const Color(0xFFFBF2EB), // Soft cream/pinkish tint
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.6),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Hasil Nest Section
              const Text(
                'Hasil Nest',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6E2E1A),
                ),
              ),
              const SizedBox(height: 6),
              _buildValueBox(_formatNumber(_nestValue)),
              const SizedBox(height: 14),

              // Action Section
              const Text(
                'Action',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6E2E1A),
                ),
              ),
              const SizedBox(height: 6),
              _buildValueBox(_action),
              const SizedBox(height: 16),

              if (_action == 'BUY')
                const Text(
                  'Jika Close diatas Open BUY',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E683A),
                  ),
                )
              else if (_action == 'SELL')
                const Text(
                  'Jika Close dibawah Open SELL',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFC62828),
                  ),
                ),
            ],
          ),
        ),

        // Floating Top Badge "Indikasi"
        Positioned(
          top: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFD8531D),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD8531D).withValues(alpha: 0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Text(
              'Indikasi',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildValueBox(String text) {
    return Container(
      width: 180,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF444444), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Color(0xFF801B00), // Dark Burgundy Red
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  // --- 5. ACTION BUTTONS ---
  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Download Button
        SizedBox(
          width: 150,
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFDE5825), width: 1.5),
            ),
            child: InkWell(
              onTap: _downloadAndShareResults,
              borderRadius: BorderRadius.circular(10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(
                    Icons.file_download_outlined,
                    color: Color(0xFFDE5825),
                    size: 20,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Download',
                    style: TextStyle(
                      color: Color(0xFFDE5825),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),

        // Reset Button
        SizedBox(
          width: 150,
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFDE5825), width: 1.5),
            ),
            child: InkWell(
              onTap: () {
                setState(() {
                  _openController.clear();
                  _closeController.clear();
                  _nestValue = 0;
                  _action = '-';
                  _saveError = null;
                  _lastSavedNestInput = null;
                });
              },
              borderRadius: BorderRadius.circular(10),
              child: const Center(
                child: Text(
                  'Reset',
                  style: TextStyle(
                    color: Color(0xFFDE5825),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- 6. FLOATING BOTTOM NAVIGATION BAR ---
  Widget _buildBottomNavigationBar() {
    final List<Map<String, dynamic>> navItems = [
      {'icon': Icons.home_rounded, 'label': 'Home'},
      {'icon': Icons.calculate_outlined, 'label': 'Calculate'},
      {'icon': Icons.history_rounded, 'label': 'History'},
      {'icon': Icons.person_outline_rounded, 'label': 'Profil'},
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 72,
      decoration: BoxDecoration(
        color: const Color(0xFFE55B2B), // Vivid Orange
        borderRadius: BorderRadius.circular(36),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE55B2B).withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(navItems.length, (index) {
          final isSelected = _selectedNavIndex == index;
          final item = navItems[index];

          return GestureDetector(
            onTap: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute<void>(
                  builder: (_) => MainScreen(initialIndex: index),
                ),
              );
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isSelected)
                  Column(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          item['icon'],
                          color: const Color(0xFFE55B2B),
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item['label'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        width: 12,
                        height: 2,
                        color: Colors.white,
                      ),
                    ],
                  )
                else
                  Column(
                    children: [
                      Icon(
                        item['icon'],
                        color: Colors.white.withValues(alpha: 0.9),
                        size: 22,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item['label'],
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
