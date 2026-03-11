import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:pulsecare/model/ai_summary_model.dart';
import 'package:pulsecare/data/datasources/ai_summary_datasource.dart';

class AISummaryRepository extends ChangeNotifier {
  final AISummaryDataSource _dataSource;
  final FirebaseFirestore _firestore;

  AISummaryRepository._privateConstructor(this._dataSource, this._firestore);

  static AISummaryRepository? _instance;

  factory AISummaryRepository([
    AISummaryDataSource? dataSource,
    FirebaseFirestore? firestore,
  ]) {
    _instance ??= AISummaryRepository._privateConstructor(
      dataSource ?? LocalAISummaryDataSource(),
      firestore ?? FirebaseFirestore.instance,
    );
    return _instance!;
  }

  CollectionReference<Map<String, dynamic>> get _summaries =>
      _firestore.collection('ai_summaries');

  AISummaryModel addSummary(AISummaryModel summary) {
    final storedSummary = _dataSource.addSummary(summary);
    _upsertRemote(storedSummary);
    notifyListeners();
    return storedSummary;
  }

  Future<AISummaryModel> addSummaryAsync(AISummaryModel summary) async {
    final storedSummary = _dataSource.addSummary(summary);
    await _upsertRemote(storedSummary);
    notifyListeners();
    return storedSummary;
  }

  AISummaryModel? getById(String id) {
    return _dataSource.getById(id);
  }

  Future<AISummaryModel?> getByIdAsync(String id) async {
    final local = _dataSource.getById(id);
    if (local != null) {
      return local;
    }

    final snapshot = await _summaries.doc(id).get();
    if (!snapshot.exists || snapshot.data() == null) {
      return null;
    }

    final map = _normalizeMap(snapshot.data()!);
    map['id'] = snapshot.id;
    final summary = AISummaryModel.fromJson(map);
    _dataSource.addSummary(summary);
    return summary;
  }

  List<AISummaryModel> getByUserId(String userId) {
    return _dataSource.getByUserId(userId);
  }

  Future<List<AISummaryModel>> getByUserIdAsync(String userId) async {
    final query = await _summaries.where('userId', isEqualTo: userId).get();
    final summaries = query.docs
        .map((doc) {
          final map = _normalizeMap(doc.data());
          map['id'] = doc.id;
          return AISummaryModel.fromJson(map);
        })
        .toList(growable: false);

    for (final summary in summaries) {
      _dataSource.addSummary(summary);
    }
    return summaries;
  }

  void remove(String id) {
    _dataSource.remove(id);
    _summaries.doc(id).delete();
    notifyListeners();
  }

  List<AISummaryModel> getAll() {
    return _dataSource.getAll();
  }

  Future<void> _upsertRemote(AISummaryModel summary) async {
    await _summaries
        .doc(summary.id)
        .set(summary.toJson(), SetOptions(merge: true));
  }

  Map<String, dynamic> _normalizeMap(Map<String, dynamic> raw) {
    final map = Map<String, dynamic>.from(raw);
    if (map['generatedAt'] is Timestamp) {
      map['generatedAt'] = (map['generatedAt'] as Timestamp)
          .toDate()
          .toIso8601String();
    }
    return map;
  }
}
