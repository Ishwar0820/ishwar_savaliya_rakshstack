// lib/features/admin/admin_models.dart
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

@immutable
class AdminPg {
  final String id;
  final String name;
  final String city;
  final String area;
  final String address;
  final String genderTag;

  final int price2x;
  final int price3x;
  final int price4x;

  final bool hidden;

  final List<String> images;
  final List<String> amenities;
  final List<String> services;

  final String ownerName;
  final String ownerPhone;

  const AdminPg({
    required this.id,
    required this.name,
    required this.city,
    required this.area,
    required this.address,
    required this.genderTag,
    this.price2x = 0,
    this.price3x = 0,
    this.price4x = 0,
    required this.hidden,
    required this.images,
    this.amenities = const [],
    this.services = const [],
    this.ownerName = '',
    this.ownerPhone = '',
  });

  int get minPrice {
    final vals = <int>[price2x, price3x, price4x].where((e) => e > 0).toList();
    if (vals.isEmpty) return 0;
    vals.sort();
    return vals.first;
  }

  AdminPg copyWith({
    String? id,
    String? name,
    String? city,
    String? area,
    String? address,
    String? genderTag,
    int? price2x,
    int? price3x,
    int? price4x,
    bool? hidden,
    List<String>? images,
    List<String>? amenities,
    List<String>? services,
    String? ownerName,
    String? ownerPhone,
  }) {
    return AdminPg(
      id: id ?? this.id,
      name: name ?? this.name,
      city: city ?? this.city,
      area: area ?? this.area,
      address: address ?? this.address,
      genderTag: genderTag ?? this.genderTag,
      price2x: price2x ?? this.price2x,
      price3x: price3x ?? this.price3x,
      price4x: price4x ?? this.price4x,
      hidden: hidden ?? this.hidden,
      images: images ?? this.images,
      amenities: amenities ?? this.amenities,
      services: services ?? this.services,
      ownerName: ownerName ?? this.ownerName,
      ownerPhone: ownerPhone ?? this.ownerPhone,
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'city': city,
    'area': area,
    'address': address,
    'genderTag': genderTag, // "Any" | "Male" | "Female"
    'price2x': price2x,
    'price3x': price3x,
    'price4x': price4x,
    'hidden': hidden,
    'isActive': !hidden,
    'images': images,
    'amenities': amenities,
    'services': services,
    'ownerName': ownerName,
    'ownerPhone': ownerPhone,
    'updatedAt': FieldValue.serverTimestamp(),
    // create flows me include; update me optional
    'createdAt': FieldValue.serverTimestamp(),
  };

  // ---------- READ HELPERS ----------

  factory AdminPg.fromDoc(DocumentSnapshot d) {
    final m = d.data() as Map<String, dynamic>? ?? const {};
    int _toInt(dynamic v) => (v is int) ? v : int.tryParse('${v ?? 0}') ?? 0;

    final images = (m['images'] as List?)
        ?.map((e) => '$e'.trim())
        .where((s) => s.isNotEmpty)
        .toList() ??
        const <String>[];

    return AdminPg(
      id: d.id,
      name: (m['name'] ?? '').toString(),
      city: (m['city'] ?? '').toString(),
      area: (m['area'] ?? '').toString(),
      address: (m['address'] ?? '').toString(),
      genderTag: (m['genderTag'] ?? 'Any').toString(),
      price2x: _toInt(m['price2x']),
      price3x: _toInt(m['price3x']),
      price4x: _toInt(m['price4x']),
      // prefer explicit 'hidden'; else derive from isActive
      hidden: (m['hidden'] ?? !(m['isActive'] ?? true)) == true,
      images: images,
      amenities: (m['amenities'] as List?)?.map((e) => '$e').toList() ?? const [],
      services: (m['services'] as List?)?.map((e) => '$e').toList() ?? const [],
      ownerName: (m['ownerName'] ?? '').toString(),
      ownerPhone: (m['ownerPhone'] ?? '').toString(),
    );
  }

  factory AdminPg.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? <String, dynamic>{};
    int _toInt(dynamic v) => (v is int) ? v : int.tryParse('${v ?? 0}') ?? 0;

    return AdminPg(
      id: doc.id,
      name: (d['name'] ?? '').toString(),
      city: (d['city'] ?? '').toString(),
      area: (d['area'] ?? '').toString(),
      address: (d['address'] ?? '').toString(),
      genderTag: (d['genderTag'] ?? 'Any').toString(),
      price2x: _toInt(d['price2x']),
      price3x: _toInt(d['price3x']),
      price4x: _toInt(d['price4x']),
      hidden: (d['hidden'] ?? !(d['isActive'] ?? true)) == true,
      images: List<String>.from(d['images'] ?? const []),
      amenities: List<String>.from(d['amenities'] ?? const []),
      services: List<String>.from(d['services'] ?? const []),
      ownerName: (d['ownerName'] ?? '').toString(),
      ownerPhone: (d['ownerPhone'] ?? '').toString(),
    );
  }
}
