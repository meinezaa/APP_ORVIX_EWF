import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:app_pt_ewf/Views/Kalkulator/detail_emasfisik.dart';
import '../../Services/history_service.dart';
import 'pivotpoin.dart';

class KalkulatorEmasFisikView extends StatefulWidget {
  const KalkulatorEmasFisikView({super.key});

  @override
  State<KalkulatorEmasFisikView> createState() =>
      _KalkulatorEmasFisikViewState();
}

class _KalkulatorEmasFisikViewState extends State<KalkulatorEmasFisikView> {
  int _selectedTab = 0;
  bool _isLoadingKurs = false;

  final TextEditingController _tozController = TextEditingController(
    text: '31,1',
  );
  final TextEditingController _kursController = TextEditingController();
  final TextEditingController _modalController = TextEditingController();
  final TextEditingController _hargaBeliController = TextEditingController();
  final TextEditingController _hargaJualController = TextEditingController();
  final TextEditingController _hasilController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchKursUSD();
  }

  Future<void> _fetchKursUSD() async {
    setState(() => _isLoadingKurs = true);

    try {
      final response = await http.get(
        Uri.parse('https://open.er-api.com/v6/latest/USD'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['rates'] != null && data['rates']['IDR'] != null) {
          double idrRate = (data['rates']['IDR'] as num).toDouble();

          String formattedRate = idrRate
              .toStringAsFixed(0)
              .replaceAllMapped(
                RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                (Match m) => '${m[1]}.',
              );

          if (mounted) {
            setState(() {
              _kursController.text = formattedRate;
            });
          }
        }
      } else {
        if (mounted) setState(() => _kursController.text = '16.000');
      }
    } catch (e) {
      if (mounted) setState(() => _kursController.text = '16.000');
    } finally {
      if (mounted) setState(() => _isLoadingKurs = false);
    }
  }

  double _parseInput(String text) {
    final cleanText = text.trim();
    final commaCount = ','.allMatches(cleanText).length;
    final dotCount = '.'.allMatches(cleanText).length;
    final normalized = cleanText.contains('.') && cleanText.contains(',')
        ? cleanText.replaceAll('.', '').replaceAll(',', '.')
        : dotCount > 0 &&
              cleanText.split('.').skip(1).every((part) => part.length == 3)
        ? cleanText.replaceAll('.', '')
        : commaCount > 1
        ? cleanText.replaceAll(',', '')
        : cleanText.replaceAll(',', '.');
    return double.tryParse(normalized) ?? 0.0;
  }

  String _formatNumber(double number, {int decimalDigits = 0}) {
    if (number.isNaN || number.isInfinite) return '0';
    var factor = 1.0;
    for (var index = 0; index < decimalDigits; index++) {
      factor *= 10;
    }
    final truncated = (number * factor).truncate() / factor;
    String str = truncated.toStringAsFixed(decimalDigits);
    List<String> parts = str.split('.');
    RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    String integerPart = parts[0].replaceAllMapped(reg, (m) => '${m[1]}.');

    if (parts.length > 1 && int.parse(parts[1]) > 0) {
      return '$integerPart.${parts[1]}';
    }
    return integerPart;
  }

  double _truncate(double value, {int decimals = 0}) {
    var factor = 1.0;
    for (var index = 0; index < decimals; index++) {
      factor *= 10;
    }
    return (value * factor).truncate() / factor;
  }

  void _resetForm() {
    setState(() {
      _tozController.text = '31,1';
      _modalController.clear();
      _hargaBeliController.clear();
      _hargaJualController.clear();
      _hasilController.clear();
    });
    _fetchKursUSD();
  }

  // RUMUS PERHITUNGAN YANG SUDAH DIPERBAIKI
  Future<void> _hitung() async {
    double toz = _parseInput(_tozController.text);
    double kurs = _parseInput(_kursController.text);
    double modal = _parseInput(_modalController.text);
    double hargaBeli = _parseInput(_hargaBeliController.text);
    double hargaJual = _parseInput(_hargaJualController.text);

    if (toz == 0) toz = 31.1;

    final h1 = _truncate((hargaBeli * kurs) / toz);
    final h2 = _truncate((hargaJual * kurs) / toz);
    final h3 = _truncate(h2 - h1);
    final h4 = h1 == 0 ? 0.0 : _truncate(modal / h1, decimals: 2);
    final hasilAkhir = _truncate(h3 * h4);

    setState(() {
      _hasilController.text = 'Rp ${_formatNumber(hasilAkhir)}';
    });

    try {
      await HistoryService.saveCalculation(
        jenisKalkulator: 'Emas Fisik',
        hasil: hasilAkhir,
        modal: modal,
        hargaBeli: hargaBeli,
        hargaJual: hargaJual,
        toz: toz,
        kurs: kurs,
        hargaBeliPerGram: h1,
        hargaJualPerGram: h2,
        selisihPerGram: h3,
        jumlahEmas: h4,
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hasil tampil, tetapi histori gagal disimpan.'),
          ),
        );
      }
    }
  }

  void _bukaDetailPerhitungan() {
    double toz = _parseInput(_tozController.text);
    double kurs = _parseInput(_kursController.text);
    double modal = _parseInput(_modalController.text);
    double hargaBeli = _parseInput(_hargaBeliController.text);
    double hargaJual = _parseInput(_hargaJualController.text);

    if (toz == 0) toz = 31.1;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailPerhitunganEmasFisikView(
          toz: toz,
          kurs: kurs,
          modal: modal,
          hargaBeli: hargaBeli,
          hargaJual: hargaJual,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryOrange = Color(0xFFD95B14);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFEA8648), Color(0xFFFDF7F2)],
            stops: [0.0, 0.6],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/text_logo.png',
                      height: 28,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Text(
                          'ORVIX',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFC74B03),
                          ),
                        );
                      },
                    ),
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
                ),

                const SizedBox(height: 24),

                // TAB TOGGLE
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedTab = 0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _selectedTab == 0
                                  ? primaryOrange
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: Center(
                              child: Text(
                                'Emas Fisik',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: _selectedTab == 0
                                      ? Colors.white
                                      : primaryOrange,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedTab = 1),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _selectedTab == 1
                                  ? primaryOrange
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: Center(
                              child: Text(
                                'Pivot Point',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: _selectedTab == 1
                                      ? Colors.white
                                      : primaryOrange,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                if (_selectedTab == 1)
                  const PivotPointView()
                else ...[
                  // FORM INPUT CARD
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Text(
                              'ToZ',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF555555),
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 85,
                              child: _buildTextField(
                                _tozController,
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const Spacer(),
                            const Text(
                              'Kurs',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF555555),
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 100,
                              child: _buildTextField(
                                _kursController,
                                textAlign: TextAlign.center,
                                isLoading: _isLoadingKurs,
                                inputFormatters: [
                                  ThousandsSeparatorFormatter(),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        _buildFormRow(
                          'Modal',
                          _modalController,
                          isInteger: true,
                        ),
                        const SizedBox(height: 12),

                        _buildFormRow('Harga Beli', _hargaBeliController),
                        const SizedBox(height: 12),

                        _buildFormRow('Harga Jual', _hargaJualController),
                        const SizedBox(height: 24),

                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 42,
                                child: ElevatedButton(
                                  onPressed: _hitung,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryOrange,
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: const Text(
                                    'Hitung',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: SizedBox(
                                height: 42,
                                child: OutlinedButton(
                                  onPressed: _resetForm,
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                      color: primaryOrange,
                                      width: 1.5,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: const Text(
                                    'Reset',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: primaryOrange,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // HASIL CARD
                  Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.topCenter,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(20, 36, 20, 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            SizedBox(
                              height: 50,
                              child: TextField(
                                controller: _hasilController,
                                readOnly: true,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: primaryOrange,
                                ),
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF666666),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF666666),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            SizedBox(
                              width: double.infinity,
                              height: 44,
                              child: OutlinedButton.icon(
                                onPressed: _bukaDetailPerhitungan,
                                icon: const Icon(
                                  Icons.toc_rounded,
                                  color: primaryOrange,
                                  size: 24,
                                ),
                                label: const Text(
                                  'Detail Perhitungan',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: primaryOrange,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                    color: primaryOrange,
                                    width: 1.5,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      Positioned(
                        top: -16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: primaryOrange,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Text(
                            'Hasil Perhitungan',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormRow(
    String label,
    TextEditingController controller, {
    bool isInteger = false,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF555555),
              fontSize: 13,
            ),
          ),
        ),
        Expanded(
          child: _buildTextField(
            controller,
            inputFormatters: isInteger ? [ThousandsSeparatorFormatter()] : null,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(
    TextEditingController controller, {
    TextAlign textAlign = TextAlign.start,
    bool isLoading = false,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return SizedBox(
      height: 38,
      child: TextField(
        controller: controller,
        textAlign: textAlign,
        keyboardType: TextInputType.number,
        inputFormatters: inputFormatters,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 8,
          ),
          suffixIcon: isLoading
              ? const Padding(
                  padding: EdgeInsets.all(10.0),
                  child: SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFFD95B14),
                    ),
                  ),
                )
              : null,
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
            borderSide: const BorderSide(color: Color(0xFFD95B14), width: 1.5),
          ),
        ),
      ),
    );
  }
}

class ThousandsSeparatorFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return newValue.copyWith(text: '');

    final formatted = digits.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    );
    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
