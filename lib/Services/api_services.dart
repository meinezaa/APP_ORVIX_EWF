import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../Models/gold_data.dart';

class ApiService {
  /// Mengambil seluruh data LGD Daily dari API resmi NewsMaker.
  static Future<List<GoldHistory>> getGoldHistory({int maxPages = 10}) async {
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

      return rows
          .whereType<Map<String, dynamic>>()
          .where((row) => row['category'] == 'LGD Daily')
          .map(
            (row) => GoldHistory(
              date: row['tanggal']?.toString() ?? '',
              open: _parseNumber(row['open']),
              high: _parseNumber(row['high']),
              low: _parseNumber(row['low']),
              close: _parseNumber(row['close']),
            ),
          )
          .where((item) => item.date.isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('Error fetching historical data: $e');
      throw Exception('Tidak dapat mengambil historical data. $e');
    }
  }

  static double _parseNumber(Object? value) {
    return double.tryParse(
          value?.toString().trim().replaceAll(',', '') ?? '',
        ) ??
        0.0;
  }
}
