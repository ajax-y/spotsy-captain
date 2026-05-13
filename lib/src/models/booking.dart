enum BookingStatus {
  pendingOwnerConfirmation,
  confirmed,
  active,
  completed,
  cancelled,
}

enum PaymentStatus {
  pending,
  completed,
  failed,
  refunded,
}

class Booking {
  final String id;
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final String vehicleType; // Bike, Car, SUV
  final String vehicleRegistration;
  final String vehicleColor;
  final String vehicleModel;
  final String parkingSpaceId;
  final String parkingSpaceName;
  final BookingStatus status;
  final PaymentStatus paymentStatus;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final double pricePerHour;
  final double? totalAmount;
  final DateTime createdAt;

  const Booking({
    required this.id,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.vehicleType,
    required this.vehicleRegistration,
    required this.vehicleColor,
    required this.vehicleModel,
    required this.parkingSpaceId,
    required this.parkingSpaceName,
    this.status = BookingStatus.pendingOwnerConfirmation,
    this.paymentStatus = PaymentStatus.pending,
    this.checkInTime,
    this.checkOutTime,
    this.pricePerHour = 0,
    this.totalAmount,
    required this.createdAt,
  });

  bool get isPending => status == BookingStatus.pendingOwnerConfirmation;
  bool get isActive =>
      status == BookingStatus.confirmed || status == BookingStatus.active;

  factory Booking.fromMap(Map<String, dynamic> map, String id) {
    return Booking(
      id: id,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? 'Unknown User',
      userPhotoUrl: map['userPhotoUrl'],
      vehicleType: map['vehicleType'] ?? 'Car',
      vehicleRegistration: map['vehicleRegistration'] ?? '',
      vehicleColor: map['vehicleColor'] ?? '',
      vehicleModel: map['vehicleModel'] ?? '',
      parkingSpaceId: map['parkingSpaceId'] ?? '',
      parkingSpaceName: map['parkingSpaceName'] ?? '',
      status: _statusFromString(map['status']),
      paymentStatus: _paymentStatusFromString(map['paymentStatus']),
      checkInTime: map['checkInTime'] != null ? DateTime.parse(map['checkInTime']) : null,
      checkOutTime: map['checkOutTime'] != null ? DateTime.parse(map['checkOutTime']) : null,
      pricePerHour: (map['pricePerHour'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (map['totalAmount'] as num?)?.toDouble(),
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : DateTime.now(),
    );
  }

  static BookingStatus _statusFromString(String? status) {
    switch (status) {
      case 'CONFIRMED': return BookingStatus.confirmed;
      case 'ACTIVE': return BookingStatus.active;
      case 'COMPLETED': return BookingStatus.completed;
      case 'CANCELLED': return BookingStatus.cancelled;
      default: return BookingStatus.pendingOwnerConfirmation;
    }
  }

  static PaymentStatus _paymentStatusFromString(String? status) {
    switch (status) {
      case 'COMPLETED': return PaymentStatus.completed;
      case 'FAILED': return PaymentStatus.failed;
      case 'REFUNDED': return PaymentStatus.refunded;
      default: return PaymentStatus.pending;
    }
  }
}
