class TransactionItemModel {
  final int id;
  final String productName;
  final int qty;
  final int price;

  TransactionItemModel({
    required this.id,
    required this.productName,
    required this.qty,
    required this.price,
  });

  factory TransactionItemModel.fromJson(Map<String, dynamic> json) {
    return TransactionItemModel(
      id: json['id'],
      productName: json['product']?['name'] ?? 'Tidak diketahui',
      qty: _parseToInt(json['qty']),
      price: _parseToInt(json['price']),
    );
  }

  static int _parseToInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return double.tryParse(value)?.round() ?? 0;
    return 0;
  }
}
