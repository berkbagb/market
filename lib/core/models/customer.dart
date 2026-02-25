import 'package:hive/hive.dart';

part 'customer.g.dart'; // Bu dosya build_runner çalışınca oluşacak

@HiveType(typeId: 1) // Customers için 1 numarasını ayırdık
class Customer extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String phone;

  @HiveField(3)
  double balance; // Güncel borç miktarı

  Customer({
    required this.id,
    required this.name,
    required this.phone,
    this.balance = 0.0,
  });
}