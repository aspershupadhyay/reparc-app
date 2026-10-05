import 'package:drift/drift.dart';

/// Emits [load] now and again after each change to [tables].
Stream<T> watchTables<T>(
  DatabaseConnectionUser db,
  Iterable<ResultSetImplementation<dynamic, dynamic>> tables,
  Future<T> Function() load,
) async* {
  yield await load();
  await for (final _ in db.tableUpdates(TableUpdateQuery.onAllTables(tables))) {
    yield await load();
  }
}
