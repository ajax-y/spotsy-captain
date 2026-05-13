enum TransactionStatus { pending, completed, failed }
enum PayoutStatus { unpaid, paid, processing }

class Earning {
  final String id;
  final String bookingId;
  final double amount;
  final TransactionStatus transactionStatus;
  final PayoutStatus payoutStatus;
  final DateTime? payoutDate;
  final DateTime createdAt;

  const Earning({
    required this.id,
    required this.bookingId,
    required this.amount,
    this.transactionStatus = TransactionStatus.pending,
    this.payoutStatus = PayoutStatus.unpaid,
    this.payoutDate,
    required this.createdAt,
  });
}

class EarningsSummary {
  final double lifetime;
  final double thisMonth;
  final double thisWeek;
  final double today;

  const EarningsSummary({
    this.lifetime = 0,
    this.thisMonth = 0,
    this.thisWeek = 0,
    this.today = 0,
  });
}
