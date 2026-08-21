class GoldHistory {
  final String date;
  final double open;
  final double high;
  final double low;
  final double close;

  GoldHistory({
    required this.date,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
  });

  factory GoldHistory.fromJson(Map<String, dynamic> json) {
    return GoldHistory(
      date: json['date'] ?? '',
      open: (json['open'] as num?)?.toDouble() ?? 0.0,
      high: (json['high'] as num?)?.toDouble() ?? 0.0,
      low: (json['low'] as num?)?.toDouble() ?? 0.0,
      close: (json['close'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
