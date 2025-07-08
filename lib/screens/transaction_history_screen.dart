import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../services/transaction_service.dart';
import 'transaction_detail_screen.dart';

class TransactionHistoryScreen extends StatefulWidget {
  final String token;
  const TransactionHistoryScreen({super.key, required this.token});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  List<TransactionModel> _transactions = [];
  List<TransactionModel> _filteredTransactions = [];
  bool _isLoading = true;
  DateTimeRange? _selectedRange;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  Future<void> _fetchTransactions() async {
    try {
      final trx =
          await TransactionService().getTransactions(token: widget.token);
      final today = DateTime.now();

      List<TransactionModel> filteredByDate;

      if (_selectedRange != null) {
        filteredByDate = trx.where((t) {
          return t.createdAt.isAfter(
                  _selectedRange!.start.subtract(const Duration(days: 1))) &&
              t.createdAt
                  .isBefore(_selectedRange!.end.add(const Duration(days: 1)));
        }).toList();
      } else {
        filteredByDate = trx.where((t) {
          return t.createdAt.year == today.year &&
              t.createdAt.month == today.month &&
              t.createdAt.day == today.day;
        }).toList();
      }

      filteredByDate.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      setState(() {
        _transactions = filteredByDate;
        _applySearch();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat transaksi: $e')),
      );
    }
  }

  String generateTransactionCode(TransactionModel trx, int index) {
    final dateStr = DateFormat('yyyyMMdd').format(trx.createdAt);
    final Map<String, int> countMap = {};
    int count = 1;

    for (int i = 0; i <= index; i++) {
      final t = _transactions[i];
      final key = DateFormat('yyyyMMdd').format(t.createdAt);
      countMap[key] = (countMap[key] ?? 0) + 1;
      if (i == index) {
        count = countMap[key]!;
      }
    }

    return '$dateStr${count.toString().padLeft(4, '0')}';
  }

  void _applySearch() {
    _filteredTransactions = _transactions
        .asMap()
        .entries
        .where((entry) {
          final index = entry.key;
          final trx = entry.value;
          final code = generateTransactionCode(trx, index);
          final query = _searchQuery.toLowerCase();

          final matchProduct = trx.items
              .any((item) => item.productName.toLowerCase().contains(query));
          final matchCode = code.toLowerCase().contains(query);

          return matchProduct || matchCode;
        })
        .map((e) => e.value)
        .toList();
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: _selectedRange,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('id', 'ID'),
    );

    if (picked != null) {
      setState(() => _selectedRange = picked);
      _fetchTransactions();
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalItems = _filteredTransactions.fold<int>(
        0, (sum, t) => sum + t.items.fold(0, (s, i) => s + i.qty));
    final totalHarga =
        _filteredTransactions.fold<int>(0, (sum, t) => sum + t.total);

    return Scaffold(
      backgroundColor: const Color(0xfff8fafc),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '📜 Riwayat Transaksi',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFB91C1C),
                ),
              ),
              const SizedBox(height: 12),

              // Filter box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _selectedRange == null
                              ? DateFormat('dd/MM/yyyy').format(DateTime.now())
                              : '${DateFormat('dd/MM/yyyy').format(_selectedRange!.start)} - ${DateFormat('dd/MM/yyyy').format(_selectedRange!.end)}',
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                        InkWell(
                          onTap: _selectDateRange,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.filter_alt,
                                color: Color(0xFFB91C1C)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text('Jumlah Produk Terjual',
                        style: TextStyle(color: Colors.black54)),
                    Text(
                      '$totalItems',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFB91C1C),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('Total Harga',
                        style: TextStyle(color: Colors.black54)),
                    Text(
                      'Rp ${NumberFormat("#,##0", "id_ID").format(totalHarga)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFB91C1C),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                decoration: InputDecoration(
                  hintText: 'Cari produk atau kode transaksi',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                    _applySearch();
                  });
                },
              ),
              const SizedBox(height: 16),

              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredTransactions.isEmpty
                        ? const Center(child: Text('Belum ada transaksi.'))
                        : ListView.builder(
                            itemCount: _filteredTransactions.length,
                            itemBuilder: (context, index) {
                              final trx = _filteredTransactions[index];
                              final kode = generateTransactionCode(
                                  trx,
                                  _transactions.indexOf(
                                      trx)); // Perhitungan tetap stabil

                              return Container(
                                margin: const EdgeInsets.only(bottom: 14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12.withOpacity(0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(16),
                                  leading: CircleAvatar(
                                    backgroundColor: const Color(0xFFB91C1C)
                                        .withOpacity(0.1),
                                    child: const Icon(Icons.receipt_long,
                                        color: Color(0xFFB91C1C)),
                                  ),
                                  title: Text(
                                    'Kode: $kode',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: Color(0xFFB91C1C),
                                    ),
                                  ),
                                  subtitle: Text(
                                    'Total: Rp ${trx.total}\n${DateFormat('EEEE, d MMMM y • HH:mm', 'id_ID').format(trx.createdAt)}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey,
                                      height: 1.4,
                                    ),
                                  ),
                                  isThreeLine: true,
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => TransactionDetailScreen(
                                          transaction: trx,
                                          token: widget.token,
                                          items: trx.items,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
