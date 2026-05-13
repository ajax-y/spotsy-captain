import 'package:cloud_firestore/cloud_firestore.dart';

enum SpaceType { bike, carSmall, carLarge, mixed }

class ParkingSpacePhoto {
  final String id;
  final String url;
  final String type; // FULL_VIEW, ENTRY, SPACE, AMENITY
  final int displayOrder;

  const ParkingSpacePhoto({
    required this.id,
    required this.url,
    required this.type,
    this.displayOrder = 0,
  });
}

class ParkingSpace {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final int totalSpaces;
  final int availableSpaces;
  final SpaceType spaceType;
  final double pricePerHour;
  final bool hasEvCharging;
  final bool hasCctv;
  final bool hasSecurity;
  final bool hasLighting;
  final bool isCovered;
  final String description;
  final String? openingTime;
  final String? closingTime;
  final bool is24x7;
  final bool isActive;
  final double rating;
  final int totalRatings;
  final List<ParkingSpacePhoto> photos;
  final DateTime createdAt;

  const ParkingSpace({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.totalSpaces = 0,
    this.availableSpaces = 0,
    this.spaceType = SpaceType.mixed,
    this.pricePerHour = 0,
    this.hasEvCharging = false,
    this.hasCctv = false,
    this.hasSecurity = false,
    this.hasLighting = false,
    this.isCovered = false,
    this.description = '',
    this.openingTime,
    this.closingTime,
    this.is24x7 = false,
    this.isActive = true,
    this.rating = 0,
    this.totalRatings = 0,
    this.photos = const [],
    required this.createdAt,
  });

  /// Occupancy ratio from 0.0 to 1.0
  double get occupancyRate =>
      totalSpaces > 0 ? 1.0 - (availableSpaces / totalSpaces) : 0.0;

  ParkingSpace copyWith({
    String? id,
    String? name,
    String? address,
    double? latitude,
    double? longitude,
    int? totalSpaces,
    int? availableSpaces,
    SpaceType? spaceType,
    double? pricePerHour,
    bool? hasEvCharging,
    bool? hasCctv,
    bool? hasSecurity,
    bool? hasLighting,
    bool? isCovered,
    String? description,
    String? openingTime,
    String? closingTime,
    bool? is24x7,
    bool? isActive,
    double? rating,
    int? totalRatings,
    List<ParkingSpacePhoto>? photos,
    DateTime? createdAt,
  }) {
    return ParkingSpace(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      totalSpaces: totalSpaces ?? this.totalSpaces,
      availableSpaces: availableSpaces ?? this.availableSpaces,
      spaceType: spaceType ?? this.spaceType,
      pricePerHour: pricePerHour ?? this.pricePerHour,
      hasEvCharging: hasEvCharging ?? this.hasEvCharging,
      hasCctv: hasCctv ?? this.hasCctv,
      hasSecurity: hasSecurity ?? this.hasSecurity,
      hasLighting: hasLighting ?? this.hasLighting,
      isCovered: isCovered ?? this.isCovered,
      description: description ?? this.description,
      openingTime: openingTime ?? this.openingTime,
      closingTime: closingTime ?? this.closingTime,
      is24x7: is24x7 ?? this.is24x7,
      isActive: isActive ?? this.isActive,
      rating: rating ?? this.rating,
      totalRatings: totalRatings ?? this.totalRatings,
      photos: photos ?? this.photos,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'totalSpaces': totalSpaces,
      'availableSpaces': availableSpaces,
      'spaceType': spaceType.name,
      'pricePerHour': pricePerHour,
      'hasEvCharging': hasEvCharging,
      'hasCctv': hasCctv,
      'hasSecurity': hasSecurity,
      'hasLighting': hasLighting,
      'isCovered': isCovered,
      'description': description,
      'openingTime': openingTime,
      'closingTime': closingTime,
      'is24x7': is24x7,
      'isActive': isActive,
      'rating': rating,
      'totalRatings': totalRatings,
      'photos': photos.map((p) => {
        'id': p.id,
        'url': p.url,
        'type': p.type,
        'displayOrder': p.displayOrder,
      }).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ParkingSpace.fromMap(Map<String, dynamic> map, String id) {
    return ParkingSpace(
      id: id,
      name: map['name'] ?? '',
      address: map['address'] ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      totalSpaces: map['totalSpaces'] ?? 0,
      availableSpaces: map['availableSpaces'] ?? 0,
      spaceType: SpaceType.values.firstWhere(
        (e) => e.name == map['spaceType'],
        orElse: () => SpaceType.mixed,
      ),
      pricePerHour: (map['pricePerHour'] as num?)?.toDouble() ?? 0.0,
      hasEvCharging: map['hasEvCharging'] ?? false,
      hasCctv: map['hasCctv'] ?? false,
      hasSecurity: map['hasSecurity'] ?? false,
      hasLighting: map['hasLighting'] ?? false,
      isCovered: map['isCovered'] ?? false,
      description: map['description'] ?? '',
      openingTime: map['openingTime'],
      closingTime: map['closingTime'],
      is24x7: map['is24x7'] ?? false,
      isActive: map['isActive'] ?? true,
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      totalRatings: map['totalRatings'] ?? 0,
      photos: (map['photos'] as List?)?.map((p) => ParkingSpacePhoto(
        id: p['id'],
        url: p['url'],
        type: p['type'],
        displayOrder: p['displayOrder'] ?? 0,
      )).toList() ?? [],
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] is String 
              ? DateTime.parse(map['createdAt']) 
              : (map['createdAt'] as Timestamp).toDate())
          : DateTime.now(),
    );
  }
}
