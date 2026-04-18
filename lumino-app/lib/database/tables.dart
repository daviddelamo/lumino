import 'package:drift/drift.dart';

class Tasks extends Table {
  TextColumn get id => text().clientDefault(() => _uuid())();
  TextColumn get userId => text()();
  TextColumn get title => text()();
  TextColumn get iconId => text().withDefault(const Constant('circle'))();
  TextColumn get color => text().withDefault(const Constant('#E8823A'))();
  DateTimeColumn get startAt => dateTime()();
  DateTimeColumn get endAt => dateTime().nullable()();
  TextColumn get repeatRule => text().nullable()();
  IntColumn get reminderOffsetMin => integer().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get dirty => boolean().withDefault(const Constant(true))();
  DateTimeColumn get syncedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class Habits extends Table {
  TextColumn get id => text().clientDefault(() => _uuid())();
  TextColumn get userId => text()();
  TextColumn get title => text()();
  TextColumn get iconId => text().withDefault(const Constant('circle'))();
  TextColumn get color => text().withDefault(const Constant('#E8823A'))();
  TextColumn get type => text()(); // bool | count | duration
  RealColumn get targetValue => real().withDefault(const Constant(1.0))();
  TextColumn get unit => text().nullable()();
  TextColumn get frequencyRule => text()();
  TextColumn get reminderTime => text().nullable()(); // HH:mm
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get archivedAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get dirty => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

class HabitEntries extends Table {
  TextColumn get id => text().clientDefault(() => _uuid())();
  TextColumn get habitId => text().references(Habits, #id)();
  DateTimeColumn get entryDate => dateTime()();
  RealColumn get value => real().withDefault(const Constant(1.0))();
  TextColumn get note => text().nullable()();
  DateTimeColumn get loggedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get dirty => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
        {habitId, entryDate}
      ];
}

class Users extends Table {
  TextColumn get id => text()();
  TextColumn get email => text().nullable()();
  TextColumn get displayName => text().nullable()();
  TextColumn get onboardingProfile => text().nullable()(); // JSON
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

String _uuid() => generateUuid();

String generateUuid() {
  final now = DateTime.now().microsecondsSinceEpoch;
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replaceAllMapped(
    RegExp(r'[xy]'),
    (m) {
      final r = (now ^ (m.start * 1000)) % 16;
      return (m[0] == 'x' ? r : (r & 0x3 | 0x8)).toRadixString(16);
    },
  );
}
