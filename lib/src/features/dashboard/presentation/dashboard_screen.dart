import 'dart:async';
import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import '../../../models/parking_space.dart';
import '../data/dashboard_providers.dart';
import '../../profile/data/profile_providers.dart';
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
    if (mounted) {
      Future.microtask(() {
        if (mounted) {
          setState(() => _currentLocation = LatLng(pos.latitude, pos.longitude));
          _mapController.move(_currentLocation, 15.0);
        }
      });
    }

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((pos) {
      if (mounted) {
        Future.microtask(() {
          if (mounted) {
            setState(() => _currentLocation = LatLng(pos.latitude, pos.longitude));
          }
        });
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
      _snack(e.toString());
    } finally {
      if (mounted) setState(() => _locationLoading = false);
    }
  }

  void _snack(String msg, {bool isError = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14)),
          backgroundColor: isError ? Colors.orangeAccent : Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
      );
    }
  }

  Future<void> _searchLocation(String query) async {
    if (query.isEmpty) return;
    _snack('Searching for "$query"...');
    try {
      final url = Uri.parse('https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=1');
      final response = await http.get(url, headers: {'User-Agent': 'SpotsyCaptainApp/1.0 (com.example.spotsy)'});
      if (response.statusCode == 200) {
        final List results = json.decode(response.body);
        if (results.isNotEmpty) {
          final lat = double.parse(results[0]['lat']);
          final lon = double.parse(results[0]['lon']);
          final displayName = results[0]['display_name'].split(',')[0];
          _mapController.move(LatLng(lat, lon), 14);
          _snack('Found: $displayName');
        } else {
          _snack('No locations found for "$query"', isError: true);
        }
      } else {
        _snack('Search service unavailable', isError: true);
      }
    } catch (e) {
      _snack('Search error: $e', isError: true);
    }
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
    final userProfileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 120),
        child: FloatingActionButton(
          heroTag: 'loc_btn',
          onPressed: _goToCurrentLocation,
          backgroundColor: theme.colorScheme.primary,
          child: const Icon(Icons.my_location_rounded, color: Colors.black),
        ),
      ),
      body: Stack(
        children: [
          // Map (High Contrast Dark)
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(initialCenter: _currentLocation, initialZoom: 14.0),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.spotsy.captain.app',
                tileBuilder: (context, tileWidget, tile) => ColorFiltered(
                  colorFilter: const ColorFilter.matrix([-1,0,0,0,255, 0,-1,0,0,255, 0,0,-1,0,255, 0,0,0,1,0]),
                  child: tileWidget,
                ),
              ),
              MarkerLayer(markers: [
                Marker(point: _currentLocation, width: 24, height: 24, child: Container(
                  decoration: BoxDecoration(color: Colors.blue, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [BoxShadow(color: Colors.blue.withValues(alpha: 0.4), blurRadius: 10, spreadRadius: 3)]),
                )),
                ...spaces.map((s) => Marker(point: LatLng(s.latitude, s.longitude), width: 44, height: 44,
                  child: GestureDetector(
                    onTap: () => context.go('/parking/${s.id}'),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.8),
                        shape: BoxShape.circle,
                        border: Border.all(color: _markerColor(s), width: 2),
                      ),
                      child: Center(
                        child: Text(
                          '₹${s.pricePerHour.toInt()}',
                          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ))),
              ]),
            ],
          ),
          
          // Top Gradient Overlay (for text visibility)
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              height: 250,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.8),
                    Colors.black.withValues(alpha: 0.4),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          

          // Top UI Overlay
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(child: Text('Hello, ${userProfileAsync.value?.name ?? 'Alex'} ', style: theme.textTheme.headlineMedium?.copyWith(fontSize: 26, color: Colors.white, overflow: TextOverflow.ellipsis))),
                                const Text('👋', style: TextStyle(fontSize: 24)),
                              ],
                            ),
                            const Text('Find and book your perfect parking spot', style: TextStyle(color: Colors.white70, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => context.go('/profile'),
                        child: CircleAvatar(
                          radius: 24,
                          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.2),
                          backgroundImage: userProfileAsync.value?.photoUrl != null ? NetworkImage(userProfileAsync.value!.photoUrl!) : null,
                          child: userProfileAsync.value?.photoUrl == null ? Icon(Icons.person_rounded, color: theme.colorScheme.primary) : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Search Bar
                  GlassContainer(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    borderRadius: 20,
                    opacity: 0.1, // Increased visibility
                    child: TextField(
                      style: const TextStyle(color: Colors.white),
                      onSubmitted: _searchLocation,
                      decoration: InputDecoration(
                        hintText: 'Search location',
                        hintStyle: const TextStyle(color: Colors.white54),
                        prefixIcon: const Icon(Icons.search_rounded, color: Colors.white70),
                        suffixIcon: Icon(Icons.tune_rounded, color: theme.colorScheme.primary),
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Bottom panel
          DraggableScrollableSheet(
            key: const ValueKey('dashboard_sheet'),
            initialChildSize: 0.35, minChildSize: 0.15, maxChildSize: 0.85,
            builder: (context, sc) => Container(
              decoration: BoxDecoration(
                color: const Color(0xFF121212).withValues(alpha: 0.9),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: ListView(controller: sc, padding: const EdgeInsets.symmetric(horizontal: 20), children: [
                    Center(child: Container(margin: const EdgeInsets.symmetric(vertical: 12), width: 40, height: 4,
                      decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
                    
                    // Quick Stats / Info Card
                    const SizedBox(height: 12),
                    _buildQuickStats(context, stats),
                    
                    const SizedBox(height: 32),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text('Nearby Parking', style: theme.textTheme.titleLarge),
                      Text('See All', style: TextStyle(color: theme.colorScheme.primary, fontSize: 13, fontWeight: FontWeight.bold)),
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
    );
  }

  Widget _buildQuickStats(BuildContext context, DashboardStats stats) {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: 24,
      opacity: 0.05,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Quick Stats', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const Icon(Icons.insights_rounded, color: Colors.white54, size: 20),
            ],
          ),
          const SizedBox(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _stat('Earnings', '₹${stats.todayEarnings.toInt()}', Icons.account_balance_wallet_rounded),
            _stat('Active', '${stats.activeBookings}', Icons.local_activity_rounded),
            _stat('Spaces', '${stats.availableSpaces}', Icons.local_parking_rounded),
            _stat('Rating', stats.averageRating.toStringAsFixed(1), Icons.stars_rounded),
          ]),
        ],
      ),
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
                _badge(
                  space.spaceType == SpaceType.bike ? Icons.two_wheeler_rounded : (space.spaceType == SpaceType.carSmall || space.spaceType == SpaceType.carLarge) ? Icons.directions_car_rounded : Icons.commute_rounded,
                  space.spaceType == SpaceType.bike ? 'Bike' : space.spaceType == SpaceType.carSmall ? 'Small Car' : space.spaceType == SpaceType.carLarge ? 'Big Car' : 'Mixed',
                ),
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
