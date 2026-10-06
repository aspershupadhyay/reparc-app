import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

/// Encrypted backup files (handbook 8.6, D-021).
///
/// A backup is the full JSON export, compressed, then encrypted with
/// AES-256-GCM. The key comes from the user's passphrase through Argon2id
/// (OWASP minimum: 19 MiB memory, 2 passes). The passphrase never leaves the
/// phone and is not stored. Without it, nobody can open the file, including
/// Apple, Google, and the Reparc project. A lost passphrase cannot be reset.
///
/// File layout (JSON):
///
/// ```json
/// {"format":"reparc-backup","version":1,
///  "kdf":{"name":"argon2id","memoryKiB":19456,"iterations":2,"parallelism":1,"salt":"…"},
///  "cipher":"aes-256-gcm","nonce":"…","data":"…ciphertext and tag…"}
/// ```
abstract final class BackupCrypto {
  static const format = 'reparc-backup';
  static const version = 1;
  static const extension = 'reparcbackup';
  static const minPassphrase = 8;

  static const _memory = 19456;
  static const _iterations = 2;

  /// Encrypts [exportJson]. Runs on a background isolate.
  static Future<Uint8List> seal(String exportJson, String passphrase) =>
      Isolate.run(() => _seal(exportJson, passphrase));

  /// Decrypts a backup file and returns the export JSON. Throws
  /// [BackupException] with a message for the user.
  static Future<String> open(Uint8List file, String passphrase) => Isolate.run(() => _open(file, passphrase));

  static Future<Uint8List> _seal(String exportJson, String passphrase) async {
    final rnd = SecureRandom.defaultRandom;
    final salt = List<int>.generate(16, (_) => rnd.nextInt(256));
    final key = await _kdf(_memory, _iterations).deriveKeyFromPassword(password: passphrase, nonce: salt);
    final plain = GZipCodec(level: 6).encode(utf8.encode(exportJson));
    final box = await AesGcm.with256bits().encrypt(plain, secretKey: key);
    final envelope = {
      'format': format,
      'version': version,
      'kdf': {
        'name': 'argon2id',
        'memoryKiB': _memory,
        'iterations': _iterations,
        'parallelism': 1,
        'salt': base64.encode(salt),
      },
      'cipher': 'aes-256-gcm',
      'nonce': base64.encode(box.nonce),
      'data': base64.encode([...box.cipherText, ...box.mac.bytes]),
    };
    return Uint8List.fromList(utf8.encode(jsonEncode(envelope)));
  }

  static Future<String> _open(Uint8List file, String passphrase) async {
    final Map<String, dynamic> env;
    try {
      env = jsonDecode(utf8.decode(file)) as Map<String, dynamic>;
    } catch (_) {
      throw const BackupException('This file is not a Reparc backup.');
    }
    if (env['format'] != format) throw const BackupException('This file is not a Reparc backup.');
    if ((env['version'] as int? ?? 0) > version) {
      throw const BackupException('This backup was made by a newer Reparc. Update the app, then try again.');
    }
    final kdf = env['kdf'] as Map<String, dynamic>;
    final memory = kdf['memoryKiB'] as int;
    final iterations = kdf['iterations'] as int;
    // Refuse values that would freeze the phone (a crafted file could ask for gigabytes).
    if (kdf['name'] != 'argon2id' || memory > 262144 || iterations > 10 || env['cipher'] != 'aes-256-gcm') {
      throw const BackupException('This backup uses settings Reparc does not support.');
    }
    final key = await _kdf(
      memory,
      iterations,
    ).deriveKeyFromPassword(password: passphrase, nonce: base64.decode(kdf['salt'] as String));
    final data = base64.decode(env['data'] as String);
    if (data.length < 16) throw const BackupException('This backup file is damaged.');
    final box = SecretBox(
      data.sublist(0, data.length - 16),
      nonce: base64.decode(env['nonce'] as String),
      mac: Mac(data.sublist(data.length - 16)),
    );
    final List<int> plain;
    try {
      plain = await AesGcm.with256bits().decrypt(box, secretKey: key);
    } on SecretBoxAuthenticationError {
      throw const BackupException('Wrong passphrase, or the file was changed.');
    }
    return utf8.decode(GZipCodec().decode(plain));
  }

  static Argon2id _kdf(int memory, int iterations) =>
      Argon2id(parallelism: 1, memory: memory, iterations: iterations, hashLength: 32);
}

class BackupException implements Exception {
  const BackupException(this.message);
  final String message;
  @override
  String toString() => message;
}
