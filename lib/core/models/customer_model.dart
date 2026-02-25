import 'package:flutter/material.dart';

@immutable
class Customer {
  final int? id; // SQLite otomatik ID vereceği için nullable olmalı
  final String name;
  final String phone;
  final double balance; // Borç takibi için şart!
  final double points;
  final String createdAt;

  const Customer({
    this.id,
    required this.name,
    required this.phone,
    this.balance = 0.0, // Varsayılan 0 borç
    this.points = 0.0,
    required this.createdAt,
  });

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

  factory Customer.fromMap(Map<String, dynamic> map) => Customer(
        id: map['id'] as int?,
        name: map['name'] ?? 'Bilinmeyen Müşteri',
        phone: map['phone'] ?? '',
        balance: (map['balance'] as num?)?.toDouble() ?? 0.0,
        points: (map['points'] as num?)?.toDouble() ?? 0.0,
        createdAt: map['createdAt'] ?? '',
      );

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'name': name,
      'phone': phone,
      'balance': balance,
      'points': points,
      'createdAt': createdAt,
    };
    if (id != null) map['id'] = id; // ID varsa ekle (Update için), yoksa ekleme (Insert için)
    return map;
  }
}