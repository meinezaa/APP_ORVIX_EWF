import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/gold_data.dart';

class ApiService {
  // Ganti dengan URL Endpoint API News Maker yang kamu gunakan
  static const String _baseUrl = 'https://api.newsmaker.id/v1';

  static Future<List<GoldHistory>> getGoldHistory(
    String startDate,
    String endDate,
  ) async {
    final url = Uri.parse(
      '$_baseUrl/gold-history?start_date=$startDate&end_date=$endDate',
    );

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          // 'Authorization': 'Bearer YOUR_API_KEY', // Buka komentar jika API pakai Key
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(response.body);
        final List<dynamic> data = body['data'];

        return data.map((item) => GoldHistory.fromJson(item)).toList();
      } else {
        throw Exception('Gagal mengambil data dari server');
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan jaringan: $e');
    }
  }
}
