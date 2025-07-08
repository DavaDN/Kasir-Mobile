import 'package:flutter/material.dart';
import 'package:kasir/models/transaction_item_model.dart';
import '../services/return_service.dart';

class ReturnFormScreen extends StatefulWidget {
  final List<TransactionItemModel> products;
  final int transactionId;
  final String token;

  const ReturnFormScreen({
    super.key,
    required this.products,
    required this.transactionId,
    required this.token,
  });

  @override
  State<ReturnFormScreen> createState() => _ReturnFormScreenState();
}

class _ReturnFormScreenState extends State<ReturnFormScreen> {
  TransactionItemModel? selectedProduct;
  final _qtyController = TextEditingController();
  final _reasonController = TextEditingController();
  bool _isLoading = false;

  void _submit() async {
    final qty = int.tryParse(_qtyController.text.trim());

    if (selectedProduct == null || qty == null || qty < 1) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Pilih produk dan isi jumlah minimal 1'),
      ));
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ReturnService().submitReturn(
        productId: selectedProduct!.id, // Use the correct property for product ID
        qty: qty,
        reason: _reasonController.text.trim(),
        token: widget.token,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Retur berhasil dikirim')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengirim retur: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff8fafc),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Form Retur Barang",
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Text(
                  '📦 Retur Produk',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFB91C1C),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<TransactionItemModel>(
                  value: selectedProduct,
                  decoration: InputDecoration(
                    labelText: 'Pilih Produk',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.inventory_2),
                  ),
                  items: widget.products.map((product) {
                    return DropdownMenuItem(
                      value: product,
                      child: Text(product.productName), // Use the correct property
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => selectedProduct = value),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _qtyController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Jumlah Retur',
                    prefixIcon: const Icon(Icons.numbers),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _reasonController,
                  decoration: InputDecoration(
                    labelText: 'Alasan Retur (opsional)',
                    prefixIcon: const Icon(Icons.comment),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _submit,
                    icon: const Icon(Icons.refresh),
                    label: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Kirim Retur'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: const Color(0xFFB91C1C),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
