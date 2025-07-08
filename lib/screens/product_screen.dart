import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/product_model.dart';
import '../models/cart_item_model.dart';
import '../services/product_service.dart';

class ProductScreen extends StatefulWidget {
  final String token;
  final List<CartItem> cartItems;
  final void Function(ProductModel product) onAddToCart;
  final void Function() onCheckoutPressed;

  const ProductScreen({
    super.key,
    required this.token,
    required this.cartItems,
    required this.onAddToCart,
    required this.onCheckoutPressed,
  });

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  List<ProductModel> _allProduct = [];
  List<ProductModel> _filteredProduct = [];
  List<String> _categories = ['Semua'];
  String _selectedCategory = 'Semua';

  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProduct();
    _searchController.addListener(_onSearch);
  }

  Future<void> _fetchProduct() async {
    try {
      final product = await ProductService().getProducts(widget.token);
      final categoryList = [
        'Semua',
        ...{...product.map((e) => e.category)}
      ];
      setState(() {
        _allProduct = product;
        _categories = categoryList;
        _filteredProduct = _applyFilters(product);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: $e')),
      );
    }
  }

  List<ProductModel> _applyFilters(List<ProductModel> products) {
    final keyword = _searchController.text.toLowerCase();
    return products.where((product) {
      final matchName = product.name.toLowerCase().contains(keyword);
      final matchCategory =
          _selectedCategory == 'Semua' || product.category == _selectedCategory;
      return matchName && matchCategory;
    }).toList();
  }

  void _onSearch() {
    setState(() {
      _filteredProduct = _applyFilters(_allProduct);
    });
  }

  Future<void> _refreshAfterCheckout() async {
    setState(() => _isLoading = true);
    await _fetchProduct();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.cartItems
        .fold(0, (sum, item) => sum + item.product.price * item.quantity);

    return Scaffold(
      backgroundColor: const Color(0xfff8fafc),
      appBar: AppBar(
        title: const Text('📦 Daftar Produk'),
        backgroundColor: const Color(0xFFB83214),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari produk...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 36,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      final isSelected = _selectedCategory == category;

                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(category),
                          selected: isSelected,
                          onSelected: (_) {
                            setState(() {
                              _selectedCategory = category;
                              _filteredProduct = _applyFilters(_allProduct);
                            });
                          },
                          selectedColor: const Color(0xFFB83214),
                          backgroundColor: Colors.grey[200],
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _fetchProduct,
                    child: GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.7,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                      ),
                      itemCount: _filteredProduct.length,
                      itemBuilder: (context, index) {
                        final product = _filteredProduct[index];
                        final imageUrl =
                            'http://localhost:8000/storage/${product.image}';

                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                blurRadius: 8,
                                color: Colors.black12.withOpacity(0.1),
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(16)),
                                  child: CachedNetworkImage(
                                    imageUrl: imageUrl,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => const Center(
                                        child: CircularProgressIndicator()),
                                    errorWidget: (context, url, error) =>
                                        const Icon(Icons.broken_image,
                                            color: Colors.grey),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product.name,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Stok: ${product.stock}',
                                      style: const TextStyle(
                                          fontSize: 13, color: Colors.grey),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Rp ${product.price}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFB83214),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: ElevatedButton(
                                        onPressed: () =>
                                            widget.onAddToCart(product),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              const Color(0xFFB83214),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                        ),
                                        child: const Icon(Icons.add,
                                            size: 18, color: Colors.white),
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
          ),
          if (widget.cartItems.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: GestureDetector(
                onTap: () async {
                  widget.onCheckoutPressed();
                  await _refreshAfterCheckout();
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${widget.cartItems.length} item | Rp $total',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const Row(
                        children: [
                          Text(
                            'Lanjut',
                            style: TextStyle(
                                color: Color(0xFFB83214),
                                fontWeight: FontWeight.bold),
                          ),
                          SizedBox(width: 6),
                          Icon(Icons.arrow_forward_ios,
                              size: 16, color: Color(0xFFB83214)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
