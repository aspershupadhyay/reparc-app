import 'package:flutter_test/flutter_test.dart';
import 'package:reparc/domain/streak.dart';

void main() {
  // Monday 2 March 2026 is the start of a week.
  final mon = DateTime(2026, 3, 2);
  DateTime d(int offset) => mon.add(Duration(days: offset));

  test('one missed plan day is forgiven', () {
    expect(streakTarget(3), 2);
    expect(streakTarget(1), 1);
    expect(streakTarget(null), 1, reason: 'Without a plan, one workout a week');
  });

  test('weeks in a row that reach the target', () {
    final days = [d(-14), d(-12), d(-7), d(-5), d(0)];
    // Two full weeks with 2 workouts; this week has 1 so far.
    expect(weeklyStreak(days, today: d(2), target: 2), 2, reason: 'An unfinished week does not break it');
    expect(weeklyStreak([...days, d(1)], today: d(2), target: 2), 3, reason: 'This week counts once reached');
  });

  test('a week below the target ends the streak', () {
    final days = [d(-21), d(-20), d(-14), d(-7), d(-6)];
    expect(weeklyStreak(days, today: d(1), target: 2), 1);
    expect(weeklyStreak(const [], today: d(1), target: 1), 0);
  });
}
