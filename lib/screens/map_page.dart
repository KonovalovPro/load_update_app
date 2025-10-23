import 'dart:io';

import 'package:apple_maps_flutter/apple_maps_flutter.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../services/location_tracking_service.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  AppleMapController? _mapController;
  bool _requestInFlight = false;
  bool _loadingLocation = false;
  LatLng? _lastCameraTarget;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _prepareLocation());
  }

  Future<void> _prepareLocation() async {
    final service = context.read<LocationTrackingService>();
    setState(() => _loadingLocation = true);
    final granted = await service.requestMapPermission(context);
    if (granted) {
      await service.refreshCurrentLocation();
    }
    if (!granted && mounted) {
      final message = service.lastError ?? 'Location permission is required to continue.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
    if (mounted) {
      setState(() => _loadingLocation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final trackingService = context.watch<LocationTrackingService>();
    final position = trackingService.lastKnownPosition;
    final isTracking = trackingService.isTracking;

    return Stack(
      children: [
        Positioned.fill(
          child: _buildMap(context, position),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 24,
          child: FilledButton(
            onPressed: _requestInFlight
                ? null
                : () => _onSharePressed(context, isTracking, trackingService),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            child: _requestInFlight
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(isTracking ? 'Tracking' : 'Share location'),
          ),
        ),
      ],
    );
  }

  Widget _buildMap(BuildContext context, Position? position) {
    if (!Platform.isIOS) {
      return const Center(
        child: Text('Apple Maps is only available on iOS devices.'),
      );
    }

    if (_loadingLocation) {
      return const Center(child: CircularProgressIndicator());
    }

    if (position == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_disabled, size: 48),
            const SizedBox(height: 12),
            const Text('Location unavailable'),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => _requestLocation(context),
              child: const Text('Enable location'),
            ),
          ],
        ),
      );
    }

    final coordinate = LatLng(position.latitude, position.longitude);
    _maybeMoveCamera(coordinate);
    final annotations = {
      Annotation(
        annotationId: const AnnotationId('current_location'),
        position: coordinate,
        title: 'You are here',
      ),
    };

    return AppleMap(
      annotations: annotations,
      initialCameraPosition: CameraPosition(target: coordinate, zoom: 14),
      showsUserLocation: true,
      onMapCreated: (controller) => _mapController = controller,
    );
  }

  Future<void> _requestLocation(BuildContext context) async {
    final service = context.read<LocationTrackingService>();
    final granted = await service.requestMapPermission(context);
    if (granted) {
      await service.refreshCurrentLocation();
      if (!mounted) return;
      final position = service.lastKnownPosition;
      if (position != null && _mapController != null) {
        _maybeMoveCamera(LatLng(position.latitude, position.longitude));
      }
    } else if (mounted) {
      final message = service.lastError ?? 'Location permission is required to continue.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  void _maybeMoveCamera(LatLng target) {
    if (_mapController == null) {
      return;
    }
    final last = _lastCameraTarget;
    if (last != null && (last.latitude - target.latitude).abs() < 1e-6 &&
        (last.longitude - target.longitude).abs() < 1e-6) {
      return;
    }
    _lastCameraTarget = target;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mapController?.moveCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: target, zoom: 14),
        ),
      );
    });
  }

  Future<void> _onSharePressed(
    BuildContext context,
    bool isTracking,
    LocationTrackingService service,
  ) async {
    setState(() => _requestInFlight = true);
    try {
      if (!isTracking) {
        final granted = await service.startTracking(context);
        if (!mounted) return;
        if (!granted) {
          final message = service.lastError ?? 'Location tracking permission denied.';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location tracking started.')),
          );
        }
      } else {
        final shouldStop = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Stop sharing?'),
                content: const Text(
                  'Tracking will stop and we will no longer send your position updates.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Keep tracking'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Stop'),
                  ),
                ],
              ),
            ) ??
            false;
        if (shouldStop) {
          await service.stopTracking();
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location tracking stopped.')),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _requestInFlight = false);
      }
    }
  }
}
