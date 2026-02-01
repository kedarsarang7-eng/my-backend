// ============================================================================
// NATIVE DATABASE CONNECTION
// ============================================================================
// Database connection for mobile and desktop platforms
//
// Author: DukanX Engineering
// Version: 1.0.0
// ============================================================================

import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/foundation.dart';

/// Opens a native database connection for mobile/desktop platforms
QueryExecutor openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'dukanx_enterprise.sqlite'));
    debugPrint('AppDatabase: Opening native database at ${file.path}');
    return NativeDatabase.createInBackground(file);
  });
}
