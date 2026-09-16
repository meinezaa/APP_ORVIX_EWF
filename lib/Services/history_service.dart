import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../Models/historikalkulator_model.dart';

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
    String? category,
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

    final currentUser = _auth.currentUser;
    String userName = currentUser?.displayName ?? '';
    String role = 'staff';
    String? email = currentUser?.email;

    if (currentUser != null) {
      final profile = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();
      final data = profile.data();
      userName = (data?['nama'] ?? currentUser.displayName ?? '').toString();
      role = (data?['role'] ?? 'staff').toString();
      email = (data?['email'] ?? currentUser.email)?.toString();
    }

    final history = HistoryModel(
      id: '',
      jenisKalkulator: jenisKalkulator,
      hasil: hasil,
      createdAt: DateTime.now(),
      userId: currentUser?.uid ?? '',
      userName: userName,
      role: role,
      email: email,
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
      kategori: category,
    );

    final payload = history.toMap();
    payload['jenisKalkulator'] = jenisKalkulator;
    payload['createdAt'] = Timestamp.fromDate(history.createdAt);
    payload['category'] = category;
    payload['kategori'] = category;

    await collection.add(payload);
  }
}
