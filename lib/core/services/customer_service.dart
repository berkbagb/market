import 'package:hive_flutter/hive_flutter.dart';
import '../models/customer.dart';

class CustomerService {
  final String _boxName = 'customers';

  // Tüm müşterileri getir
  List<Customer> getAllCustomers() {
    final box = Hive.box<Customer>(_boxName);
    return box.values.toList();
  }

  // Yeni müşteri ekle
  Future<void> addCustomer(Customer customer) async {
    final box = Hive.box<Customer>(_boxName);
    await box.put(customer.id, customer);
  }

  // Borç ekle (Veresiye satışı için)
  Future<void> updateBalance(String customerId, double amount) async {
    final box = Hive.box<Customer>(_boxName);
    final customer = box.get(customerId);
    if (customer != null) {
      customer.balance += amount;
      await customer.save();
    }
  }
}