import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/clock.dart';
import '../core/screen_awake.dart';
import '../data/providers.dart';
import '../features/exercises/library/library.dart';
import '../health/health_service.dart';
import 'contract.dart';
import 'gateway_client.dart';
import 'lan_server.dart';
import 'proposals.dart';
import 'rpc.dart';
import 'tools.dart';

/// Secrets live in the operating system's secure storage (Keychain or
/// Android Keystore), never in the database or the export (handbook 10.8).
abstract class SecretStore {
  Future<String?> read(String key);
  Future<void> write(String key, String? value);
}

class DeviceSecretStore implements SecretStore {
  static const _storage = FlutterSecureStorage();
  @override
  Future<String?> read(String key) => _storage.read(key: key);
  @override
  Future<void> write(String key, String? value) =>
      value == null ? _storage.delete(key: key) : _storage.write(key: key, value: value);
}

final secretStoreProvider = Provider<SecretStore>((ref) => DeviceSecretStore());

abstract final class SecretKeys {
  static const wifiKey = 'ai.wifi.key';
  static const gatewayUrl = 'ai.gateway.url';
  static const ownerKey = 'ai.gateway.ownerKey';

  /// Key made during setup, before the gateway is connected.
  static const draftOwnerKey = 'ai.gateway.draftOwnerKey';
}

final toolContractProvider = FutureProvider<ToolContract>(
  (ref) async => ToolContract.parse(await rootBundle.loadString('assets/mcp/tools.json')),
);

final proposalRepoProvider = Provider(
  (ref) => ProposalRepository(
    ref.watch(databaseProvider),
    ref.watch(clockProvider),
    ref.watch(workoutRepoProvider),
    ref.watch(mealRepoProvider),
    () => ref.read(libraryProvider.future),
  ),
);

final pendingProposalsProvider = StreamProvider.autoDispose((ref) => ref.watch(proposalRepoProvider).watchPending());

final recentProposalsProvider = StreamProvider.autoDispose((ref) => ref.watch(proposalRepoProvider).watchRecent());

final proposalProvider = StreamProvider.autoDispose.family(
  (ref, String id) => ref.watch(proposalRepoProvider).watch(id),
);

final reparcToolsProvider = FutureProvider<ReparcTools>((ref) async {
  final contract = await ref.watch(toolContractProvider.future);
  return ReparcTools(
    contract: contract,
    db: ref.watch(databaseProvider),
    clock: ref.watch(clockProvider),
    workouts: ref.watch(workoutRepoProvider),
    meals: ref.watch(mealRepoProvider),
    proposals: ref.watch(proposalRepoProvider),
    health: ref.watch(healthSourceProvider),
    settings: () => ref.read(settingsRepoProvider).watch().first,
    library: () => ref.read(libraryProvider.future),
  );
});

/// How long an AI connection stays on before it stops by itself.
const accessDurations = [Duration(minutes: 15), Duration(minutes: 30), Duration(hours: 1), Duration(hours: 2)];

class AiState {
  const AiState({
    this.wifiOn = false,
    this.wifiUntil,
    this.wifiPort,
    this.wifiAddresses = const [],
    this.wifiKey,
    this.wifiError,
    this.gatewayUrl,
    this.onlineOn = false,
    this.onlineUntil,
    this.relay = RelayStatus.stopped,
    this.relayMessage,
    this.activity = const [],
  });

  final bool wifiOn;
  final DateTime? wifiUntil;
  final int? wifiPort;
  final List<String> wifiAddresses;
  final String? wifiKey;
  final String? wifiError;

  /// Base address of the owner's own gateway, once connected.
  final Uri? gatewayUrl;
  final bool onlineOn;
  final DateTime? onlineUntil;
  final RelayStatus relay;
  final String? relayMessage;

  /// Tool calls in this app session, newest first. Names only.
  final List<ActivityEntry> activity;

  String? get wifiUrl =>
      wifiAddresses.isEmpty || wifiPort == null ? null : 'http://${wifiAddresses.first}:$wifiPort/mcp';
  String? get onlineMcpUrl => gatewayUrl == null ? null : '$gatewayUrl/mcp';
  bool get anyOn => wifiOn || onlineOn;

  AiState copyWith({
    bool? wifiOn,
    DateTime? Function()? wifiUntil,
    int? Function()? wifiPort,
    List<String>? wifiAddresses,
    String? Function()? wifiKey,
    String? Function()? wifiError,
    Uri? Function()? gatewayUrl,
    bool? onlineOn,
    DateTime? Function()? onlineUntil,
    RelayStatus? relay,
    String? Function()? relayMessage,
    List<ActivityEntry>? activity,
  }) => AiState(
    wifiOn: wifiOn ?? this.wifiOn,
    wifiUntil: wifiUntil != null ? wifiUntil() : this.wifiUntil,
    wifiPort: wifiPort != null ? wifiPort() : this.wifiPort,
    wifiAddresses: wifiAddresses ?? this.wifiAddresses,
    wifiKey: wifiKey != null ? wifiKey() : this.wifiKey,
    wifiError: wifiError != null ? wifiError() : this.wifiError,
    gatewayUrl: gatewayUrl != null ? gatewayUrl() : this.gatewayUrl,
    onlineOn: onlineOn ?? this.onlineOn,
    onlineUntil: onlineUntil != null ? onlineUntil() : this.onlineUntil,
    relay: relay ?? this.relay,
    relayMessage: relayMessage != null ? relayMessage() : this.relayMessage,
    activity: activity ?? this.activity,
  );
}

/// Owns the Wi-Fi server and the online relay. Both are off until the user
/// turns one on, and both stop by themselves when their time ends.
class AiController extends Notifier<AiState> {
  LanMcpServer? _lan;
  GatewayRelay? _relay;
  GatewayApi? _api;
  Timer? _wifiTimer;
  Timer? _onlineTimer;
  AppLifecycleListener? _lifecycle;

  SecretStore get _secrets => ref.read(secretStoreProvider);

  @override
  AiState build() {
    ref.onDispose(() {
      _wifiTimer?.cancel();
      _onlineTimer?.cancel();
      _lifecycle?.dispose();
      unawaited(_lan?.stop());
      _relay?.stop();
      _api?.close();
    });
    unawaited(_load());
    return const AiState();
  }

  Future<void> _load() async {
    try {
      final url = await _secrets.read(SecretKeys.gatewayUrl);
      final key = await _secrets.read(SecretKeys.wifiKey);
      state = state.copyWith(gatewayUrl: () => url == null ? null : Uri.tryParse(url), wifiKey: () => key);
    } catch (_) {
      // Secure storage can be unavailable (for example right after a
      // restore). Connections then start as not set up.
    }
  }

  void _log(ActivityEntry e) => state = state.copyWith(activity: [e, ...state.activity.take(49)]);

  void _watchLifecycle() {
    _lifecycle ??= AppLifecycleListener(onResume: _resume);
  }

  /// The operating system may pause sockets in the background. Restart what
  /// is still within its time window when the app is in front again.
  Future<void> _resume() async {
    final now = DateTime.now();
    if (state.wifiOn && (state.wifiUntil?.isAfter(now) ?? false)) {
      await _lan?.stop();
      _lan = null;
      await _startWifi(state.wifiUntil!.difference(now));
    }
    if (state.onlineOn && (state.onlineUntil?.isAfter(now) ?? false)) {
      _relay?.stop();
      _relay = null;
      await _startOnline(state.onlineUntil!.difference(now));
    }
  }

  void _updateWakelock() {
    ScreenAwake.hold('ai', state.anyOn);
  }

  // ------------------------------------------------------------------ Wi-Fi

  Future<String> wifiKey() async {
    var key = await _secrets.read(SecretKeys.wifiKey);
    if (key == null) {
      key = newAccessKey();
      await _secrets.write(SecretKeys.wifiKey, key);
    }
    state = state.copyWith(wifiKey: () => key);
    return key;
  }

  /// Makes a new Wi-Fi key. AI apps that used the old key stop working.
  Future<void> rotateWifiKey() async {
    final key = newAccessKey();
    await _secrets.write(SecretKeys.wifiKey, key);
    state = state.copyWith(wifiKey: () => key);
    if (state.wifiOn) {
      await _lan?.stop();
      _lan = null;
      await _startWifi(state.wifiUntil!.difference(DateTime.now()));
    }
  }

  Future<void> startWifi(Duration duration) => _startWifi(duration);

  Future<void> _startWifi(Duration duration) async {
    _watchLifecycle();
    try {
      final tools = await ref.read(reparcToolsProvider.future);
      final contract = await ref.read(toolContractProvider.future);
      final key = await wifiKey();
      final lan = LanMcpServer(
        rpc: McpRpc(contract, tools, onActivity: _log),
        accessKey: key,
      );
      final port = await lan.start();
      _lan = lan;
      final addresses = await localAddresses();
      final until = DateTime.now().add(duration);
      _wifiTimer?.cancel();
      _wifiTimer = Timer(duration, stopWifi);
      state = state.copyWith(
        wifiOn: true,
        wifiUntil: () => until,
        wifiPort: () => port,
        wifiAddresses: addresses,
        wifiError: () => addresses.isEmpty ? 'This phone is not on a Wi-Fi network. Join Wi-Fi, then try again.' : null,
      );
    } catch (_) {
      state = state.copyWith(wifiOn: false, wifiError: () => 'The Wi-Fi server could not start. Try again.');
    }
    _updateWakelock();
  }

  Future<void> stopWifi() async {
    _wifiTimer?.cancel();
    await _lan?.stop();
    _lan = null;
    state = state.copyWith(wifiOn: false, wifiUntil: () => null, wifiPort: () => null);
    _updateWakelock();
  }

  // ----------------------------------------------------------------- Online

  /// The owner key for setup. Made once and kept until setup finishes, so
  /// the user can switch to Vercel and come back.
  Future<String> draftOwnerKey() async {
    var key = await _secrets.read(SecretKeys.draftOwnerKey);
    if (key == null) {
      key = newOwnerKey();
      await _secrets.write(SecretKeys.draftOwnerKey, key);
    }
    return key;
  }

  Future<String?> ownerKey() => _secrets.read(SecretKeys.ownerKey);

  /// Checks the gateway with [ownerKey], then saves both. Throws
  /// [GatewayException] with a message for the user.
  Future<void> connectGateway(String address, String ownerKey) async {
    final base = parseGatewayAddress(address);
    if (base == null) {
      throw const GatewayException('Enter the https address from Vercel, for example reparc-gateway-you.vercel.app.');
    }
    final key = ownerKey.trim();
    if (key.length < 32) throw const GatewayException('The owner key is too short.');
    final api = GatewayApi(base, key);
    try {
      await api.verify();
    } finally {
      api.close();
    }
    await _secrets.write(SecretKeys.gatewayUrl, base.toString());
    await _secrets.write(SecretKeys.ownerKey, key);
    await _secrets.write(SecretKeys.draftOwnerKey, null);
    state = state.copyWith(gatewayUrl: () => base);
  }

  /// Forgets the gateway on this phone. The Vercel project stays in the
  /// owner's account until they delete it there.
  Future<void> forgetGateway() async {
    await stopOnline();
    await _secrets.write(SecretKeys.gatewayUrl, null);
    await _secrets.write(SecretKeys.ownerKey, null);
    state = state.copyWith(gatewayUrl: () => null);
  }

  /// Owner API for the connected gateway, or null.
  Future<GatewayApi?> api() async {
    final url = state.gatewayUrl;
    final key = await ownerKey();
    if (url == null || key == null) return null;
    if (_api == null || _api!.base != url || _api!.ownerKey != key) {
      _api?.close();
      _api = GatewayApi(url, key);
    }
    return _api;
  }

  Future<void> startOnline(Duration duration) => _startOnline(duration);

  Future<void> _startOnline(Duration duration) async {
    _watchLifecycle();
    final api = await this.api();
    if (api == null) return;
    final tools = await ref.read(reparcToolsProvider.future);
    // The relay gets its own client so a long poll never blocks owner calls.
    final relay = GatewayRelay(
      api: GatewayApi(api.base, api.ownerKey),
      tools: tools,
      onActivity: _log,
      onStatus: (s, m) {
        state = state.copyWith(relay: s, relayMessage: () => m);
        if (s == RelayStatus.stopped && state.onlineOn && m != null) {
          state = state.copyWith(onlineOn: false, onlineUntil: () => null);
          _updateWakelock();
        }
      },
    );
    _relay?.stop();
    _relay = relay..start();
    final until = DateTime.now().add(duration);
    _onlineTimer?.cancel();
    _onlineTimer = Timer(duration, stopOnline);
    state = state.copyWith(onlineOn: true, onlineUntil: () => until);
    _updateWakelock();
  }

  Future<void> stopOnline() async {
    _onlineTimer?.cancel();
    final relay = _relay;
    _relay = null;
    relay?.stop();
    relay?.api.close();
    state = state.copyWith(
      onlineOn: false,
      onlineUntil: () => null,
      relay: RelayStatus.stopped,
      relayMessage: () => null,
    );
    _updateWakelock();
  }
}

final aiControllerProvider = NotifierProvider<AiController, AiState>(AiController.new);
