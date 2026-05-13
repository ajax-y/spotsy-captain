import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../../models/parking_space.dart';
import '../data/dashboard_providers.dart';
import '../../../common_widgets/glass_container.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});
  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final _mapController = MapController();
  LatLng _currentLocation = const LatLng(12.9716, 77.5946);
  StreamSubscription<Position>? _positionStream;
  bool _locationLoading = false;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  Future<void> _initLocation() async {
    bool svc = await Geolocator.isLocationServiceEnabled();
    if (!svc) return;
    LocationPermission p = await Geolocator.checkPermission();
    if (p == LocationPermission.denied) {
      p = await Geolocator.requestPermission();
      if (p == LocationPermission.denied) return;
    }
    if (p == LocationPermission.deniedForever) return;

    final pos = await Geolocator.getCurrentPosition();
    setState(() => _currentLocation = LatLng(pos.latitude, pos.longitude));
    _mapController.move(_currentLocation, 15.0);

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((pos) {
      if (mounted) {
        setState(() => _currentLocation = LatLng(pos.latitude, pos.longitude));
      }
    });
  }

  Future<void> _goToCurrentLocation() async {
    if (_locationLoading) return;
    setState(() => _locationLoading = true);
    try {
      final pos = await Geolocator.getCurrentPosition();
      setState(() => _currentLocation = LatLng(pos.latitude, pos.longitude));
      _mapController.move(_currentLocation, 15.0);
    } catch (e) {
      _snack('Location error: $e');
    } finally {
      if (mounted) setState(() => _locationLoading = false);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));
  }

  Color _markerColor(ParkingSpace s) {
    if (s.availableSpaces == 0) return Colors.red;
    if (s.occupancyRate > 0.5) return Colors.orange;
    return const Color(0xFF00E676);
  }

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(dashboardStatsProvider);
    final spacesAsync = ref.watch(parkingSpacesProvider);
    final spaces = spacesAsync.value ?? [];
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          // Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(initialCenter: _currentLocation, initialZoom: 14.0),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.spotsy',
                tileBuilder: (context, tileWidget, tile) {
                  return ColorFiltered(
                    colorFilter: const ColorFilter.matrix([
                      -0.2126, -0.7152, -0.0722, 0, 255,
                      -0.2126, -0.7152, -0.0722, 0, 255,
                      -0.2126, -0.7152, -0.0722, 0, 255,
                      0, 0, 0, 1, 0,
                    ]),
                    child: tileWidget,
                  );
                },
              ),
              MarkerLayer(markers: [
                Marker(point: _currentLocation, width: 24, height: 24, child: Container(
                  decoration: BoxDecoration(color: Colors.blue, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [BoxShadow(color: Colors.blue.withValues(alpha: 0.4), blurRadius: 10, spreadRadius: 3)]),
                )),
                ...spaces.map((s) => Marker(point: LatLng(s.latitude, s.longitude), width: 40, height: 40,
                  child: GestureDetector(onTap: () => context.go('/parking/${s.id}'),
                    child: Icon(Icons.local_parking_rounded, size: 36, color: _markerColor(s))))),
              ]),
            ],
          ),
          // AppBar (Floating Glass)
          Positioned(
            top: 40,
            left: 20,
            right: 20,
            child: GlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              borderRadius: 16,
              child: Row(
                children: [
                  const Icon(Icons.menu_rounded, color: Colors.white70),
                  const SizedBox(width: 16),
                  const Expanded(child: Text('Spotsy Captain', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
                  IconButton(
                    icon: const Icon(Icons.logout_rounded, color: Colors.white70),
                    onPressed: () => context.go('/login'),
                  ),
                ],
              ),
            ),
          ),
          // Location FAB
          Positioned(
            right: 20,
            top: 120,
            child: GlassContainer(
              padding: EdgeInsets.zero,
              borderRadius: 12,
              width: 44,
              height: 44,
              child: IconButton(
                onPressed: _locationLoading ? null : _goToCurrentLocation,
                icon: _locationLoading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
                    : const Icon(Icons.my_location_rounded, size: 20, color: Colors.white),
              ),
            ),
          ),
          // Bottom panel
          DraggableScrollableSheet(
            initialChildSize: 0.35, minChildSize: 0.15, maxChildSize: 0.85,
            builder: (context, sc) => ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: ListView(controller: sc, padding: const EdgeInsets.symmetric(horizontal: 20), children: [
                    Center(child: Container(margin: const EdgeInsets.symmetric(vertical: 12), width: 40, height: 4,
                      decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
                    _buildQuickStats(context, stats),
                    const SizedBox(height: 24),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text('My Parking Spaces', style: theme.textTheme.titleLarge),
                      Text('${spaces.length} listed', style: const TextStyle(color: Colors.white54, fontSize: 13)),
                    ]),
                    const SizedBox(height: 16),
                    if (spaces.isEmpty) _buildEmptyState(context),
                    ...spaces.map((s) => _buildSpaceCard(context, s)),
                    const SizedBox(height: 100),
                  ]),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: FloatingActionButton.extended(
          heroTag: 'add',
          onPressed: () => context.go('/parking/add'),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Add Space'),
        ),
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context, DashboardStats stats) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: 20,
      opacity: 0.05,
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _stat('Earnings', '₹${stats.todayEarnings.toStringAsFixed(0)}', Icons.trending_up_rounded),
        _stat('Active', '${stats.activeBookings}', Icons.directions_car_filled_rounded),
        _stat('Spaces', '${stats.availableSpaces}/${stats.totalSpaces}', Icons.local_parking_rounded),
        _stat('Rating', stats.averageRating.toStringAsFixed(1), Icons.star_rounded),
      ]),
    );
  }

  Widget _stat(String label, String value, IconData icon) {
    return Column(children: [
      Icon(icon, color: Theme.of(context).colorScheme.primary, size: 24),
      const SizedBox(height: 8),
      Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      const SizedBox(height: 4),
      Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: Colors.white54)),
    ]);
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(padding: const EdgeInsets.symmetric(vertical: 48), child: Column(children: [
      Icon(Icons.local_parking_rounded, size: 64, color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)),
      const SizedBox(height: 16),
      const Text('No parking spaces listed yet', style: TextStyle(color: Colors.white54, fontSize: 16)),
      const SizedBox(height: 8),
      const Text('Tap "+ Add Space" to list your first spot', style: TextStyle(color: Colors.white38, fontSize: 13)),
    ]));
  }

  Widget _buildSpaceCard(BuildContext context, ParkingSpace space) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassContainer(
        padding: EdgeInsets.zero,
        borderRadius: 20,
        opacity: 0.05,
        child: InkWell(
          onTap: () => context.go('/parking/${space.id}'),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Expanded(child: Text(space.name, style: theme.textTheme.titleMedium, overflow: TextOverflow.ellipsis)),
                Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: theme.colorScheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('₹${space.pricePerHour.toStringAsFixed(0)}/hr',
                    style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 14))),
              ]),
              const SizedBox(height: 8),
              Text(space.address, style: const TextStyle(color: Colors.white38, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 16),
              Row(children: [
                _badge(space.spaceType == SpaceType.bike ? Icons.two_wheeler_rounded : space.spaceType == SpaceType.car ? Icons.directions_car_rounded : Icons.commute_rounded,
                  space.spaceType == SpaceType.bike ? 'Bike' : space.spaceType == SpaceType.car ? 'Car' : 'Mixed'),
                const SizedBox(width: 8),
                if (space.hasEvCharging) ...[_badge(Icons.ev_station_rounded, 'EV'), const SizedBox(width: 8)],
                const Spacer(),
                Text('${space.availableSpaces}/${space.totalSpaces} free', style: TextStyle(color: space.availableSpaces == 0 ? Colors.redAccent : Colors.white54, fontSize: 13)),
                const SizedBox(width: 12),
                const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                const SizedBox(width: 4),
                Text(space.rating.toStringAsFixed(1), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              ]),
              const SizedBox(height: 12),
              ClipRRect(borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(value: space.occupancyRate, minHeight: 6, backgroundColor: Colors.white10,
                  valueColor: AlwaysStoppedAnimation<Color>(space.occupancyRate > 0.8 ? Colors.redAccent : space.occupancyRate > 0.5 ? Colors.orangeAccent : theme.colorScheme.primary))),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _badge(IconData icon, String label) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(10)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: Colors.white70),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w500)),
      ]));
  }
}
