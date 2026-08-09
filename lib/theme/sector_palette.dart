import 'package:flutter/material.dart';

import '../data/sample_places.dart';

/// Two-stop gradients giving each Nkolmbong sector a distinct, consistent
/// color identity across the sectors list and sector detail pages.
const sectorPalette = [
  [Color(0xFF00532A), Color(0xFF007A3D)],
  [Color(0xFFB00020), Color(0xFFCE1126)],
  [Color(0xFF0D47A1), Color(0xFF1976D2)],
  [Color(0xFFE65100), Color(0xFFEF6C00)],
  [Color(0xFF4A148C), Color(0xFF8E24AA)],
  [Color(0xFF004D40), Color(0xFF00897B)],
];

List<Color> sectorColors(String sector) {
  final index = nkolmbongSectors.indexOf(sector);
  return sectorPalette[(index < 0 ? 0 : index) % sectorPalette.length];
}

/// Filesystem-friendly slug (e.g. `San Francisco` -> `san_francisco`) used
/// to namespace each sector's place photos under `assets/places/<slug>/`.
String sectorSlug(String sector) {
  final slug = sector.toLowerCase().trim().replaceAll(RegExp(r"[^a-z0-9]+"), '_');
  return slug.replaceAll(RegExp(r'^_+|_+$'), '');
}
