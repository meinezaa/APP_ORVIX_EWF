import 'package:flutter/material.dart';

class DetailPerhitunganEmasFisikView extends StatelessWidget {
  final double toz;
  final double kurs;
  final double modal;
  final double hargaBeli;
  final double hargaJual;

  const DetailPerhitunganEmasFisikView({
    super.key,
    required this.toz,
    required this.kurs,
    required this.modal,
    required this.hargaBeli,
    required this.hargaJual,
  });

  // Helper Format Angka ke Rupiah / Ribuan
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

  @override
  Widget build(BuildContext context) {
    const primaryOrange = Color(0xFFD95B14);

    // LOGIKA PERHITUNGAN TAHAP 1 - 5
    final h1 = toz == 0 ? 0.0 : _truncate((hargaBeli * kurs) / toz);
    final h2 = toz == 0 ? 0.0 : _truncate((hargaJual * kurs) / toz);
    final h3 = _truncate(h2 - h1);
    final h4 = h1 == 0 ? 0.0 : _truncate(modal / h1, decimals: 2);
    final hasilAkhir = _truncate(h3 * h4);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF3C7AA), Color(0xFFFDF7F2)],
            stops: [0.0, 0.4],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 1. TOP APP BAR
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.black87,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Detail Perhitungan',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),

              // 2. KONTEN UTAMA DENGAN CONTAINER PUTIH BESAR
              Expanded(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // CARD HASIL AKHIR TOP
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.workspace_premium,
                                  color: Colors.amber,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Hasil Akhir',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Rp ${_formatNumber(hasilAkhir)}',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: primaryOrange,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // TIMELINE ALUR TAHAP 1 - 5
                        Stack(
                          children: [
                            // Garis Putus-putus Oranye Vertikal
                            Positioned(
                              left: 20,
                              top: 20,
                              bottom: 40,
                              child: CustomPaint(
                                painter: DashedLinePainter(
                                  color: primaryOrange.withValues(alpha: 0.6),
                                ),
                              ),
                            ),

                            Column(
                              children: [
                                // TAHAP 1
                                _buildStepCard(
                                  stepNumber: '1',
                                  tahapTitle: 'Tahap 1',
                                  subTitle: 'Perhitungan Awal',
                                  formulaChild: _buildFractionFormula(
                                    numerator: 'HB x Kurs',
                                    denominator: 'ToZ',
                                    valNumerator:
                                        '${_formatNumber(hargaBeli)} × ${_formatNumber(kurs)}',
                                    valDenominator: _formatNumber(
                                      toz,
                                      decimalDigits: 1,
                                    ),
                                  ),
                                  resultText: _formatNumber(h1),
                                ),

                                const SizedBox(height: 16),

                                // TAHAP 2
                                _buildStepCard(
                                  stepNumber: '2',
                                  tahapTitle: 'Tahap 2',
                                  subTitle: 'Perhitungan Kedua',
                                  formulaChild: _buildFractionFormula(
                                    numerator: 'HJ x Kurs',
                                    denominator: 'ToZ',
                                    valNumerator:
                                        '${_formatNumber(hargaJual)} × ${_formatNumber(kurs)}',
                                    valDenominator: _formatNumber(
                                      toz,
                                      decimalDigits: 1,
                                    ),
                                  ),
                                  resultText: _formatNumber(h2),
                                ),

                                const SizedBox(height: 16),

                                // TAHAP 3
                                _buildStepCard(
                                  stepNumber: '3',
                                  tahapTitle: 'Tahap 3',
                                  subTitle: 'Perhitungan Ketiga',
                                  formulaChild: Column(
                                    children: [
                                      const Text(
                                        'H2 - H1',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '= ${_formatNumber(h2)} - ${_formatNumber(h1)}',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                  resultText: _formatNumber(h3),
                                ),

                                const SizedBox(height: 16),

                                // TAHAP 4
                                _buildStepCard(
                                  stepNumber: '4',
                                  tahapTitle: 'Tahap 4',
                                  subTitle: 'Perhitungan Keempat',
                                  formulaChild: _buildFractionFormula(
                                    numerator: 'Modal',
                                    denominator: 'H1',
                                    valNumerator: _formatNumber(modal),
                                    valDenominator: _formatNumber(h1),
                                  ),
                                  resultText: _formatNumber(
                                    h4,
                                    decimalDigits: 2,
                                  ),
                                ),

                                const SizedBox(height: 16),

                                // TAHAP 5
                                _buildStepCard(
                                  stepNumber: '5',
                                  tahapTitle: 'Tahap 5',
                                  subTitle: 'Hasil Akhir',
                                  formulaChild: Column(
                                    children: [
                                      const Text(
                                        'H3 x H4',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '= ${_formatNumber(h3)} × ${_formatNumber(h4, decimalDigits: 2)}',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                  resultText: _formatNumber(hasilAkhir),
                                  isHighlightResult: true,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper Widget Item Step Card
  Widget _buildStepCard({
    required String stepNumber,
    required String tahapTitle,
    required String subTitle,
    required Widget formulaChild,
    required String resultText,
    bool isHighlightResult = false,
  }) {
    const primaryOrange = Color(0xFFD95B14);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Lingkaran Nomor Indikator
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: primaryOrange,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              stepNumber,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Box Detail Perhitungan
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tahapTitle,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: primaryOrange,
                  ),
                ),
                Text(
                  subTitle,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),

                // Container Formula Rumus
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8EFE7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: formulaChild,
                ),

                const SizedBox(height: 8),

                // Hasil Baris Bawah
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      '= ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      resultText,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isHighlightResult ? 18 : 14,
                        color: primaryOrange,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Helper Fraction Formula (Pecahan Atas / Bawah)
  Widget _buildFractionFormula({
    required String numerator,
    required String denominator,
    required String valNumerator,
    required String valDenominator,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Sisi Kiri Simbol Rumus Pecahan
        Column(
          children: [
            Text(
              numerator,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
            Container(width: 60, height: 1, color: Colors.black87),
            Text(
              denominator,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            '=',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ),
        // Sisi Kanan Angka Real Pecahan
        Column(
          children: [
            Text(valNumerator, style: const TextStyle(fontSize: 11)),
            Container(width: 90, height: 1, color: Colors.black87),
            Text(valDenominator, style: const TextStyle(fontSize: 11)),
          ],
        ),
      ],
    );
  }
}

// Custom Painter untuk Menggambar Garis Putus-putus Vertikal
class DashedLinePainter extends CustomPainter {
  final Color color;
  DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    double dashHeight = 4, dashSpace = 4, startY = 0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2;

    while (startY < size.height) {
      canvas.drawLine(Offset(0, startY), Offset(0, startY + dashHeight), paint);
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
