// lib/data/pg_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../features/admin/admin_models.dart';

class PgQuery {
  final String city;
  final bool onlyActive;
  final String? genderTag;
  final int? budgetMin;
  final int? budgetMax;
  final List<String>? amenitiesAny;
  final List<String>? servicesAny;
  final String sort;
  final String? searchText;

  const PgQuery({
    required this.city,
    this.onlyActive = true,
    this.genderTag,
    this.budgetMin,
    this.budgetMax,
    this.amenitiesAny,
    this.servicesAny,
    this.sort = 'priceAsc',
    this.searchText,
  });
}

class PgRepository {
  final CollectionReference _col =
  FirebaseFirestore.instance.collection('pgs');

  Stream<List<AdminPg>> streamPgs(PgQuery q, {int limit = 50}) {
    Query ref = _col;

    ref = ref.where('cityKey', isEqualTo: q.city.toLowerCase());
    if (q.onlyActive) ref = ref.where('isActive', isEqualTo: true);

    if (q.genderTag != null && q.genderTag!.toLowerCase() != 'any') {
      ref = ref.where('genderTag', isEqualTo: q.genderTag);
    }

    if (q.budgetMin != null) {
      ref = ref.where('price4x', isGreaterThanOrEqualTo: q.budgetMin);
    }
    if (q.budgetMax != null) {
      ref = ref.where('price4x', isLessThanOrEqualTo: q.budgetMax);
    }

    if (q.amenitiesAny != null && q.amenitiesAny!.isNotEmpty) {
      ref = ref.where('amenities', arrayContainsAny: q.amenitiesAny);
    }
    if (q.servicesAny != null && q.servicesAny!.isNotEmpty) {
      ref = ref.where('services', arrayContainsAny: q.servicesAny);
    }

    switch (q.sort) {
      case 'priceDesc':
        ref = ref.orderBy('price4x', descending: true);
        break;
      case 'newest':
        ref = ref.orderBy('createdAt', descending: true);
        break;
      default:
        ref = ref.orderBy('price4x');
    }

    ref = ref.limit(limit);

    return ref.snapshots().map((snap) {
      final list = snap.docs
          .map((d) => AdminPg.fromFirestore(
          d as DocumentSnapshot<Map<String, dynamic>>))
          .toList();

      final s = (q.searchText ?? '').trim().toLowerCase();
      if (s.isEmpty) return list;
      return list
          .where((pg) =>
      pg.name.toLowerCase().contains(s) ||
          pg.area.toLowerCase().contains(s))
          .toList();
    });
  }

  Future<AdminPg?> getById(String id) async {
    final doc =
    await _col.doc(id).get() as DocumentSnapshot<Map<String, dynamic>>;
    if (!doc.exists) return null;
    return AdminPg.fromFirestore(doc);
  }
}
