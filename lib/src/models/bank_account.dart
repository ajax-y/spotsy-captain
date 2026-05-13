enum BankAccountType { savings, current }

class BankAccount {
  final String id;
  final String holderName;
  final String accountNumber;
  final String ifscCode;
  final String bankName;
  final BankAccountType accountType;
  final bool isVerified;
  final bool isPrimary;
  final DateTime createdAt;

  const BankAccount({
    required this.id,
    required this.holderName,
    required this.accountNumber,
    required this.ifscCode,
    required this.bankName,
    this.accountType = BankAccountType.savings,
    this.isVerified = false,
    this.isPrimary = false,
    required this.createdAt,
  });

  /// Masked account number for display (e.g., "XXXX XXXX 1234")
  String get maskedAccountNumber {
    if (accountNumber.length <= 4) return accountNumber;
    final last4 = accountNumber.substring(accountNumber.length - 4);
    return 'XXXX XXXX $last4';
  }
}
