
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:verifier_facl/core/services/database/app_database.dart';
import 'package:verifier_facl/core/utils/constants.dart';

final databaseFutureProvider = FutureProvider<AppDatabase>((ref) async {
  return await initDatabase();
});

final databaseProvider = Provider<AppDatabase>((ref) {
  final dbAsyncValue = ref.watch(databaseFutureProvider);
  return dbAsyncValue.when(
    data: (db) => db,
    loading: () => throw Exception("Database not initialized yet"),
    error: (err, stack) => throw Exception("Database failed to initialize: $err"),
  );
});

Future<AppDatabase> initDatabase() async {
  return await $FloorAppDatabase
      .databaseBuilder(AppConstants.databaseName)
      .build();
}

