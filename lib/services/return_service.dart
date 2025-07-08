import 'package:http/http.dart' as http;

class ReturnService {
  Future<void> submitReturn({
    required int productId,
    required int qty,
    String? reason,
    required String token,
  }) async {
    final response = await http.post(
      Uri.parse('http://localhost:8000/api/return'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
      body: {
        'product_id': productId.toString(),
        'qty': qty.toString(),
        'reason': reason ?? '',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Gagal menyimpan retur: ${response.body}');
    }
  }
}
