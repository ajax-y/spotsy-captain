import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../models/bank_account.dart';
import '../data/earnings_providers.dart';

class EarningsScreen extends ConsumerWidget {
  const EarningsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(earningsSummaryProvider);
    final transactions = ref.watch(transactionHistoryProvider);
    final accounts = ref.watch(bankAccountsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Earnings', style: TextStyle(fontWeight: FontWeight.bold))),
      body: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Earnings overview cards
        Container(padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [theme.colorScheme.primary.withValues(alpha: 0.2), theme.colorScheme.primary.withValues(alpha: 0.05)],
              begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(20)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Lifetime Earnings', style: TextStyle(color: Colors.grey[400], fontSize: 13)),
            const SizedBox(height: 4),
            Text('₹${summary.lifetime.toStringAsFixed(0)}',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
          ])),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: _miniCard(context, 'This Month', '₹${summary.thisMonth.toStringAsFixed(0)}')),
          const SizedBox(width: 12),
          Expanded(child: _miniCard(context, 'This Week', '₹${summary.thisWeek.toStringAsFixed(0)}')),
          const SizedBox(width: 12),
          Expanded(child: _miniCard(context, 'Today', '₹${summary.today.toStringAsFixed(0)}')),
        ]),
        const SizedBox(height: 28),
        // Bank accounts
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Bank Accounts', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          TextButton.icon(onPressed: () => context.go('/earnings/bank-account'),
            icon: const Icon(Icons.add, size: 18), label: const Text('Link')),
        ]),
        accounts.when(
          data: (list) => list.isEmpty
            ? Container(padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: const Color(0xFF252525), borderRadius: BorderRadius.circular(16)),
                child: Row(children: [
                  Icon(Icons.account_balance_outlined, color: Colors.grey[600], size: 32), const SizedBox(width: 16),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('No bank account linked', style: TextStyle(color: Colors.grey[400])),
                    const SizedBox(height: 2),
                    Text('Link one to receive payouts', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  ])),
                ]))
            : Column(children: list.map((a) => _bankCard(context, a)).toList()),
          loading: () => const LinearProgressIndicator(),
          error: (e, s) => Text('Error: $e', style: const TextStyle(color: Colors.red)),
        ),
        const SizedBox(height: 28),
        // Transaction history
        Text('Transaction History', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        transactions.when(
          data: (list) => list.isEmpty
            ? Container(padding: const EdgeInsets.symmetric(vertical: 48),
                child: Center(child: Column(children: [
                  Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey[700]),
                  const SizedBox(height: 12),
                  Text('No transactions yet', style: TextStyle(color: Colors.grey[600])),
                ])))
            : Column(children: list.map((e) => Container(
                margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: const Color(0xFF252525), borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  Icon(Icons.receipt, color: theme.colorScheme.primary, size: 20), const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Booking #${e.bookingId.length > 8 ? e.bookingId.substring(0, 8) : e.bookingId}', style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text('${e.createdAt.day}/${e.createdAt.month}/${e.createdAt.year}', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                  ])),
                  Text('₹${e.amount.toStringAsFixed(0)}', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                ]))).toList()),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Text('Error: $e'),
        ),
      ])),
    );
  }

  Widget _miniCard(BuildContext context, String label, String value) {
    return Container(padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xFF252525), borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
      ]));
  }

  Widget _bankCard(BuildContext context, BankAccount a) {
    final theme = Theme.of(context);
    return Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xFF252525), borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: theme.colorScheme.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(Icons.account_balance, color: theme.colorScheme.primary, size: 20)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(a.bankName, style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(a.maskedAccountNumber, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
        ])),
        if (a.isPrimary) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: theme.colorScheme.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
          child: Text('PRIMARY', style: TextStyle(color: theme.colorScheme.primary, fontSize: 10, fontWeight: FontWeight.bold))),
        if (a.isVerified) ...[const SizedBox(width: 6), const Icon(Icons.verified, color: Colors.green, size: 18)],
      ]));
  }
}
