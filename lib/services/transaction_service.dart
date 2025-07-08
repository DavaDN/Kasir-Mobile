import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/cart_item_model.dart';
import '../models/transaction_model.dart';

class TransactionService {
  Future<void> checkout({
    required List<CartItem> cartItems,
    required String token,
    required int total,
    required int payment,
    required int change, String? voucherCode,
  }) async {
    const String url = 'http://localhost:8000/api/transaction';

    final items = cartItems
        .map((item) => {
              'product_id': item.product.id,
              'qty': item.quantity,
              'price': item.product.price,
            })
        .toList();

    final body = jsonEncode({
      'total': total,
      'payment': payment,
      'change': change,
      'items': items,
      'voucher_code': voucherCode,
    });

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: body,
    );

    if (response.statusCode != 200) {
      throw Exception('Gagal menyimpan transaksi: ${response.body}');
    }
  }

  Future<List<TransactionModel>> getTransactions(
      {required String token}) async {
    const String url = 'http://localhost:8000/api/transaction';

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Gagal mengambil data transaksi: ${response.body}');
    }

    final Map<String, dynamic> responseData = jsonDecode(response.body);
    final List list = responseData['data'];

    return list.map((e) => TransactionModel.fromJson(e)).toList();
  }

  Future<TransactionModel> getTransactionById({
    required int id,
    required String token,
  }) async {
    final response = await http.get(
      Uri.parse('http://localhost:8000/api/transaction/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return TransactionModel.fromJson(data['data']);
    } else {
      throw Exception('Gagal mengambil detail transaksi');
    }
  }
}
