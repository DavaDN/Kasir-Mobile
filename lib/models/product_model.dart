class ProductModel {
  final int id;
  final String code;
  final String name;
  final String? image;
  final String brand;
  final String category;
  final int stock;
  final int price;

  ProductModel({
    required this.id,
    required this.code,
    required this.name,
    this.image,
    required this.brand,
    required this.category,
    required this.stock,
    required this.price,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    int latestPrice = 0;
    if (json['prices'] != null &&
        json['prices'] is List &&
        json['prices'].isNotEmpty) {
      final priceData = json['prices'].last;
      final rawPrice = priceData['price'];
      latestPrice = (rawPrice is int)
          ? rawPrice
          : int.tryParse(rawPrice.toString().split('.').first) ?? 0;
    }

    int totalStock = 0;
    if (json['stocks'] != null && json['stocks'] is List) {
      for (var stock in json['stocks']) {
        final type = stock['type'];
        final qty = stock['qty'];
        int intQty = (qty is int)
            ? qty
            : int.tryParse(qty.toString().split('.').first) ?? 0;

        if (type == 'in') {
          totalStock += intQty;
        } else if (type == 'out') {
          totalStock -= intQty;
        }
      }
    }

    return ProductModel(
      id: json['id'] ?? 0,
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      image: json['image'],
      brand: json['brand']?['name'] ?? '',
      category: json['category']?['name'] ?? '',
      stock: totalStock,
      price: latestPrice,
    );
  }
}
