import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product_model.dart';

class ProductService {
  final String baseUrl = 'http://localhost:8000/api';

  Future<List<ProductModel>> getProducts(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/product'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body)['data'];
      return data.map((e) => ProductModel.fromJson(e)).toList();
    } else {
      throw Exception('Gagal memuat data produk');
    }
  }
}
