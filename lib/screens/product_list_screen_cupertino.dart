import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/cached_product_provider.dart';
import '../providers/category_provider.dart';
import '../models/product.dart';
import 'product_form_screen_cupertino.dart';

class ProductListScreenCupertino extends StatefulWidget {
  final Function(int)? onScreenChange;

  const ProductListScreenCupertino({super.key, this.onScreenChange});

  @override
  State<ProductListScreenCupertino> createState() =>
      _ProductListScreenCupertinoState();
}

class _ProductListScreenCupertinoState
    extends State<ProductListScreenCupertino> {
  final currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  bool _isLoading = false;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final productProvider = Provider.of<CachedProductProvider>(
        context,
        listen: false,
      );
      await productProvider.loadAllProducts(forceRefresh: true);
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog(e.toString());
    }
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;
    showCupertinoDialog(
      context: context,
      builder:
          (ctx) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: Text(message),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () {
                  if (ctx.mounted) Navigator.pop(ctx);
                },
              ),
            ],
          ),
    );
  }

  void _showDeleteConfirmation(Product product) {
    if (!mounted) return;
    showCupertinoDialog(
      context: context,
      builder:
          (ctx) => CupertinoAlertDialog(
            title: const Text('Hapus Produk'),
            content: Text('Yakin ingin menghapus produk "${product.name}"?'),
            actions: [
              CupertinoDialogAction(
                child: const Text('Batal'),
                onPressed: () {
                  if (ctx.mounted) Navigator.pop(ctx);
                },
              ),
              CupertinoDialogAction(
                isDestructiveAction: true,
                onPressed: () async {
                  if (ctx.mounted) Navigator.pop(ctx);
                  setState(() => _isLoading = true);

                  try {
                    final productProvider = Provider.of<CachedProductProvider>(
                      context,
                      listen: false,
                    );
                    await productProvider.deleteProduct(product.id!);
                    setState(() => _isLoading = false);
                  } catch (e) {
                    setState(() => _isLoading = false);
                    _showErrorDialog('Gagal menghapus produk: ${e.toString()}');
                  }
                },
                child: const Text('Hapus'),
              ),
            ],
          ),
    );
  }

  void _editProduct(Product product) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder:
            (context) => ProductFormScreenCupertino(
              product: product,
              onScreenChange: widget.onScreenChange,
            ),
      ),
    );
  }

  void _addProduct() {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder:
            (context) => ProductFormScreenCupertino(
              onScreenChange: widget.onScreenChange,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Daftar Produk'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(CupertinoIcons.refresh),
              onPressed: _loadProducts,
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(CupertinoIcons.add),
              onPressed: _addProduct,
            ),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: CupertinoSearchTextField(
                controller: _searchController,
                placeholder: 'Cari produk...',
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
            Expanded(
              child:
                  _isLoading
                      ? const Center(child: CupertinoActivityIndicator())
                      : Consumer<CachedProductProvider>(
                        builder: (context, productProvider, child) {
                          final products = productProvider.products;

                          if (products.isEmpty) {
                            return const Center(
                              child: Text('Belum ada produk'),
                            );
                          }

                          final filteredProducts =
                              _searchQuery.isEmpty
                                  ? products
                                  : products
                                      .where(
                                        (product) =>
                                            product.name.toLowerCase().contains(
                                              _searchQuery.toLowerCase(),
                                            ),
                                      )
                                      .toList();

                          if (filteredProducts.isEmpty) {
                            return const Center(child: Text('Tidak ditemukan'));
                          }

                          return ListView.builder(
                            itemCount: filteredProducts.length,
                            itemBuilder: (context, index) {
                              final product = filteredProducts[index];
                              return _buildProductItem(
                                product,
                                context,
                                productProvider,
                              );
                            },
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductItem(
    Product product,
    BuildContext context,
    CachedProductProvider productProvider,
  ) {
    final categoryProvider = Provider.of<CategoryProvider>(
      context,
      listen: false,
    );
    final category = categoryProvider.categories.firstWhere(
      (c) => c.id == product.categoryId,
      orElse: () => categoryProvider.defaultCategory,
    );

    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        border: Border(
          bottom: BorderSide(color: CupertinoColors.systemGrey5, width: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currencyFormatter.format(product.price),
                        style: const TextStyle(
                          fontSize: 14,
                          color: CupertinoColors.activeBlue,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            'Stok: ${product.stock}',
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  product.stock > 0
                                      ? CupertinoColors.systemGrey
                                      : CupertinoColors.destructiveRed,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Kategori: ${category.name}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: CupertinoColors.systemGrey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Icon(CupertinoIcons.pencil, size: 20),
                      onPressed: () => _editProduct(product),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Icon(
                        CupertinoIcons.delete,
                        size: 20,
                        color: CupertinoColors.destructiveRed,
                      ),
                      onPressed: () => _showDeleteConfirmation(product),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
