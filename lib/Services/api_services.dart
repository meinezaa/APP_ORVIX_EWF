import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../Models/historidata_model.dart';

class ApiService {
  static const List<String> supportedCategories = ['LGD', 'HSI', 'SNI'];

  static String normalizeCategoryName(String? rawCategory) {
    final value = (rawCategory ?? '').trim();
    if (value.isEmpty) return '';

    final upper = value.toUpperCase();

    if (upper.contains('LGD')) return 'LGD';
    if (upper.contains('HSI')) return 'HSI';
    if (upper.contains('SNI') ||
        upper.contains('JEP') ||
        upper.contains('N225') ||
        upper.contains('USD/JPY')) {
      return 'SNI';
    }

    return upper;
  }

  static Future<List<GoldHistory>> getGoldHistory({
    int maxPages = 10,
    String category = 'LGD',
  }) async {
    try {
      const rawUrl = 'https://www.newsmaker.id/api/historical-data';
      final url = kIsWeb
          ? Uri.parse('https://corsproxy.io/?${Uri.encodeComponent(rawUrl)}')
          : Uri.parse(rawUrl);
      final response = await http
          .get(url, headers: const {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Exception('Server mengembalikan status ${response.statusCode}');
      }

      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      final rows = payload['data'];
      if (rows is! List) return [];

      final normalizedCategory = normalizeCategoryName(category);

      final mapped = rows
          .whereType<Map<String, dynamic>>()
          .where((row) {
            final rowCategory = normalizeCategoryName(
              row['category']?.toString(),
            );
            return rowCategory == normalizedCategory;
          })
          .map(
            (row) => GoldHistory(
              date: row['tanggal']?.toString() ?? '',
              category: normalizeCategoryName(row['category']?.toString()),
              open: parseNumber(row['open']),
              high: parseNumber(row['high']),
              low: parseNumber(row['low']),
              close: parseNumber(row['close']),
            ),
          )
          .where((item) => item.date.isNotEmpty)
          .toList();

      return collapseDuplicateDates(mapped);
    } catch (e) {
      debugPrint('Error fetching historical data: $e');
      throw Exception('Tidak dapat mengambil historical data. $e');
    }
  }

  static List<GoldHistory> collapseDuplicateDates(List<GoldHistory> rows) {
    final byDate = <String, GoldHistory>{};

    for (final row in rows) {
      final existing = byDate[row.date];
      if (existing == null) {
        byDate[row.date] = row;
        continue;
      }

      final currentScore = _rowDataQuality(row);
      final existingScore = _rowDataQuality(existing);
      if (currentScore > existingScore) {
        byDate[row.date] = row;
      }
    }

    final list = byDate.values.toList();
    list.sort((a, b) {
      final aDate = DateTime.tryParse(a.date);
      final bDate = DateTime.tryParse(b.date);
      if (aDate == null || bDate == null) return 0;
      return aDate.compareTo(bDate);
    });
    return list;
  }

  static int _rowDataQuality(GoldHistory row) {
    int score = 0;
    if (row.open > 0) score++;
    if (row.high > 0) score++;
    if (row.low > 0) score++;
    if (row.close > 0) score++;
    return score;
  }

  static double parseNumber(Object? value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();

    String text = value.toString().trim();
    if (text.isEmpty || text == 'null' || text == 'NULL') return 0.0;

    text = text.replaceAll(RegExp(r'\s+'), '');
    if (text.isEmpty) return 0.0;

    final hasDot = text.contains('.');
    final hasComma = text.contains(',');

    if (hasDot && hasComma) {
      final lastDot = text.lastIndexOf('.');
      final lastComma = text.lastIndexOf(',');
      if (lastComma > lastDot) {
        text = text.replaceAll('.', '').replaceAll(',', '.');
      } else {
        text = text.replaceAll(',', '');
      }
    } else if (hasComma) {
      final commaParts = text.split(',');
      if (commaParts.length > 2) {
        text = text.replaceAll(',', '');
      } else {
        final partAfterComma = commaParts.length > 1 ? commaParts[1] : '';
        if (partAfterComma.length == 3 &&
            int.tryParse(partAfterComma) != null) {
          text = '${commaParts[0]}$partAfterComma';
        } else {
          text = text.replaceAll(',', '.');
        }
      }
    }

    text = text.replaceAll(RegExp(r'[^0-9\.\-]'), '');
    if (text.isEmpty) return 0.0;

    return double.tryParse(text) ?? 0.0;
  }
}
