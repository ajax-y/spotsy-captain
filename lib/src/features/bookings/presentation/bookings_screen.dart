import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/booking.dart';
import '../../dashboard/data/dashboard_providers.dart';

class BookingsScreen extends ConsumerWidget {
  const BookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(bookingRequestsProvider);
    final activeAsync = ref.watch(activeBookingsProvider);
    
    final requests = requestsAsync.value ?? [];
    final active = activeAsync.value ?? [];

    return DefaultTabController(length: 2, child: Scaffold(
      appBar: AppBar(
        title: const Text('Bookings', style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          indicatorColor: Theme.of(context).colorScheme.primary,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Colors.grey[500],
          tabs: [
            Tab(text: 'Requests (${requests.length})'),
            Tab(text: 'Active (${active.length})'),
          ],
        ),
      ),
      body: TabBarView(children: [
        // Requests Tab
        requestsAsync.when(
          data: (list) => list.isEmpty
            ? _emptyState(context, 'No pending requests', 'New booking requests will appear here')
            : ListView.builder(padding: const EdgeInsets.all(16), itemCount: list.length,
                itemBuilder: (ctx, i) => _requestCard(context, ref, list[i])),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Center(child: Text('Error: $e')),
        ),
        // Active Tab
        activeAsync.when(
          data: (list) => list.isEmpty
            ? _emptyState(context, 'No active bookings', 'Confirmed bookings will appear here')
            : ListView.builder(padding: const EdgeInsets.all(16), itemCount: list.length,
                itemBuilder: (ctx, i) => _activeCard(context, list[i])),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Center(child: Text('Error: $e')),
        ),
      ]),
    ));
  }

  Widget _emptyState(BuildContext context, String title, String sub) {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.inbox_outlined, size: 64, color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)),
      const SizedBox(height: 16),
      Text(title, style: TextStyle(color: Colors.grey[500], fontSize: 16)),
      const SizedBox(height: 4),
      Text(sub, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
    ]));
  }

  Widget _requestCard(BuildContext context, WidgetRef ref, Booking b) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF252525), borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // User info
        Row(children: [
          CircleAvatar(radius: 20, backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.2),
            child: Icon(Icons.person, color: theme.colorScheme.primary)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(b.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            Text(b.parkingSpaceName, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
          ])),
        ]),
        const SizedBox(height: 12),
        // Vehicle info
        Container(padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(10)),
          child: Row(children: [
            Icon(b.vehicleType == 'Bike' ? Icons.two_wheeler : Icons.directions_car, color: Colors.grey[400], size: 20),
            const SizedBox(width: 8),
            Text('${b.vehicleModel} • ${b.vehicleRegistration}', style: TextStyle(color: Colors.grey[300], fontSize: 13)),
            const Spacer(),
            Container(width: 16, height: 16, decoration: BoxDecoration(
              color: _colorFromName(b.vehicleColor), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1))),
          ])),
        const SizedBox(height: 12),
        // Accept / Reject
        Row(children: [
          Expanded(child: OutlinedButton(
            onPressed: () => ref.read(firestoreServiceProvider).updateBookingStatus(b.id, 'CANCELLED'),
            style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.redAccent), foregroundColor: Colors.redAccent),
            child: const Text('REJECT'))),
          const SizedBox(width: 12),
          Expanded(child: ElevatedButton(
            onPressed: () => ref.read(firestoreServiceProvider).updateBookingStatus(b.id, 'CONFIRMED'),
            child: const Text('ACCEPT'))),
        ]),
      ]),
    );
  }

  Widget _activeCard(BuildContext context, Booking b) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF252525), borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(radius: 20, backgroundColor: Colors.green.withValues(alpha: 0.2),
            child: const Icon(Icons.check, color: Colors.green)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(b.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            Text(b.parkingSpaceName, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
          ])),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
            child: const Text('ACTIVE', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 11))),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Icon(b.vehicleType == 'Bike' ? Icons.two_wheeler : Icons.directions_car, color: Colors.grey[400], size: 18),
          const SizedBox(width: 6),
          Text('${b.vehicleModel} • ${b.vehicleRegistration}', style: TextStyle(color: Colors.grey[400], fontSize: 13)),
        ]),
        if (b.checkInTime != null) ...[
          const SizedBox(height: 8),
          Row(children: [
            Icon(Icons.access_time, color: Colors.grey[500], size: 16), const SizedBox(width: 6),
            Text('Checked in: ${_formatTime(b.checkInTime!)}', style: TextStyle(color: Colors.grey[400], fontSize: 13)),
          ]),
        ],
        const SizedBox(height: 12),
        SizedBox(width: double.infinity, child: OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.location_on, size: 18),
          label: const Text('Track User Location'),
          style: OutlinedButton.styleFrom(foregroundColor: theme.colorScheme.primary,
            side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.5))),
        )),
      ]),
    );
  }

  Color _colorFromName(String name) {
    final n = name.toLowerCase();
    if (n.contains('red')) return Colors.red;
    if (n.contains('blue')) return Colors.blue;
    if (n.contains('black')) return Colors.black;
    if (n.contains('white')) return Colors.white;
    if (n.contains('silver') || n.contains('grey')) return Colors.grey;
    return Colors.grey;
  }

  String _formatTime(DateTime t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}
