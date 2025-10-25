import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:verifier_facl/core/providers/database_provider.dart';
import 'package:verifier_facl/core/services/auth/auth_service.dart';
import 'package:verifier_facl/core/services/crypto/crypto_service.dart';
import 'package:verifier_facl/core/services/p2p/nearby_connections_service.dart';
import 'package:verifier_facl/core/services/p2p/p2p_manager.dart';

// Layer 1: Service Providers (Singletons)
final cryptoServiceProvider = Provider<CryptoService>((ref) => CryptoService());
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) => const FlutterSecureStorage());
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
    ref.watch(databaseProvider),
    ref.watch(cryptoServiceProvider),
    ref.watch(secureStorageProvider),
  );
});

// UPDATED: Replaced BLE and CrossP2P with a single NearbyConnections service
final nearbyConnectionsServiceProvider = Provider<NearbyConnectionsService>((ref) {
  final service = NearbyConnectionsService();
  ref.onDispose(() => service.dispose());
  return service;
});

// Layer 2: Manager Providers
final p2pManagerProvider = Provider<P2PManager>((ref) {
  final manager = P2PManager(
    ref,
    // Inject the new service
    ref.watch(nearbyConnectionsServiceProvider),
    ref.watch(cryptoServiceProvider),
  );
  ref.onDispose(() => manager.dispose());
  return manager;
});
