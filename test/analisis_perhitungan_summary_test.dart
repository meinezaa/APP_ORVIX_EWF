import 'package:app_pt_ewf/Models/historikalkulator_model.dart';
import 'package:app_pt_ewf/Views/Analitik/analisis_perhitungan.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('summary counts physical, pivot, and nest totals from real history', () {
    final history = [
      HistoryModel(
        id: '1',
        jenisKalkulator: 'Emas Fisik',
        hasil: 10,
        createdAt: DateTime(2026, 9, 17),
      ),
      HistoryModel(
        id: '2',
        jenisKalkulator: 'Emas Fisik',
        hasil: 20,
        createdAt: DateTime(2026, 9, 17),
      ),
      HistoryModel(
        id: '3',
        jenisKalkulator: 'Pivot Point',
        hasil: 30,
        createdAt: DateTime(2026, 9, 17),
      ),
      HistoryModel(
        id: '4',
        jenisKalkulator: 'NEST',
        hasil: 40,
        createdAt: DateTime(2026, 9, 17),
      ),
      HistoryModel(
        id: '5',
        jenisKalkulator: 'NEST',
        hasil: 50,
        createdAt: DateTime(2026, 9, 17),
      ),
    ];

    final summary = summarizeCalculationTypes(history);

    expect(summary.total, 5);
    expect(summary.physical, 2);
    expect(summary.pivot, 1);
    expect(summary.nest, 2);
  });
}
