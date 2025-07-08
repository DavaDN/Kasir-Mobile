import 'package:flutter/material.dart';
import '../models/cart_item_model.dart';
import '../models/voucher_model.dart';
import '../services/transaction_service.dart';
import '../services/voucher_service.dart';

class OrderScreen extends StatefulWidget {
  final List<CartItem> cartItems;
  final String token;
  final void Function() onClearCart;

  const OrderScreen({
    super.key,
    required this.cartItems,
    required this.token,
    required this.onClearCart, required int discount,
  });

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  final _voucherController = TextEditingController();
  final _paymentController = TextEditingController();
  Voucher? _voucher;
  bool _isLoading = false;

  int get totalBeforeDiscount => widget.cartItems
      .fold(0, (sum, item) => sum + item.product.price * item.quantity);

  int get discount => _voucher != null
      ? ((totalBeforeDiscount * _voucher!.discount) / 100).round()
      : 0;

  int get totalAfterDiscount => totalBeforeDiscount - discount;
  int get payment => int.tryParse(_paymentController.text) ?? 0;
  int get change => payment - totalAfterDiscount;

  Future<void> _checkVoucher(String code) async {
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan kode voucher.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final voucher = await VoucherService().checkVoucher(code, widget.token);
      setState(() => _voucher = voucher);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Voucher "${voucher.code}" berhasil digunakan!')),
      );
    } catch (e) {
      setState(() => _voucher = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkout() async {
    if (widget.cartItems.isEmpty) return;
    if (payment < totalAfterDiscount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jumlah pembayaran kurang!')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await TransactionService().checkout(
        cartItems: widget.cartItems,
        token: widget.token,
        payment: payment,
        change: change,
        total: totalAfterDiscount,
        voucherCode: _voucher?.code, // Kirim voucher ke backend
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaksi berhasil disimpan!')),
      );
      widget.onClearCart();
      Navigator.pop(context); // Kembali ke ProductScreen
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal checkout: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _voucherController.dispose();
    _paymentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff8fafc),
      appBar: AppBar(
        backgroundColor: const Color(0xFFB91C1C),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('🧾 Ringkasan Order'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: widget.cartItems.isEmpty
                  ? const Center(child: Text('Keranjang kosong.'))
                  : ListView.builder(
                      itemCount: widget.cartItems.length,
                      itemBuilder: (context, index) {
                        final item = widget.cartItems[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.product.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Total: Rp ${item.product.price * item.quantity}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black54,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Jumlah:'),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                              Icons.remove_circle_outline),
                                          onPressed: () {
                                            setState(() {
                                              if (item.quantity > 1) {
                                                item.quantity--;
                                              } else {
                                                widget.cartItems
                                                    .removeAt(index);
                                              }
                                            });
                                          },
                                        ),
                                        Text(
                                          '${item.quantity}',
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                              Icons.add_circle_outline),
                                          onPressed: () {
                                            setState(() {
                                              item.quantity++;
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const Divider(),
            TextField(
              controller: _voucherController,
              decoration: InputDecoration(
                labelText: 'Kode Voucher',
                prefixIcon: const Icon(Icons.discount),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.check),
                  onPressed: () =>
                      _checkVoucher(_voucherController.text.trim()),
                ),
                border: const OutlineInputBorder(),
              ),
            ),
            if (_voucher != null) ...[
              const SizedBox(height: 6),
              Chip(
                label: Text('Voucher aktif: ${_voucher!.code}'),
                backgroundColor: Colors.green.shade100,
                avatar: const Icon(Icons.discount, color: Colors.green),
              ),
            ],
            const SizedBox(height: 12),
            Text('Total Sebelum Diskon: Rp $totalBeforeDiscount',
                style: const TextStyle(fontSize: 14, color: Colors.grey)),
            Text('Diskon (${_voucher?.discount ?? 0}%): Rp $discount',
                style: const TextStyle(fontSize: 14, color: Colors.grey)),
            Text('Total Bayar: Rp $totalAfterDiscount',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: _paymentController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Pembayaran',
                prefixIcon: Icon(Icons.payments),
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 6),
            Text('Kembalian: Rp ${change < 0 ? 0 : change}',
                style: const TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _checkout,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: const Color(0xFFB91C1C),
                ),
                icon: const Icon(Icons.check),
                label: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Checkout & Simpan Transaksi',
                        style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
