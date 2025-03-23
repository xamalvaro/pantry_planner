import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pantry_pal/expiry/expiry_service.dart';

/// A lightweight service locator for lazy loading and accessing services
///
/// This helps reduce startup time by only initializing services when needed
class ServiceLocator {
  // Singleton instance
  static final ServiceLocator _instance = ServiceLocator._internal();
  factory ServiceLocator() => _instance;
  ServiceLocator._internal();

  // Service cache
  final Map<String, dynamic> _services = {};

  // Flag for whether we've completed initial app loading
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;
  set isInitialized(bool value) => _isInitialized = value;

  // Get or create a service
  T get<T>(String serviceName) {
    // Check if already created
    if (_services.containsKey(serviceName)) {
      return _services[serviceName] as T;
    }

    // Create the service
    late final dynamic service;

    switch (serviceName) {
      case 'expiryService':
        service = ExpiryService();
        break;
      default:
        throw Exception('Unknown service: $serviceName');
    }

    // Cache it
    _services[serviceName] = service;
    return service as T;
  }

  // Get a Hive box (opens it if not already open)
  Future<Box> getBox(String boxName) async {
    // Use a key specific to boxes
    final cacheKey = 'box_$boxName';

    // Check if already opened and cached
    if (_services.containsKey(cacheKey)) {
      return _services[cacheKey] as Box;
    }

    // If box is already open in Hive, just get it
    if (Hive.isBoxOpen(boxName)) {
      final box = Hive.box(boxName);
      _services[cacheKey] = box;
      return box;
    }

    // Otherwise open it in an isolate
    try {
      final box = await compute<String, Box>(_openBoxIsolate, boxName);
      _services[cacheKey] = box;
      return box;
    } catch (e) {
      print('Error opening box $boxName: $e');
      rethrow;
    }
  }

  // Helper to open box in isolate
  static Future<Box> _openBoxIsolate(String boxName) async {
    return await Hive.openBox(boxName);
  }

  // Clear service cache (useful for testing or when memory pressure is high)
  void clearCache() {
    _services.clear();
  }

  // Register a service manually (useful for testing with mocks)
  void register<T>(String serviceName, T service) {
    _services[serviceName] = service;
  }
}

// Global accessor
final serviceLocator = ServiceLocator();