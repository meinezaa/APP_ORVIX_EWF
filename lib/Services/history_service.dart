import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../Models/histori_model.dart';

class HistoryService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static CollectionReference<Map<String, dynamic>>? get _userHistory {
    final user = _auth.currentUser;
    if (user == null) return null;
    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('calculation_history');
  }

  static Stream<List<HistoryModel>> watchHistory() {
    final collection = _userHistory;
    if (collection == null) {
      return Stream.value(const <HistoryModel>[]);
    }

    return collection
        .orderBy('created_at', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(HistoryModel.fromFirestore).toList(),
        );
  }

  static Future<void> saveCalculation({
    required String jenisKalkulator,
    required double hasil,
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
  }) async {
    final collection = _userHistory;
    if (collection == null) return;

    final history = HistoryModel(
      id: '',
      jenisKalkulator: jenisKalkulator,
      hasil: hasil,
      createdAt: DateTime.now(),
      open: open,
      high: high,
      low: low,
      close: close,
      indikasi: indikasi,
      modal: modal,
      hargaBeli: hargaBeli,
      hargaJual: hargaJual,
      toz: toz,
      kurs: kurs,
      hargaBeliPerGram: hargaBeliPerGram,
      hargaJualPerGram: hargaJualPerGram,
      selisihPerGram: selisihPerGram,
      jumlahEmas: jumlahEmas,
    );
    await collection.add(history.toMap());
  }
}
