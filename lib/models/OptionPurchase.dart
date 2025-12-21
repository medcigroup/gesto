import 'package:cloud_firestore/cloud_firestore.dart';
import '../components/checkin/options_package_section.dart';

// Classe pour stocker les détails d'une option achetée
class PurchasedOption {
  final HotelPackage package;
  final String period; // 'hour', 'day', 'week', 'month'
  final int quantity;
  final double unitPrice;
  final double subtotal;

  // Getter pour faciliter l'accès au nom du package
  String get packageName => package.name;

  PurchasedOption({
    required this.package,
    required this.period,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': package.id,
      'name': package.name,
      'description': package.description,
      'icon': package.icon,
      'category': package.category,
      'period': period,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'subtotal': subtotal,
    };
  }

  factory PurchasedOption.fromMap(Map<String, dynamic> map) {
    return PurchasedOption(
      package: HotelPackage(
        id: map['id'] ?? '',
        name: map['name'] ?? '',
        description: map['description'] ?? '',
        icon: map['icon'] ?? 'hotel',
        isIncluded: false,
        category: map['category'] ?? 'amenities',
        pricing: PackagePricing(
          pricePerHour: null,
          pricePerDay: null,
          pricePerWeek: null,
          pricePerMonth: null,
        ),
      ),
      period: map['period'] ?? 'day',
      quantity: map['quantity'] ?? 1,
      unitPrice: (map['unitPrice'] ?? 0).toDouble(),
      subtotal: (map['subtotal'] ?? 0).toDouble(),
    );
  }
}

class OptionPurchase {
  final String id;
  final String hotelId;
  final String? hotelName;
  final String? bookingId;
  final String customerName;
  final String customerEmail;
  final String customerPhone;
  final String? roomNumber;
  final List<PurchasedOption> purchasedOptions;
  final double totalAmount;
  final String paymentMethod;
  final DateTime purchaseDate;
  final String status; // 'paid', 'pending', 'cancelled'

  OptionPurchase({
    required this.id,
    required this.hotelId,
    this.hotelName,
    this.bookingId,
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
    this.roomNumber,
    required this.purchasedOptions,
    required this.totalAmount,
    required this.paymentMethod,
    required this.purchaseDate,
    required this.status,
  });

  // Créer depuis Map
  factory OptionPurchase.fromMap(Map<String, dynamic> data, String docId) {
    return OptionPurchase(
      id: docId,
      hotelId: data['hotelId'] ?? '',
      hotelName: data['hotelName'],
      bookingId: data['bookingId'],
      customerName: data['customerName'] ?? '',
      customerEmail: data['customerEmail'] ?? '',
      customerPhone: data['customerPhone'] ?? '',
      roomNumber: data['roomNumber'],
      purchasedOptions: (data['purchasedOptions'] as List<dynamic>?)
              ?.map((item) => PurchasedOption.fromMap(item))
              .toList() ??
          [],
      totalAmount: (data['totalAmount'] ?? 0).toDouble(),
      paymentMethod: data['paymentMethod'] ?? 'Espèces',
      purchaseDate: (data['purchaseDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: data['status'] ?? 'pending',
    );
  }

  // Créer depuis Firestore
  factory OptionPurchase.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return OptionPurchase(
      id: doc.id,
      hotelId: data['hotelId'] ?? '',
      hotelName: data['hotelName'],
      bookingId: data['bookingId'],
      customerName: data['customerName'] ?? '',
      customerEmail: data['customerEmail'] ?? '',
      customerPhone: data['customerPhone'] ?? '',
      roomNumber: data['roomNumber'],
      purchasedOptions: (data['purchasedOptions'] as List<dynamic>?)
              ?.map((item) => PurchasedOption.fromMap(item))
              .toList() ??
          [],
      totalAmount: (data['totalAmount'] ?? 0).toDouble(),
      paymentMethod: data['paymentMethod'] ?? 'Espèces',
      purchaseDate: (data['purchaseDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: data['status'] ?? 'pending',
    );
  }

  // Convertir en Map pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'hotelId': hotelId,
      'hotelName': hotelName,
      'bookingId': bookingId,
      'customerName': customerName,
      'customerEmail': customerEmail,
      'customerPhone': customerPhone,
      'roomNumber': roomNumber,
      'purchasedOptions': purchasedOptions.map((option) => option.toMap()).toList(),
      'totalAmount': totalAmount,
      'paymentMethod': paymentMethod,
      'purchaseDate': Timestamp.fromDate(purchaseDate),
      'status': status,
    };
  }

  // Copier avec modification
  OptionPurchase copyWith({
    String? id,
    String? hotelId,
    String? hotelName,
    String? bookingId,
    String? customerName,
    String? customerEmail,
    String? customerPhone,
    String? roomNumber,
    List<PurchasedOption>? purchasedOptions,
    double? totalAmount,
    String? paymentMethod,
    DateTime? purchaseDate,
    String? status,
  }) {
    return OptionPurchase(
      id: id ?? this.id,
      hotelId: hotelId ?? this.hotelId,
      hotelName: hotelName ?? this.hotelName,
      bookingId: bookingId ?? this.bookingId,
      customerName: customerName ?? this.customerName,
      customerEmail: customerEmail ?? this.customerEmail,
      customerPhone: customerPhone ?? this.customerPhone,
      roomNumber: roomNumber ?? this.roomNumber,
      purchasedOptions: purchasedOptions ?? this.purchasedOptions,
      totalAmount: totalAmount ?? this.totalAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      status: status ?? this.status,
    );
  }
}
