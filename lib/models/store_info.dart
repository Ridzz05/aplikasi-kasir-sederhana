import 'dart:convert';
import 'package:flutter/foundation.dart';

class StoreInfo {
  final String storeName;
  final String address;
  final String phone;
  final String cashierName;
  final String? logoPath;
  final bool showLogo;
  final String? receiptFooter;

  StoreInfo({
    required this.storeName,
    required this.address,
    required this.phone,
    required this.cashierName,
    this.logoPath,
    this.showLogo = false,
    this.receiptFooter,
  });

  // Constructors to create default store info
  factory StoreInfo.defaultInfo() {
    return StoreInfo(
      storeName: 'APLIKASI KASIR',
      address: 'Jl. Contoh No. 123, Kota',
      phone: '(021) 123-4567',
      cashierName: 'Admin',
      receiptFooter:
          'Terima kasih telah berbelanja\nBarang yang sudah dibeli tidak dapat dikembalikan',
    );
  }

  // Convert to Map for storage
  Map<String, dynamic> toMap() {
    return {
      'storeName': storeName,
      'address': address,
      'phone': phone,
      'cashierName': cashierName,
      'logoPath': logoPath,
      'showLogo': showLogo,
      'receiptFooter': receiptFooter,
    };
  }

  // Create StoreInfo from map
  factory StoreInfo.fromMap(Map<String, dynamic> map) {
    return StoreInfo(
      storeName: map['storeName'] ?? '',
      address: map['address'] ?? '',
      phone: map['phone'] ?? '',
      cashierName: map['cashierName'] ?? '',
      logoPath: map['logoPath'],
      showLogo: map['showLogo'] ?? false,
      receiptFooter: map['receiptFooter'],
    );
  }

  // Serialize to JSON string
  String toJson() => json.encode(toMap());

  // Create from JSON string
  factory StoreInfo.fromJson(String source) =>
      StoreInfo.fromMap(json.decode(source));

  // Copy with new values
  StoreInfo copyWith({
    String? storeName,
    String? address,
    String? phone,
    String? cashierName,
    String? logoPath,
    bool? showLogo,
    String? receiptFooter,
  }) {
    return StoreInfo(
      storeName: storeName ?? this.storeName,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      cashierName: cashierName ?? this.cashierName,
      logoPath: logoPath ?? this.logoPath,
      showLogo: showLogo ?? this.showLogo,
      receiptFooter: receiptFooter ?? this.receiptFooter,
    );
  }
}
