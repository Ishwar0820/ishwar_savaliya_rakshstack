// lib/features/pg/pg_models.dart
import 'package:flutter/foundation.dart';

@immutable
class PgDetailData {
  final String name;
  final String city;
  final String area;
  final String address;
  final String genderTag;
  final List<String> images;
  final List<String> priceChips;
  final List<String> amenities;
  final List<String> services;

  const PgDetailData({
    required this.name,
    required this.city,
    required this.area,
    required this.address,
    required this.genderTag,
    required this.images,
    required this.priceChips,
    required this.amenities,
    required this.services,
  });
}
