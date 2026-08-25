import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:flutter/foundation.dart';
import '../models/gold_data.dart';

class ApiService {
  /// Mengambil data dari halaman tabel historical data.
  static Future<List<GoldHistory>> getGoldHistory({int maxPages = 10}) async {
    final fetchedData = <GoldHistory>[];
    final seenDates = <String>{};
    const baseUrl = 'https://newsmaker.id/id/tools/historical-data';

    for (int page = 1; page <= maxPages; page++) {
      final offset = (page - 1) * 10;
      final rawUrl = page == 1 ? baseUrl : '$baseUrl?start=$offset';
      final url = kIsWeb
          ? Uri.parse('https://corsproxy.io/?${Uri.encodeComponent(rawUrl)}')
          : Uri.parse(rawUrl);

      try {
        final response = await http
            .get(
              url,
              headers: const {
                'User-Agent':
                    'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 Chrome/120.0 Mobile Safari/537.36',
                'Accept': 'text/html,application/xhtml+xml',
              },
            )
            .timeout(const Duration(seconds: 15));

        if (response.statusCode != 200) {
          throw Exception('Server mengembalikan status ${response.statusCode}');
        }

        final document = parser.parse(response.body);
        final tableRows = document.querySelectorAll('table tbody tr');
        final rows = tableRows.isNotEmpty
            ? tableRows
            : document.querySelectorAll('table tr');
        var newRowsInThisPage = 0;

        for (final row in rows) {
          final columns = row.querySelectorAll('td');
          if (columns.length < 5) continue;

          final date = columns[0].text.trim().replaceAll('\u00a0', ' ');
          final open = _parseNumber(columns[1].text);
          final high = _parseNumber(columns[2].text);
          final low = _parseNumber(columns[3].text);
          final close = _parseNumber(columns[4].text);

          if (date.isNotEmpty && seenDates.add(date)) {
            fetchedData.add(
              GoldHistory(
                date: date,
                open: open,
                high: high,
                low: low,
                close: close,
              ),
            );
            newRowsInThisPage++;
          }
        }

        if (newRowsInThisPage == 0) break;
      } catch (e) {
        debugPrint('Error fetching page $page: $e');
        if (fetchedData.isEmpty) {
          throw Exception('Tidak dapat mengambil historical data. $e');
        }
        break;
      }
    }

    return fetchedData;
  }

  static double _parseNumber(String value) {
    return double.tryParse(value.trim().replaceAll(',', '')) ?? 0.0;
  }
}
