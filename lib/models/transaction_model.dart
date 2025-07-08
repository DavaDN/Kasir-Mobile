import 'transaction_item_model.dart';

class TransactionModel {
  final int id;
  final int total;
  final int payment;
  final int change;
  final DateTime createdAt;
  final List<TransactionItemModel> items;

  final String? voucherCode;
  final String? code;
  final String? kasirName;
  final String? paymentType;

  TransactionModel({
    required this.id,
    required this.total,
    required this.payment,
    required this.change,
    required this.createdAt,
    required this.items,
    this.voucherCode,
    this.code,
    this.kasirName,
    this.paymentType,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'],
      total: _parseToInt(json['total']),
      payment: _parseToInt(json['payment']),
      change: _parseToInt(json['change']),
      createdAt: DateTime.parse(json['created_at']),
      items: (json['items'] as List)
          .map((e) => TransactionItemModel.fromJson(e))
          .toList(),
      code: json['code'] ?? '',
      voucherCode: json['voucher_code'],
      kasirName: json['kasir']?['name'] ?? '',
      paymentType: json['payment_type'] ?? 'Tunai',
    );
  }

  static int _parseToInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return double.tryParse(value)?.round() ?? 0;
    return 0;
  }
}
