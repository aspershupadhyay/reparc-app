import 'package:flutter_test/flutter_test.dart';
import 'package:reparc/core/theme.dart';

/// Letter spacing follows each typeface's own table (platform design audit,
/// 2026-11-09): Apple's iOS tracking values for SF Pro, Inter's dynamic
/// metrics for Inter.
void main() {
  test('SF Pro follows Apple\'s iOS tracking table', () {
    expect(trackingFor(17, ios: true), closeTo(-0.43, 0.001));
    expect(trackingFor(13, ios: true), closeTo(-0.08, 0.001));
    expect(trackingFor(34, ios: true), closeTo(0.40, 0.001));
    expect(trackingFor(28, ios: true), closeTo(0.38, 0.001));
  });

  test('Inter tightens large sizes and leaves small ones open', () {
    expect(trackingFor(34, ios: false), lessThan(-0.6));
    expect(trackingFor(17, ios: false), inInclusiveRange(-0.3, -0.1));
    expect(trackingFor(12, ios: false).abs(), lessThan(0.05));
  });
}
