import 'package:flutter/material.dart';

import '../../Models/historikalkulator_model.dart';
import '../../Services/app_strings.dart';
import '../../Services/app_theme.dart';

class DetailHistoryScreen extends StatelessWidget {
  final HistoryModel history;

  const DetailHistoryScreen({super.key, required this.history});

  static const Color primaryOrange = Color(0xFFD95B14);

  @override
  Widget build(BuildContext context) {
    final isPivot = history.jenisKalkulator.toLowerCase().contains('pivot');
    final isNest = history.jenisKalkulator.toLowerCase().contains('nest');
    return Scaffold(
      backgroundColor: AppTheme.background(context),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(gradient: AppTheme.pageGradient(context)),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      style: IconButton.styleFrom(
                        backgroundColor: AppTheme.surface(context),
                        shape: const CircleBorder(),
                      ),
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Color(0xFFE07856),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      AppStrings.text(context, 'Detail History'),
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.text(context),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppTheme.background(context),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildMetaCard(context),
                        const SizedBox(height: 20),
                        Text(
                          AppStrings.text(context, 'Hasil Perhitungan'),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.text(context),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildResultCard(context),
                        const SizedBox(height: 20),
                        Text(
                          AppStrings.text(
                            context,
                            isPivot || isNest
                                ? 'Data Harga'
                                : 'Data Emas Fisik',
                          ),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.text(context),
                          ),
                        ),
                        const SizedBox(height: 10),
                        isPivot
                            ? _buildPriceCard(context)
                            : isNest
                            ? _buildNestPriceCard(context)
                            : _buildGoldPriceCard(context),
                        const SizedBox(height: 20),
                        Text(
                          AppStrings.text(
                            context,
                            isPivot
                                ? 'Detail Pivot Point'
                                : isNest
                                ? 'Detail NEST'
                                : 'Detail Emas Fisik',
                          ),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.text(context),
                          ),
                        ),
                        const SizedBox(height: 10),
                        isPivot
                            ? _buildTypeCard(context, isPivot)
                            : isNest
                            ? _buildTypeCard(context, isPivot, isNest: true)
                            : _buildGoldFormulaCard(context),
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

  Widget _buildMetaCard(BuildContext context) {
    return _card(
      context,
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
          Text(
            '${AppStrings.text(context, 'ID Histori')}: ${history.id}',
            style: _secondaryStyle(context),
          ),
          const SizedBox(height: 4),
          Text(_formatDate(history.createdAt), style: _secondaryStyle(context)),
        ],
      ),
    );
  }

  Widget _buildResultCard(BuildContext context) {
    return _card(
      context,
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            AppStrings.text(context, 'Hasil akhir'),
            style: TextStyle(fontSize: 14, color: AppTheme.mutedText(context)),
          ),
          Text(
            _formatWholeNumber(history.hasil),
            style: TextStyle(
              color: primaryOrange,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeCard(
    BuildContext context,
    bool isPivot, {
    bool isNest = false,
  }) {
    return _card(
      context,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(
            context,
            AppStrings.text(context, 'Jenis proses'),
            isPivot
                ? AppStrings.text(context, 'Perhitungan Pivot Point')
                : isNest
                ? AppStrings.text(context, 'Perhitungan NEST')
                : AppStrings.text(context, 'Perhitungan Emas Fisik'),
          ),
          if (isPivot && history.kategori != null) ...[
            const Divider(height: 20),
            _buildInfoRow(
              context,
              AppStrings.text(context, 'Kategori'),
              history.kategori!.toUpperCase(),
            ),
          ],
          const Divider(height: 20),
          _buildInfoRow(
            context,
            AppStrings.text(context, 'Status'),
            AppStrings.text(context, 'Selesai'),
          ),
          const SizedBox(height: 12),
          Text(
            AppStrings.text(
              context,
              'Input rinci tersimpan pada histori akan ditampilkan di bagian ini.',
            ),
            style: TextStyle(fontSize: 12, color: AppTheme.mutedText(context)),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceCard(BuildContext context) {
    return _card(
      context,
      Column(
        children: [
          _buildInfoRow(context, 'Open', _formatPrice(history.open)),
          const Divider(height: 20),
          _buildInfoRow(context, 'High', _formatPrice(history.high)),
          const Divider(height: 20),
          _buildInfoRow(context, 'Low', _formatPrice(history.low)),
          const Divider(height: 20),
          _buildInfoRow(context, 'Close', _formatPrice(history.close)),
          const Divider(height: 20),
          _buildInfoRow(context, 'Indikasi', history.indikasi ?? '-'),
        ],
      ),
    );
  }

  Widget _buildNestPriceCard(BuildContext context) {
    return _card(
      context,
      Column(
        children: [
          _buildInfoRow(context, 'Open', _formatPrice(history.open)),
          const Divider(height: 20),
          _buildInfoRow(context, 'Close', _formatPrice(history.close)),
          const Divider(height: 20),
          _buildInfoRow(context, 'Action', history.indikasi ?? '-'),
        ],
      ),
    );
  }

  Widget _buildGoldPriceCard(BuildContext context) {
    return _card(
      context,
      Column(
        children: [
          _buildInfoRow(context, 'Modal', _formatPrice(history.modal)),
          const Divider(height: 20),
          _buildInfoRow(context, 'Harga Beli', _formatPrice(history.hargaBeli)),
          const Divider(height: 20),
          _buildInfoRow(context, 'Harga Jual', _formatPrice(history.hargaJual)),
        ],
      ),
    );
  }

  Widget _buildGoldFormulaCard(BuildContext context) {
    return _card(
      context,
      Column(
        children: [
          _buildInfoRow(context, 'ToZ', _formatPrice(history.toz)),
          const Divider(height: 20),
          _buildInfoRow(context, 'Kurs', _formatWholeNumber(history.kurs)),
          const Divider(height: 20),
          _buildInfoRow(
            context,
            'Harga beli / gram',
            _formatPrice(history.hargaBeliPerGram),
          ),
          const Divider(height: 20),
          _buildInfoRow(
            context,
            'Harga jual / gram',
            _formatPrice(history.hargaJualPerGram),
          ),
          const Divider(height: 20),
          _buildInfoRow(
            context,
            'Selisih / gram (2 - 1)',
            _formatPrice(history.selisihPerGram),
          ),
          const Divider(height: 20),
          _buildInfoRow(
            context,
            'Jumlah emas',
            _formatPrice(history.jumlahEmas),
          ),
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

  Widget _card(BuildContext context, Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border(context)),
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

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(AppStrings.text(context, label), style: _secondaryStyle(context)),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppTheme.text(context),
          ),
        ),
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

  TextStyle _secondaryStyle(BuildContext context) =>
      TextStyle(fontSize: 12, color: AppTheme.mutedText(context));
}
