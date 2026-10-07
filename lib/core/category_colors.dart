import 'package:flutter/material.dart';

const _palette = <Color>[
  Color(0xFF2A9D8F),
  Color(0xFFE76F51),
  Color(0xFF264653),
  Color(0xFFE9C46A),
  Color(0xFF8E7DBE),
  Color(0xFF4D908E),
  Color(0xFFF4A261),
  Color(0xFF577590),
  Color(0xFFB56576),
  Color(0xFF90A955),
];

/// Stable colour per category id so the list, legend and chart agree.
Color categoryColor(int categoryId) => _palette[categoryId % _palette.length];
