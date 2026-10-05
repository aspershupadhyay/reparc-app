import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Source of the current time. Tests override it.
typedef Clock = DateTime Function();

final clockProvider = Provider<Clock>((ref) => DateTime.now);
