import 'package:cloud_firestore/cloud_firestore.dart';

class HistoryModel {
  final String id;
  final String jenisKalkulator;
  final double hasil;
  final DateTime createdAt;
  final double? open;
  final double? high;
  final double? low;
  final double? close;
  final String? indikasi;
  final double? modal;
  final double? hargaBeli;
  final double? hargaJual;
  final double? toz;
  final double? kurs;
  final double? hargaBeliPerGram;
  final double? hargaJualPerGram;
  final double? selisihPerGram;
  final double? jumlahEmas;

  HistoryModel({
    required this.id,
    required this.jenisKalkulator,
    required this.hasil,
    required this.createdAt,
    this.open,
    this.high,
    this.low,
    this.close,
    this.indikasi,
    this.modal,
    this.hargaBeli,
    this.hargaJual,
    this.toz,
    this.kurs,
    this.hargaBeliPerGram,
    this.hargaJualPerGram,
    this.selisihPerGram,
    this.jumlahEmas,
  });

  // Konversi dari data Firestore ke Object Model Dart
  factory HistoryModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return HistoryModel(
      id: doc.id,
      jenisKalkulator: data['jenis_kalkulator']?.toString() ?? '',
      hasil: (data['hasil'] as num?)?.toDouble() ?? 0,
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      open: (data['open'] as num?)?.toDouble(),
      high: (data['high'] as num?)?.toDouble(),
      low: (data['low'] as num?)?.toDouble(),
      close: (data['close'] as num?)?.toDouble(),
      indikasi: data['indikasi']?.toString(),
      modal: (data['modal'] as num?)?.toDouble(),
      hargaBeli: (data['harga_beli'] as num?)?.toDouble(),
      hargaJual: (data['harga_jual'] as num?)?.toDouble(),
      toz: (data['toz'] as num?)?.toDouble(),
      kurs: (data['kurs'] as num?)?.toDouble(),
      hargaBeliPerGram: (data['harga_beli_per_gram'] as num?)?.toDouble(),
      hargaJualPerGram: (data['harga_jual_per_gram'] as num?)?.toDouble(),
      selisihPerGram: (data['selisih_per_gram'] as num?)?.toDouble(),
      jumlahEmas: (data['jumlah_emas'] as num?)?.toDouble(),
    );
  }

  // Konversi dari Object Model Dart ke Map Firebase
  Map<String, dynamic> toMap() {
    return {
      'jenis_kalkulator': jenisKalkulator,
      'hasil': hasil,
      'created_at': Timestamp.fromDate(createdAt),
      'open': open,
      'high': high,
      'low': low,
      'close': close,
      'indikasi': indikasi,
      'modal': modal,
      'harga_beli': hargaBeli,
      'harga_jual': hargaJual,
      'toz': toz,
      'kurs': kurs,
      'harga_beli_per_gram': hargaBeliPerGram,
      'harga_jual_per_gram': hargaJualPerGram,
      'selisih_per_gram': selisihPerGram,
      'jumlah_emas': jumlahEmas,
    };
  }
}
