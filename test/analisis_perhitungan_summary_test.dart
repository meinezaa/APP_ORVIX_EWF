import 'package:app_pt_ewf/Models/historikalkulator_model.dart';
import 'package:app_pt_ewf/Views/Analitik/analisis_perhitungan.dart';
import 'package:app_pt_ewf/Views/History/detail_histori.dart';
import 'package:flutter/material.dart';
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

  test('same-day NEST results deduplicate even if inputs changed', () {
    final first = HistoryModel(
      id: 'first',
      jenisKalkulator: 'NEST',
      hasil: 4140.8,
      createdAt: DateTime(2026, 10, 6),
      open: 4100,
      close: 4140.8,
      indikasi: 'BUY',
    );
    final repeated = first.copyWith(
      id: 'repeated',
      createdAt: DateTime(2026, 10, 6, 12),
    );
    final differentInput = first.copyWith(open: 4090);
    final differentResult = first.copyWith(hasil: 4141);

    expect(first.isSameNestCalculationAs(repeated), isTrue);
    expect(first.isSameNestCalculationAs(differentInput), isTrue);
    expect(first.isSameNestCalculationAs(differentResult), isFalse);
  });

  test('same-day Pivot results deduplicate across changed inputs', () {
    final first = HistoryModel(
      id: 'first',
      jenisKalkulator: 'Pivot Point',
      hasil: 4116.23,
      createdAt: DateTime(2026, 10, 8),
      kategori: 'LGD',
      open: 4120,
      high: 4150,
      low: 4090,
      close: 4108.7,
    );
    final repeated = first.copyWith(id: 'repeated');
    final differentInputs = first.copyWith(high: 4151);
    final differentResult = first.copyWith(hasil: 4117);

    expect(first.isSameCalculationAs(repeated), isTrue);
    expect(first.isSameCalculationAs(differentInputs), isTrue);
    expect(first.isSameCalculationAs(differentResult), isFalse);
  });

  test('same calculator inputs on a new day create a new history item', () {
    final today = HistoryModel(
      id: 'today',
      jenisKalkulator: 'Emas Fisik',
      hasil: 100,
      createdAt: DateTime(2026, 10, 8, 10),
      modal: 1000,
      hargaBeli: 10,
      hargaJual: 12,
      toz: 31.1,
      kurs: 16000,
    );
    final tomorrow = today.copyWith(
      id: 'tomorrow',
      createdAt: DateTime(2026, 10, 9, 10),
    );

    expect(today.isSameCalculationAs(today.copyWith(id: 'duplicate')), isTrue);
    expect(today.isSameCalculationAs(tomorrow), isFalse);
  });

  testWidgets('NEST history detail displays its saved inputs', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DetailHistoryScreen(
          history: HistoryModel(
            id: 'nest-history',
            jenisKalkulator: 'NEST',
            hasil: 3412,
            createdAt: DateTime(2026, 10, 8),
            open: 3260,
            close: 3412,
            indikasi: 'SELL',
          ),
        ),
      ),
    );

    expect(find.text('Data Harga'), findsOneWidget);
    expect(find.text('Data Emas Fisik'), findsNothing);
    expect(find.text('3.260,00'), findsOneWidget);
    expect(find.text('3.412,00'), findsOneWidget);
    expect(find.text('SELL'), findsOneWidget);
  });
}
