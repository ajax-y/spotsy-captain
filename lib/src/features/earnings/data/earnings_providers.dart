import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/earning.dart';
import '../../../models/bank_account.dart';
import '../../dashboard/data/dashboard_providers.dart';

final transactionHistoryProvider = StreamProvider<List<Earning>>((ref) {
  return ref.watch(firestoreServiceProvider).getEarnings();
});

final bankAccountsProvider = StreamProvider<List<BankAccount>>((ref) {
  return ref.watch(firestoreServiceProvider).getBankAccounts();
});

final earningsSummaryProvider = Provider<EarningsSummary>((ref) {
  final earnings = ref.watch(transactionHistoryProvider).value ?? [];
  
  double lifetime = 0;
  double thisMonth = 0;
  double thisWeek = 0;
  double today = 0;
  
  final now = DateTime.now();
  final startOfMonth = DateTime(now.year, now.month, 1);
  final startOfWeek = now.subtract(Duration(days: now.weekday % 7));
  final startOfToday = DateTime(now.year, now.month, now.day);
  
  for (var e in earnings) {
    lifetime += e.amount;
    if (e.createdAt.isAfter(startOfMonth)) thisMonth += e.amount;
    if (e.createdAt.isAfter(startOfWeek)) thisWeek += e.amount;
    if (e.createdAt.isAfter(startOfToday)) today += e.amount;
  }
  
  return EarningsSummary(
    lifetime: lifetime,
    thisMonth: thisMonth,
    thisWeek: thisWeek,
    today: today,
  );
});
