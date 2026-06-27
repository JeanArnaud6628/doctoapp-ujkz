import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

void main() {
  // ✅ Lancer l'application SANS Supabase
  runApp(
    const ProviderScope(
      child: DoctoApp(),
    ),
  );
}