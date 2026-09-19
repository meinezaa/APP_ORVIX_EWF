import 'package:cloud_firestore/cloud_firestore.dart';

class HistoryModel {
  final String id;
  final String jenisKalkulator;
  final double hasil;
  final DateTime createdAt;
  final String userId;
  final String userName;
  final String role;
  final String? email;
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
  final String? kategori;

  HistoryModel({
    required this.id,
    required this.jenisKalkulator,
    required this.hasil,
    required this.createdAt,
    this.userId = '',
    this.userName = '',
    this.role = 'staff',
    this.email,
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
    this.kategori,
  });

  factory HistoryModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return HistoryModel.fromMap(doc.data() ?? {}, id: doc.id);
  }

  factory HistoryModel.fromMap(Map<String, dynamic> data, {String id = ''}) {
    DateTime parseDate(dynamic date) {
      if (date is Timestamp) return date.toDate();
      if (date is String) return DateTime.tryParse(date) ?? DateTime.now();
      if (date is DateTime) return date;
      return DateTime.now();
    }

    return HistoryModel(
      id: id,
      jenisKalkulator: data['jenis_kalkulator']?.toString() ?? '',
      hasil: (data['hasil'] as num?)?.toDouble() ?? 0,
      createdAt: parseDate(data['created_at']),
      userId: data['user_id']?.toString() ?? '',
      userName: data['user_name']?.toString() ?? '',
      role: data['role']?.toString() ?? 'staff',
      email: data['email']?.toString(),
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
      kategori: data['kategori']?.toString() ?? data['category']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'user_name': userName,
      'role': role,
      'email': email,
      'jenis_kalkulator': jenisKalkulator,
      'jenisKalkulator': jenisKalkulator,
      'kategori': kategori,
      'category': kategori,
      'hasil': hasil,
      'created_at': Timestamp.fromDate(createdAt),
      'createdAt': Timestamp.fromDate(createdAt),
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

  HistoryModel copyWith({
    String? id,
    String? jenisKalkulator,
    double? hasil,
    DateTime? createdAt,
    String? userId,
    String? userName,
    String? role,
    String? email,
    double? open,
    double? high,
    double? low,
    double? close,
    String? indikasi,
    double? modal,
    double? hargaBeli,
    double? hargaJual,
    double? toz,
    double? kurs,
    double? hargaBeliPerGram,
    double? hargaJualPerGram,
    double? selisihPerGram,
    double? jumlahEmas,
    String? kategori,
  }) {
    return HistoryModel(
      id: id ?? this.id,
      jenisKalkulator: jenisKalkulator ?? this.jenisKalkulator,
      hasil: hasil ?? this.hasil,
      createdAt: createdAt ?? this.createdAt,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      role: role ?? this.role,
      email: email ?? this.email,
      open: open ?? this.open,
      high: high ?? this.high,
      low: low ?? this.low,
      close: close ?? this.close,
      indikasi: indikasi ?? this.indikasi,
      modal: modal ?? this.modal,
      hargaBeli: hargaBeli ?? this.hargaBeli,
      hargaJual: hargaJual ?? this.hargaJual,
      toz: toz ?? this.toz,
      kurs: kurs ?? this.kurs,
      hargaBeliPerGram: hargaBeliPerGram ?? this.hargaBeliPerGram,
      hargaJualPerGram: hargaJualPerGram ?? this.hargaJualPerGram,
      selisihPerGram: selisihPerGram ?? this.selisihPerGram,
      jumlahEmas: jumlahEmas ?? this.jumlahEmas,
      kategori: kategori ?? this.kategori,
    );
  }
}
