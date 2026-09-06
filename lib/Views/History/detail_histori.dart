import 'package:flutter/material.dart';
import '../../Models/historikalkulator_model.dart';

class DetailHistoryScreen extends StatelessWidget {
  final HistoryModel history;

  const DetailHistoryScreen({super.key, required this.history});

  static const Color primaryOrange = Color(0xFFD95B14);

  @override
  Widget build(BuildContext context) {
    final isPivot = history.jenisKalkulator.toLowerCase().contains('pivot');
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
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: const CircleBorder(),
                      ),
                      icon: const Icon(Icons.arrow_back, color: Colors.black),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Detail History',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF9FAFC),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildMetaCard(),
                        const SizedBox(height: 20),
                        const Text(
                          'Hasil Perhitungan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildResultCard(),
                        const SizedBox(height: 20),
                        Text(
                          isPivot ? 'Data Harga' : 'Data Emas Fisik',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        isPivot ? _buildPriceCard() : _buildGoldPriceCard(),
                        const SizedBox(height: 20),
                        Text(
                          isPivot ? 'Detail Pivot Point' : 'Detail Emas Fisik',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        isPivot
                            ? _buildTypeCard(isPivot)
                            : _buildGoldFormulaCard(),
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

  Widget _buildMetaCard() {
    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            history.jenisKalkulator,
            style: const TextStyle(
              color: primaryOrange,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text('ID Histori: ${history.id}', style: _secondaryStyle),
          const SizedBox(height: 4),
          Text(_formatDate(history.createdAt), style: _secondaryStyle),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    return _card(
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Hasil akhir',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          Text(
            _formatWholeNumber(history.hasil),
            style: const TextStyle(
              color: primaryOrange,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeCard(bool isPivot) {
    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(
            'Jenis proses',
            isPivot ? 'Perhitungan Pivot Point' : 'Perhitungan Emas Fisik',
          ),
          const Divider(height: 20),
          _buildInfoRow('Status', 'Selesai'),
          const SizedBox(height: 12),
          const Text(
            'Input rinci tersimpan pada histori akan ditampilkan di bagian ini.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceCard() {
    return _card(
      Column(
        children: [
          _buildInfoRow('Open', _formatPrice(history.open)),
          const Divider(height: 20),
          _buildInfoRow('High', _formatPrice(history.high)),
          const Divider(height: 20),
          _buildInfoRow('Low', _formatPrice(history.low)),
          const Divider(height: 20),
          _buildInfoRow('Close', _formatPrice(history.close)),
          const Divider(height: 20),
          _buildInfoRow('Indikasi', history.indikasi ?? '-'),
        ],
      ),
    );
  }

  Widget _buildGoldPriceCard() {
    return _card(
      Column(
        children: [
          _buildInfoRow('Modal', _formatPrice(history.modal)),
          const Divider(height: 20),
          _buildInfoRow('Harga Beli', _formatPrice(history.hargaBeli)),
          const Divider(height: 20),
          _buildInfoRow('Harga Jual', _formatPrice(history.hargaJual)),
        ],
      ),
    );
  }

  Widget _buildGoldFormulaCard() {
    return _card(
      Column(
        children: [
          _buildInfoRow('ToZ', _formatPrice(history.toz)),
          const Divider(height: 20),
          _buildInfoRow('Kurs', _formatWholeNumber(history.kurs)),
          const Divider(height: 20),
          _buildInfoRow(
            'Harga beli / gram',
            _formatPrice(history.hargaBeliPerGram),
          ),
          const Divider(height: 20),
          _buildInfoRow(
            'Harga jual / gram',
            _formatPrice(history.hargaJualPerGram),
          ),
          const Divider(height: 20),
          _buildInfoRow(
            'Selisih / gram (2 - 1)',
            _formatPrice(history.selisihPerGram),
          ),
          const Divider(height: 20),
          _buildInfoRow('Jumlah emas', _formatPrice(history.jumlahEmas)),
        ],
      ),
    );
  }

  String _formatPrice(double? value) =>
      value == null ? '-' : _formatIndonesianNumber(value, decimals: 2);

  String _formatWholeNumber(double? value) =>
      value == null ? '-' : _formatIndonesianNumber(value);

  String _formatIndonesianNumber(double value, {int decimals = 0}) {
    var factor = 1.0;
    for (var index = 0; index < decimals; index++) {
      factor *= 10;
    }
    final truncated = (value * factor).truncate() / factor;
    final fixed = truncated.toStringAsFixed(decimals).split('.');
    final integer = fixed.first.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    );
    if (decimals == 0) return integer;
    return '$integer,${fixed[1]}';
  }

  Widget _card(Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: _secondaryStyle),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
  }

  static const TextStyle _secondaryStyle = TextStyle(
    fontSize: 12,
    color: Colors.grey,
  );
}
