import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:app_pt_ewf/Views/Kalkulator/detail_emasfisik.dart';
import '../../Services/app_strings.dart';
import '../../Services/app_theme.dart';
import '../../Services/history_service.dart';
import '../main_screen.dart';
import 'kalkulator_info.dart';
import 'pivotpoin.dart';
import 'nest.dart';
import 'grafik_harga.dart';

class KalkulatorEmasFisikView extends StatefulWidget {
  final int initialTab;
  final bool showBottomNavigation;

  const KalkulatorEmasFisikView({
    super.key,
    this.initialTab = 0,
    this.showBottomNavigation = true,
  });

  @override
  State<KalkulatorEmasFisikView> createState() =>
      _KalkulatorEmasFisikViewState();
}

class _KalkulatorEmasFisikViewState extends State<KalkulatorEmasFisikView> {
  late int _selectedTab = widget.initialTab;
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
        idempotencyKey: 'physical|$hasilAkhir',
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
      bottomNavigationBar: widget.showBottomNavigation
          ? _buildBottomNavigationBar()
          : null,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(gradient: AppTheme.pageGradient(context)),
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
                    Text(
                      AppStrings.text(context, 'Kalkulator'),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                const TradingViewChartCarousel(),
                const SizedBox(height: 24),

                // TAB TOGGLE
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppTheme.surface(context),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: AppTheme.border(context)),
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
                                AppStrings.text(context, 'Emas Fisik'),
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
                                AppStrings.text(context, 'Pivot Point'),
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
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedTab = 2),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _selectedTab == 2
                                  ? primaryOrange
                                  : Colors.transparent,
                              borderRadius: BorderRadius.all(
                                Radius.circular(25),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                AppStrings.text(context, 'Nest'),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: _selectedTab == 2
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

                KalkulatorInfoCard(
                  title: _selectedTab == 0 ? 'Emas Fisik' : 'Pivot Point',
                  summary: _selectedTab == 0
                      ? 'Emas fisik adalah emas berwujud yang dapat disimpan sebagai aset riil.'
                      : 'Pivot Point adalah harga acuan untuk menentukan aksi beli atau jual berdasarkan harga Open.',
                  details: _selectedTab == 0
                      ? 'Emas fisik adalah emas yang berwujud, dapat berupa batangan, koin, atau perhiasan, yang dibeli oleh investor dan disimpan sebagai aset riil. Emas fisik memiliki nilai intrinsik yang dihargai di seluruh dunia, dan karena bentuknya yang nyata, investor dapat menyimpannya di rumah dan atau di tempat penyimpanan khusus.'
                      : 'Pivot Point adalah harga wajar atau harga pasaran untuk menentukan aksi beli dan jual yang mengacu pada harga pembukaan (Open).\n\nOpen < Pivot Point: BUY\nOpen > Pivot Point: SELL',
                ),

                if (_selectedTab == 1)
                  const PivotPointView()
                else if (_selectedTab == 2)
                  const OrvixKalkulatorScreen(
                    embedded: true,
                    showBottomNavigation: false,
                  )
                else ...[
                  // FORM INPUT CARD
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.surface(context),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppTheme.border(context)),
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
                            Text(
                              'ToZ',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.mutedText(context),
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
                                  child: Text(
                                    AppStrings.text(context, 'Hitung'),
                                    style: const TextStyle(
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
                                  child: Text(
                                    AppStrings.text(context, 'Reset'),
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
                          color: AppTheme.surface(context),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppTheme.border(context)),
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
                                    borderSide: BorderSide(
                                      color: AppTheme.border(context),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                      color: AppTheme.border(context),
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
                                label: Text(
                                  AppStrings.text(
                                    context,
                                    'Detail Perhitungan',
                                  ),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
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
                          child: Text(
                            AppStrings.text(context, 'Hasil Perhitungan'),
                            style: const TextStyle(
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

  Widget _buildBottomNavigationBar() {
    const primaryOrange = Color(0xFFD95B14);
    const navItems = [
      (icon: Icons.home_outlined, label: 'Home'),
      (icon: Icons.calculate_outlined, label: 'Calculate'),
      (icon: Icons.history_toggle_off, label: 'History'),
      (icon: Icons.person_outline, label: 'Profil'),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: primaryOrange,
          borderRadius: BorderRadius.circular(35),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(navItems.length, (index) {
            final item = navItems[index];
            final isSelected = index == 1;
            return Expanded(
              child: InkWell(
                onTap: () {
                  if (index == 1) return;
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute<void>(
                      builder: (_) => MainScreen(initialIndex: index),
                    ),
                  );
                },
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isSelected)
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: primaryOrange, width: 3),
                        ),
                        child: Icon(item.icon, color: primaryOrange, size: 26),
                      )
                    else
                      Icon(
                        item.icon,
                        color: Colors.white.withValues(alpha: 0.9),
                        size: 22,
                      ),
                    if (!isSelected) const SizedBox(height: 4),
                    Text(
                      item.label,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 11,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w500,
                      ),
                    ),
                    if (isSelected)
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        width: 14,
                        height: 2.5,
                        color: Colors.white,
                      ),
                  ],
                ),
              ),
            );
          }),
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
            AppStrings.text(context, label),
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppTheme.mutedText(context),
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
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
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
            borderSide: BorderSide(color: AppTheme.border(context)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: AppTheme.border(context)),
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
