/// Enumerations stored by name in the local database.
///
/// Stored names are part of the data format. Do not rename a value without
/// a migration.
library;

enum SessionStatus { active, paused, finished, incomplete }

enum SetType { warmup, working, drop, timed }

enum MealStatus { planned, eaten }

extension SetTypeLabel on SetType {
  String get label => switch (this) {
    SetType.warmup => 'Warm-up',
    SetType.working => 'Working',
    SetType.drop => 'Drop',
    SetType.timed => 'Timed',
  };

  String get short => switch (this) {
    SetType.warmup => 'W',
    SetType.working => '',
    SetType.drop => 'D',
    SetType.timed => 'T',
  };
}

extension SessionStatusLabel on SessionStatus {
  String get label => switch (this) {
    SessionStatus.active => 'In progress',
    SessionStatus.paused => 'Paused',
    SessionStatus.finished => 'Finished',
    SessionStatus.incomplete => 'Saved as incomplete',
  };

  bool get isLive => this == SessionStatus.active || this == SessionStatus.paused;
}

/// Units the app can record. The original unit is always stored.
abstract final class Units {
  static const kg = 'kg';
  static const lb = 'lb';
  static const km = 'km';
  static const mi = 'mi';
  static const m = 'm';
  static const loadUnits = [kg, lb];
  static const distanceUnits = [km, mi, m];
  static const amountUnits = ['g', 'ml', 'oz', 'serving', 'piece', 'cup', 'tbsp', 'tsp'];
}

/// Source text for values that the user typed.
const sourceManual = 'Manual entry';
