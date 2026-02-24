import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/recycleingcenter_model.dart';

final centersRepositoryProvider = Provider((ref) => CentersRepository());

class CentersRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<RecyclingCenterModel>> getCentersStream() {
    return _firestore
        .collection('recyclingCenters')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RecyclingCenterModel.fromMap(doc.data()))
            .toList());
  }
}