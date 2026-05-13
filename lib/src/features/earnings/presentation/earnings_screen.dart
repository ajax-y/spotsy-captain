import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../common_widgets/glass_container.dart';
import '../../../models/earning.dart';
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
      body: Stack(
        children: [
          // Background Blobs
          Positioned(top: -50, right: -50, child: _GlowBlob(color: theme.colorScheme.primary.withValues(alpha: 0.1))),
          
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Earnings', style: theme.textTheme.headlineMedium),
                      const GlassContainer(
                        padding: EdgeInsets.all(12),
                        borderRadius: 16,
                        child: Icon(Icons.tune_rounded, color: Colors.white, size: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  
                  // Main Wallet Card
                  GlassContainer(
                    padding: const EdgeInsets.all(24),
                    borderRadius: 32,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Wallet Balance', style: TextStyle(color: Colors.white54, fontSize: 14)),
                            Icon(Icons.account_balance_wallet_rounded, color: theme.colorScheme.primary, size: 24),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('₹${summary.lifetime.toInt()}', style: theme.textTheme.displayMedium),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            _WalletAction(icon: Icons.add_rounded, label: 'Add', color: theme.colorScheme.primary),
                            const SizedBox(width: 16),
                            _WalletAction(icon: Icons.north_east_rounded, label: 'Payout', color: Colors.white),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Stats Grid
                  Row(
                    children: [
                      Expanded(child: _miniStatCard(context, 'This Month', '₹${summary.thisMonth.toInt()}')),
                      const SizedBox(width: 16),
                      Expanded(child: _miniStatCard(context, 'Today', '₹${summary.today.toInt()}')),
                    ],
                  ),
                  const SizedBox(height: 32),
                  
                  // Bank Accounts Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Bank Accounts', style: theme.textTheme.titleLarge),
                      TextButton.icon(
                        onPressed: () => context.go('/earnings/bank-account'),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add New'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  accounts.when(
                    data: (list) => list.isEmpty
                        ? _buildEmptyState('No bank account linked')
                        : Column(children: list.map((a) => _bankCard(context, a)).toList()),
                    loading: () => const LinearProgressIndicator(),
                    error: (e, s) => Text('Error: $e'),
                  ),
                  const SizedBox(height: 32),
                  
                  // Transactions Section
                  Text('Recent Transactions', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 16),
                  transactions.when(
                    data: (list) => list.isEmpty
                        ? _buildEmptyState('No transactions yet')
                        : Column(children: list.map((e) => _transactionTile(context, e)).toList()),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, s) => Text('Error: $e'),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStatCard(BuildContext context, String label, String value) {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: 24,
      opacity: 0.03,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String msg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.02), borderRadius: BorderRadius.circular(24)),
      child: Center(child: Text(msg, style: const TextStyle(color: Colors.white38))),
    );
  }

  Widget _bankCard(BuildContext context, BankAccount a) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        borderRadius: 20,
        opacity: 0.05,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: theme.colorScheme.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(Icons.account_balance_rounded, color: theme.colorScheme.primary, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(a.bankName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(a.maskedAccountNumber, style: const TextStyle(color: Colors.white54, fontSize: 13)),
                ],
              ),
            ),
            if (a.isPrimary)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: theme.colorScheme.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                child: Text('Primary', style: TextStyle(color: theme.colorScheme.primary, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _transactionTile(BuildContext context, Earning e) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        borderRadius: 20,
        opacity: 0.03,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), shape: BoxShape.circle),
              child: Icon(Icons.arrow_downward_rounded, color: theme.colorScheme.primary, size: 18),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Payout to Bank', style: const TextStyle(fontWeight: FontWeight.w500)),
                  Text('${e.createdAt.day}/${e.createdAt.month}/${e.createdAt.year}', style: const TextStyle(color: Colors.white38, fontSize: 12)),
                ],
              ),
            ),
            Text('₹${e.amount.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}

class _WalletAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _WalletAction({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: color.withValues(alpha: color == Colors.white ? 0.05 : 1), borderRadius: BorderRadius.circular(16)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color == Colors.white ? Colors.white : Colors.black, size: 18),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: color == Colors.white ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  final Color color;
  const _GlowBlob({required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(width: 400, height: 400, decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100), child: Container(color: Colors.transparent)));
  }
}
