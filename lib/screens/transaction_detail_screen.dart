import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:url_launcher/url_launcher.dart';

import '../models/transaction_model.dart';
import '../models/transaction_item_model.dart';
import 'return_screen.dart';

class TransactionDetailScreen extends StatelessWidget {
  final TransactionModel transaction;
  final List<TransactionItemModel> items;
  final String token;

  const TransactionDetailScreen({
    super.key,
    required this.transaction,
    required this.items,
    required this.token,
  });

  String formatCurrency(int value) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff1f5f9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: const BackButton(color: Colors.black),
        title: const Text(
          'Detail Transaksi',
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildAmountCard(),
            const SizedBox(height: 16),
            _buildInfoSection(),
            const SizedBox(height: 16),
            _buildItemList(),
            const SizedBox(height: 24),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountCard() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(16),
        width: 160,
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade100),
        ),
        child: Column(
          children: [
            const Text(
              'Uang Diterima',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              formatCurrency(transaction.total),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _infoRow('📅 Tanggal',
                DateFormat('dd/MM/yyyy').format(transaction.createdAt)),
            _infoRow('⏰ Waktu',
                DateFormat('HH:mm:ss').format(transaction.createdAt)),
            _infoRow('👤 Kasir', transaction.kasirName ?? '-'),
            const Divider(),
            _infoRow('Subtotal', formatCurrency(transaction.total)),
            _infoRow('Dibayar', formatCurrency(transaction.payment)),
            _infoRow('Kembalian', formatCurrency(transaction.change)),
            _infoRow('Tipe Bayar', transaction.paymentType ?? 'Tunai'),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildItemList() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🛍️ Produk Terjual',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text('${items.length} item'),
            const Divider(),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final item = items[index];
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(item.productName)),
                    Text('${item.qty} x ${formatCurrency(item.price)}'),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _showWhatsAppDialog(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const FaIcon(FontAwesomeIcons.whatsapp),
                label: const Text('Kirim WA'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _generateAndOpenPdf(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Cetak PDF'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity, // Biar lebar penuh
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ReturnFormScreen(
                    products: items,
                    transactionId: transaction.id,
                    token: token,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: Colors.red),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            icon: const Icon(Icons.undo),
            label: const Text('Retur Barang'),
          ),
        ),
      ],
    );
  }

  void _showWhatsAppDialog(BuildContext context) {
    final phoneController = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Kirim ke WhatsApp'),
        content: TextField(
          controller: phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            hintText: '6281234567890',
            labelText: 'Nomor WhatsApp',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _sendWhatsApp(phoneController.text.trim());
            },
            child: const Text('Kirim'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendWhatsApp(String phoneNumber) async {
    final message = '''
🧾 *NOTA TRANSAKSI*
Kode     : ${transaction.code}
Tanggal  : ${DateFormat('dd/MM/yyyy HH:mm').format(transaction.createdAt)}
Kasir    : ${transaction.kasirName}
Total    : ${formatCurrency(transaction.total)}
Dibayar  : ${formatCurrency(transaction.payment)}
Kembalian: ${formatCurrency(transaction.change)}

📦 *Detail Barang:*
${items.map((item) => '• ${item.productName} x${item.qty} = ${formatCurrency(item.qty * item.price)}').join('\n')}
''';

    final url = Uri.parse(
      'https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}',
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      debugPrint('Tidak dapat membuka WhatsApp.');
    }
  }

  Future<void> _generateAndOpenPdf(BuildContext context) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('🧾 NOTA TRANSAKSI',
                  style: pw.TextStyle(
                      fontSize: 20, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Text('Kode     : ${transaction.code}'),
              pw.Text(
                  'Tanggal  : ${DateFormat('dd/MM/yyyy HH:mm').format(transaction.createdAt)}'),
              pw.Text('Kasir    : ${transaction.kasirName}'),
              pw.SizedBox(height: 12),
              pw.Text('📦 Barang:'),
              ...items.map((item) => pw.Text(
                  '• ${item.productName} x${item.qty} = Rp ${item.qty * item.price}')),
              pw.Divider(),
              pw.Text('Total     : Rp ${transaction.total}'),
              pw.Text('Dibayar   : Rp ${transaction.payment}'),
              pw.Text('Kembalian : Rp ${transaction.change}'),
            ],
          );
        },
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/nota_${transaction.id}.pdf');
    await file.writeAsBytes(await pdf.save());
    await OpenFile.open(file.path);
  }
}
