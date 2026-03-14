import 'package:flutter/material.dart';

@immutable
class Customer {
  final int? id; // SQLite otomatik artan ID için int ve nullable
  final String name;
  final String phone;
  final double balance;   // Borç takibi
  final double points;    // Müşteri puanı
  final String createdAt; // Kayıt tarihi

  const Customer({
    this.id,
    required this.name,
    required this.phone,
    this.balance = 0.0,
    this.points = 0.0,
    required this.createdAt,
  });

  // Veriyi güncellerken (Örn: Borç eklerken) kolaylık sağlar
  Customer copyWith({
    int? id,
    String? name,
    String? phone,
    double? balance,
    double? points,
    String? createdAt,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      balance: balance ?? this.balance,
      points: points ?? this.points,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Veritabanından gelen Map'i nesneye çevirir
  factory Customer.fromMap(Map<String, dynamic> map) => Customer(
        id: map['id'] as int?,
        name: map['name'] ?? 'Bilinmeyen Müşteri',
        phone: map['phone'] ?? '',
        balance: (map['balance'] as num?)?.toDouble() ?? 0.0,
        points: (map['points'] as num?)?.toDouble() ?? 0.0,
        createdAt: map['createdAt'] ?? '',
      );

  // Nesneyi veritabanına kaydedilecek Map formatına çevirir
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id, // ID varsa ekle (Update), yoksa SQLite kendi atar (Insert)
      'name': name,
      'phone': phone,
      'balance': balance,
      'points': points,
      'createdAt': createdAt,
    };
  }
}