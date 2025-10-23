import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:background_location_tracker/background_location_tracker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

import '../widgets/permission_dialog.dart';

const _uploadEndpoint = 'https://loadupdate.ai/api/location';
const Duration _trackingInterval = Duration(minutes: 10);

@pragma('vm:entry-point')
Future<void> backgroundLocationCallback(dynamic data) async {
  final payload = _LocationPayload.fromDynamic(data);
  if (payload == null) {
    return;
  }
  await _LocationUploader.upload(
    latitude: payload.latitude,
    longitude: payload.longitude,
    timestamp: payload.timestamp,
  );
}

class LocationTrackingService extends ChangeNotifier {
  LocationTrackingService();

  bool _initialized = false;
  bool _tracking = false;
  Position? _lastKnownPosition;
  Timer? _foregroundTimer;
  String? _lastError;

  bool get isTracking => _tracking;
  Position? get lastKnownPosition => _lastKnownPosition;
  String? get lastError => _lastError;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    await BackgroundLocationTrackerManager.initialize(backgroundLocationCallback);
    _initialized = true;
  }

  Future<bool> ensureLocationService() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }
    return true;
  }

  Future<bool> requestMapPermission(BuildContext context) async {
    final status = await Permission.locationWhenInUse.status;
    if (status.isGranted) {
      _lastError = null;
      return true;
    }
    final accepted = await showPermissionDialog(
      context,
      permission: Permission.locationWhenInUse,
      title: 'Location access needed',
      rationale:
          'We need your permission to read your location so we can show it on the map.',
    );
    if (!accepted) {
      _lastError = 'Location access is needed to display your position on the map.';
      return false;
    }
    final result = await Permission.locationWhenInUse.request();
    final granted = result.isGranted;
    if (!granted) {
      _lastError = 'Location permission was denied.';
    } else {
      _lastError = null;
    }
    return granted;
  }

  Future<bool> startTracking(
    BuildContext context,
  ) async {
    if (_tracking) {
      _lastError = null;
      return true;
    }

    if (!await ensureLocationService()) {
      _lastError = 'Please enable location services on your device.';
      return false;
    }

    final backgroundStatus = await Permission.locationAlways.status;
    if (!backgroundStatus.isGranted) {
      final accepted = await showPermissionDialog(
        context,
        permission: Permission.locationAlways,
        title: 'Share your live position',
        rationale:
            'We send your position every 10 minutes so dispatch can follow your progress even if you close the app.',
      );
      if (!accepted) {
        _lastError = 'Background location access keeps the dispatcher updated even if the app is closed.';
        return false;
      }
      final requested = await Permission.locationAlways.request();
      if (!requested.isGranted) {
        _lastError = 'Background location permission was denied.';
        return false;
      }
    }

    final notificationStatus = await Permission.notification.status;
    if (!notificationStatus.isGranted) {
      final accepted = await showPermissionDialog(
        context,
        permission: Permission.notification,
        title: 'Allow status notifications',
        rationale:
            'Notifications let us keep a small reminder running while tracking is active so the system keeps you informed.',
      );
      if (accepted) {
        final notificationResult = await Permission.notification.request();
        if (!notificationResult.isGranted) {
          _lastError = 'Notifications permission was denied.';
          return false;
        }
      } else {
        _lastError = 'Notifications help us keep tracking active in the background.';
        return false;
      }
    }

    await _captureAndUploadCurrentPosition();
    _foregroundTimer?.cancel();
    _foregroundTimer = Timer.periodic(
      _trackingInterval,
      (_) => _captureAndUploadCurrentPosition(),
    );

    await BackgroundLocationTrackerManager.startTracking(_trackingInterval);
    _tracking = true;
    _lastError = null;
    notifyListeners();
    return true;
  }

  Future<void> stopTracking() async {
    if (!_tracking) {
      return;
    }
    _foregroundTimer?.cancel();
    _foregroundTimer = null;
    await BackgroundLocationTrackerManager.stopTracking();
    _tracking = false;
    _lastError = null;
    notifyListeners();
  }

  Future<void> refreshCurrentLocation() async {
    if (!await ensureLocationService()) {
      return;
    }
    final permission = await Permission.locationWhenInUse.status;
    if (!permission.isGranted) {
      return;
    }
    _lastKnownPosition = await Geolocator.getCurrentPosition();
    notifyListeners();
  }

  Future<void> _captureAndUploadCurrentPosition() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _lastKnownPosition = position;
      notifyListeners();
      await _LocationUploader.upload(
        latitude: position.latitude,
        longitude: position.longitude,
        timestamp: DateTime.now(),
      );
    } on Exception catch (_) {
      // Ignore errors; the background callback will retry on next interval.
    }
  }
}

class _LocationPayload {
  _LocationPayload({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  final double latitude;
  final double longitude;
  final DateTime timestamp;

  static _LocationPayload? fromDynamic(dynamic value) {
    if (value == null) {
      return null;
    }
    try {
      double? lat;
      double? lng;
      DateTime? timestamp;

      if (value is Map) {
        lat = _coerceDouble(value['latitude'] ?? value['lat']);
        lng = _coerceDouble(value['longitude'] ?? value['lng']);
        timestamp = _coerceDate(value['timestamp'] ?? value['time']);
      } else {
        final dynamic dynamicValue = value;
        lat = _coerceDouble(dynamicValue.latitude);
        lng = _coerceDouble(dynamicValue.longitude);
        timestamp = _coerceDate(dynamicValue.timestamp ?? dynamicValue.time);
      }

      if (lat == null || lng == null) {
        return null;
      }
      return _LocationPayload(
        latitude: lat,
        longitude: lng,
        timestamp: timestamp ?? DateTime.now(),
      );
    } catch (_) {
      return null;
    }
  }
}

class _LocationUploader {
  static Future<void> upload({
    required double latitude,
    required double longitude,
    DateTime? timestamp,
  }) async {
    final uri = Uri.parse(_uploadEndpoint);
    final body = jsonEncode({
      'latitude': latitude,
      'longitude': longitude,
      'recorded_at': (timestamp ?? DateTime.now()).toIso8601String(),
    });

    try {
      final response = await http.post(
        uri,
        headers: {
          HttpHeaders.contentTypeHeader: 'application/json',
        },
        body: body,
      );
      if (response.statusCode >= 400) {
        debugPrint('Location upload failed: ${response.statusCode} -> ${response.body}');
      }
    } on Exception catch (error) {
      debugPrint('Location upload error: $error');
    }
  }
}

double? _coerceDouble(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is double) {
    return value;
  }
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value.toString());
}

DateTime? _coerceDate(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is DateTime) {
    return value;
  }
  if (value is int) {
    return DateTime.fromMillisecondsSinceEpoch(value);
  }
  if (value is String) {
    return DateTime.tryParse(value);
  }
  return null;
}
