import 'package:flutter/material.dart';

@immutable
class Customer {
  final int? id;
  final String name;
  final String phone;
  final double points;
  final String createdAt;

  const Customer({
    this.id,
    required this.name,
    required this.phone,
    this.points = 0.0,
    required this.createdAt,
  });

  Customer copyWith({int? id, String? name, String? phone, double? points, String? createdAt}) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      points: points ?? this.points,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory Customer.fromMap(Map<String, dynamic> map) => Customer(
        id: map['id'],
        name: map['name'] ?? 'Bilinmeyen Müşteri',
        phone: map['phone'] ?? '',
        points: (map['points'] as num?)?.toDouble() ?? 0.0,
        createdAt: map['createdAt'] ?? '',
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'phone': phone,
        'points': points,
        'createdAt': createdAt,
      };
}