import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../providers/category_provider.dart';
import '../models/category.dart';

class CategoryScreenCupertino extends StatefulWidget {
  final Function(int)? onScreenChange;

  const CategoryScreenCupertino({super.key, this.onScreenChange});

  @override
  State<CategoryScreenCupertino> createState() =>
      _CategoryScreenCupertinoState();
}

class _CategoryScreenCupertinoState extends State<CategoryScreenCupertino> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isLoading = false;
  Category? _editingCategory;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _showAddEditDialog([Category? category]) {
    _editingCategory = category;
    if (category != null) {
      _nameController.text = category.name;
    } else {
      _nameController.clear();
    }

    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: Text(category == null ? 'Tambah Kategori' : 'Edit Kategori'),
            content: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: CupertinoTextField(
                controller: _nameController,
                placeholder: 'Nama kategori',
                autofocus: true,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: CupertinoColors.white,
                  border: Border.all(color: CupertinoColors.systemGrey4),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            actions: [
              CupertinoDialogAction(
                isDestructiveAction: true,
                onPressed: () {
                  Navigator.pop(context);
                  _nameController.clear();
                },
                child: const Text('Batal'),
              ),
              CupertinoDialogAction(
                onPressed: () async {
                  if (_nameController.text.isNotEmpty) {
                    final categoryProvider = Provider.of<CategoryProvider>(
                      context,
                      listen: false,
                    );

                    if (_editingCategory == null) {
                      await categoryProvider.addCategory(
                        Category(name: _nameController.text),
                      );
                    } else {
                      await categoryProvider.updateCategory(
                        Category(
                          id: _editingCategory!.id,
                          name: _nameController.text,
                        ),
                      );
                    }

                    if (mounted) {
                      Navigator.pop(context);
                      _nameController.clear();
                    }
                  }
                },
                child: const Text('Simpan'),
              ),
            ],
          ),
    );
  }

  void _showDeleteConfirmation(Category category) {
    if (!mounted) return;
    showCupertinoDialog(
      context: context,
      builder:
          (ctx) => CupertinoAlertDialog(
            title: const Text('Hapus Kategori'),
            content: Text('Yakin ingin menghapus kategori "${category.name}"?'),
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
                    final categoryProvider = Provider.of<CategoryProvider>(
                      context,
                      listen: false,
                    );
                    await categoryProvider.deleteCategory(category.id!);
                    setState(() => _isLoading = false);
                  } catch (e) {
                    setState(() => _isLoading = false);
                    _showErrorDialog(
                      'Gagal menghapus kategori: ${e.toString()}',
                    );
                  }
                },
                child: const Text('Hapus'),
              ),
            ],
          ),
    );
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

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Kategori'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.add),
          onPressed: () => _showAddEditDialog(),
        ),
      ),
      child: SafeArea(
        child: Consumer<CategoryProvider>(
          builder: (context, categoryProvider, child) {
            if (_isLoading) {
              return const Center(child: CupertinoActivityIndicator());
            }

            final categories = categoryProvider.categories;
            if (categories.isEmpty) {
              return const Center(child: Text('Belum ada kategori'));
            }

            return ListView.builder(
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return Container(
                  decoration: BoxDecoration(
                    color: CupertinoColors.white,
                    border: Border(
                      bottom: BorderSide(
                        color: CupertinoColors.systemGrey5,
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: CupertinoListTile(
                    title: Text(category.name),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          child: const Icon(CupertinoIcons.pencil, size: 20),
                          onPressed: () => _showAddEditDialog(category),
                        ),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          child: const Icon(
                            CupertinoIcons.delete,
                            size: 20,
                            color: CupertinoColors.destructiveRed,
                          ),
                          onPressed: () => _showDeleteConfirmation(category),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
