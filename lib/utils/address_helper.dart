// lib/utils/address_helper.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';

Future<String> getAddressFromGeoPoint(GeoPoint point) async {
  try {
    final placemarks = await placemarkFromCoordinates(
      point.latitude,
      point.longitude,
    );
    if (placemarks.isNotEmpty) {
      final p = placemarks.first;
      return "${p.locality ?? ''}, ${p.subAdministrativeArea ?? ''}, ${p.administrativeArea ?? ''}";
    }
  } catch (e) {
    // ignore and return fallback
  }
  return "Unknown location";
}
