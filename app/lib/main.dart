import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/router.dart';
import 'data/database.dart';
import 'data/providers.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(() async* {
    final ofl = await rootBundle.loadString('assets/fonts/Inter-OFL.txt');
    yield LicenseEntryWithLineBreaks(['Inter'], ofl);
    final lucide = await rootBundle.loadString('assets/licenses/lucide-ISC.txt');
    yield LicenseEntryWithLineBreaks(['Lucide icons'], lucide);
    final voice = await rootBundle.loadString('assets/licenses/elevenlabs-voice.txt');
    yield LicenseEntryWithLineBreaks(['Voice cues (ElevenLabs)'], voice);
  });

  final db = AppDatabase.open();
  runApp(
    ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: ReparcApp(router: buildRouter(), intro: true),
    ),
  );
}
