import 'package:flutter/widgets.dart';

/// True when the user asked the system to reduce motion.
bool reduceMotion(BuildContext context) => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

/// Returns [d], or zero when the user asked to reduce motion.
Duration motionOf(BuildContext context, Duration d) => reduceMotion(context) ? Duration.zero : d;
