import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/parking_space.dart';
import '../../../models/booking.dart';
import '../../../services/firestore_service.dart';
import '../../earnings/data/earnings_providers.dart';

// ─── Services ───────────────────────────────────────────────────

final firestoreServiceProvider = Provider((ref) => FirestoreService());

// ─── Data Streams ───────────────────────────────────────────────

final parkingSpacesProvider = StreamProvider<List<ParkingSpace>>((ref) {
  return ref.watch(firestoreServiceProvider).getOwnerSpaces();
});

final bookingRequestsProvider = StreamProvider<List<Booking>>((ref) {
  return ref.watch(firestoreServiceProvider).getPendingRequests();
});

final activeBookingsProvider = StreamProvider<List<Booking>>((ref) {
  return ref.watch(firestoreServiceProvider).getActiveBookings();
});

// ─── Dashboard Stats (Computed) ──────────────────────────────────

class DashboardStats {
  final double todayEarnings;
  final int activeBookings;
  final int availableSpaces;
  final int totalSpaces;
  final double averageRating;

  const DashboardStats({
    this.todayEarnings = 0,
    this.activeBookings = 0,
    this.availableSpaces = 0,
    this.totalSpaces = 0,
    this.averageRating = 0.0,
  });
}

final dashboardStatsProvider = Provider<DashboardStats>((ref) {
  final spaces = ref.watch(parkingSpacesProvider).value ?? [];
  final active = ref.watch(activeBookingsProvider).value ?? [];
  final summary = ref.watch(earningsSummaryProvider);

  final totalSpaces = spaces.fold<int>(0, (sum, s) => sum + s.totalSpaces);
  final availableSpaces = spaces.fold<int>(0, (sum, s) => sum + s.availableSpaces);
  final avgRating = spaces.isEmpty
      ? 0.0
      : spaces.fold<double>(0, (sum, s) => sum + s.rating) / spaces.length;

  return DashboardStats(
    todayEarnings: summary.today,
    activeBookings: active.length,
    availableSpaces: availableSpaces,
    totalSpaces: totalSpaces,
    averageRating: avgRating,
  );
});
