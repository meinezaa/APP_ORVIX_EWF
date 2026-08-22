import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:flutter/foundation.dart';
import '../models/gold_data.dart';

class ApiService {
  /// Mengambil data dari beberapa halaman/slide newsmaker.id sekaligus
  static Future<List<GoldHistory>> getGoldHistory({int maxPages = 10}) async {
    List<GoldHistory> fetchedData = [];
    Set<String> seenDates = {}; // Mencegah tanggal duplikat
    const baseUrl =
        'https://www.newsmaker.id/index.php/id/tools/historical-data-2';

    for (int page = 1; page <= maxPages; page++) {
      int offset = (page - 1) * 10;

      // Mengakses pagination via query parameter (?start=X&page=Y)
      final rawUrl = page == 1 ? baseUrl : '$baseUrl?start=$offset&page=$page';

      final url = kIsWeb
          ? Uri.parse('https://corsproxy.io/?${Uri.encodeComponent(rawUrl)}')
          : Uri.parse(rawUrl);

      try {
        final response = await http.get(
          url,
          headers: {
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          },
        );

        if (response.statusCode == 200) {
          var document = parser.parse(response.body);
          var rows = document.querySelectorAll('table tbody tr');

          int newRowsInThisPage = 0;

          for (var row in rows) {
            var columns = row.querySelectorAll('td');
            if (columns.length >= 5) {
              String date = columns[0].text.trim().replaceAll('\u00a0', ' ');
              double open =
                  double.tryParse(columns[1].text.trim().replaceAll(',', '')) ??
                  0.0;
              double high =
                  double.tryParse(columns[2].text.trim().replaceAll(',', '')) ??
                  0.0;
              double low =
                  double.tryParse(columns[3].text.trim().replaceAll(',', '')) ??
                  0.0;
              double close =
                  double.tryParse(columns[4].text.trim().replaceAll(',', '')) ??
                  0.0;

              // Masukkan hanya jika tanggal belum ada di daftar
              if (date.isNotEmpty && !seenDates.contains(date)) {
                seenDates.add(date);
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
          }

          // Jika halaman tidak menghasilkan data baru lagi, hentikan pengambilan
          if (newRowsInThisPage == 0) break;
        } else {
          break;
        }
      } catch (e) {
        debugPrint('Error fetching page $page: $e');
        break;
      }
    }

    return fetchedData;
  }
}
