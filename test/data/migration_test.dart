import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stick/data/database.dart' as db_;
import 'package:stick/data/repository.dart';

import '../generated_migrations/schema.dart';
import '../generated_migrations/schema_v1.dart' as v1;

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;

  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));

  test('schema 1 to 2 keeps the habit and fills the new fields', () async {
    final schema = await verifier.schemaAt(1);
    final old = v1.DatabaseAtV1(schema.newConnection());
    final created = DateTime(2026, 11, 20, 9).millisecondsSinceEpoch ~/ 1000;
    await old.customStatement(
      'INSERT INTO habits (id, name, tiny, why, reminder_minutes, created_at) '
      "VALUES (1, 'Walk', 'Shoes on', 'x', 480, $created)",
    );
    await old.customStatement(
      'INSERT INTO attempts (number, start_day, quit_target) '
      "VALUES (1, '2026-11-20', 3)",
    );
    await old.customStatement('INSERT INTO flags (id) VALUES (1)');
    await old.close();

    final db = db_.StickDatabase.forTesting(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 2);

    final h = (await StickRepository(db).load())!.habit;
    expect(h.name, 'Walk');
    expect(h.tiny, 'Shoes on');
    expect(h.emoji, '⭐');
    expect(h.templateId, isNull);
    expect(h.quizQuitDay, isNull);
    expect(h.quizReason, isNull);
  });
}
