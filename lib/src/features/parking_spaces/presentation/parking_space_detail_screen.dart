import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../models/parking_space.dart';
import '../../dashboard/data/dashboard_providers.dart';

class ParkingSpaceDetailScreen extends ConsumerWidget {
  final String spaceId;
  const ParkingSpaceDetailScreen({super.key, required this.spaceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacesAsync = ref.watch(parkingSpacesProvider);
    final spaces = spacesAsync.value ?? [];
    final space = spaces.where((s) => s.id == spaceId).firstOrNull;
    final theme = Theme.of(context);

    if (space == null) {
      return Scaffold(appBar: AppBar(), body: const Center(child: Text('Space not found')));
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/dashboard')),
        title: Text(space.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [IconButton(icon: const Icon(Icons.edit), onPressed: () => context.go('/parking/${space.id}/edit'))],
      ),
      body: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Photos placeholder
        Container(height: 180, width: double.infinity, decoration: BoxDecoration(
          color: const Color(0xFF252525), borderRadius: BorderRadius.circular(16)),
          child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.photo_library_outlined, size: 48, color: Colors.grey[600]),
            const SizedBox(height: 8),
            Text('No photos uploaded', style: TextStyle(color: Colors.grey[600])),
          ]))),
        const SizedBox(height: 20),
        // Price
        Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(color: theme.colorScheme.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
          child: Text('₹${space.pricePerHour.toStringAsFixed(0)} / hour',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: theme.colorScheme.primary))),
        const SizedBox(height: 16),
        // Address
        Row(children: [Icon(Icons.location_on, color: Colors.grey[500], size: 18), const SizedBox(width: 6),
          Expanded(child: Text(space.address, style: TextStyle(color: Colors.grey[400])))]),
        const SizedBox(height: 20),
        // Availability
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Availability', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[400])),
          Text('${space.availableSpaces} / ${space.totalSpaces} spaces free',
            style: TextStyle(color: space.availableSpaces == 0 ? Colors.red : theme.colorScheme.primary, fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 8),
        ClipRRect(borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(value: space.occupancyRate, minHeight: 6, backgroundColor: Colors.grey[800],
            valueColor: AlwaysStoppedAnimation(space.occupancyRate > 0.8 ? Colors.red : space.occupancyRate > 0.5 ? Colors.orange : theme.colorScheme.primary))),
        const SizedBox(height: 24),
        // Details grid
        Text('Details', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[400])),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _detailChip(
            (space.spaceType == SpaceType.carSmall || space.spaceType == SpaceType.carLarge) ? Icons.directions_car_rounded : Icons.commute,
            space.spaceType == SpaceType.bike ? 'Bike' : space.spaceType == SpaceType.carSmall ? 'Small Car' : space.spaceType == SpaceType.carLarge ? 'Big Car' : 'Mixed',
          ),
          if (space.hasEvCharging) _detailChip(Icons.ev_station, 'EV Charging'),
          if (space.hasCctv) _detailChip(Icons.videocam, 'CCTV'),
          if (space.hasSecurity) _detailChip(Icons.security, 'Security'),
          if (space.hasLighting) _detailChip(Icons.light, 'Lighting'),
          if (space.isCovered) _detailChip(Icons.roofing, 'Covered'),
          _detailChip(Icons.access_time, space.is24x7 ? '24/7' : '${space.openingTime ?? "N/A"} - ${space.closingTime ?? "N/A"}'),
        ]),
        const SizedBox(height: 24),
        // Rating
        Row(children: [
          const Icon(Icons.star, color: Colors.amber, size: 20), const SizedBox(width: 4),
          Text('${space.rating.toStringAsFixed(1)} (${space.totalRatings} reviews)', style: TextStyle(color: Colors.grey[400])),
        ]),
        const SizedBox(height: 24),
        // Description
        if (space.description.isNotEmpty) ...[
          Text('Description', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[400])),
          const SizedBox(height: 8),
          Text(space.description, style: TextStyle(color: Colors.grey[300], height: 1.5)),
        ],
      ])),
    );
  }

  Widget _detailChip(IconData icon, String label) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: const Color(0xFF252525), borderRadius: BorderRadius.circular(10)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 16, color: Colors.grey[400]), const SizedBox(width: 6),
        Text(label, style: TextStyle(color: Colors.grey[300], fontSize: 13)),
      ]));
  }
}
