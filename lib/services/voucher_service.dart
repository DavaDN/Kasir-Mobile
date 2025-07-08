import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/voucher_model.dart';

class VoucherService {
  Future<Voucher> checkVoucher(String code, String token) async {
    final response = await http.get(
      Uri.parse('http://localhost:8000/api/voucher/$code'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Voucher.fromJson(data);
    } else if (response.statusCode == 404) {
      throw Exception('Kode voucher tidak ditemukan');
    } else if (response.statusCode == 401) {
      throw Exception('Token tidak valid atau tidak terkirim');
    } else {
      throw Exception('Gagal mengambil voucher: ${response.statusCode}');
    }
  }
}
