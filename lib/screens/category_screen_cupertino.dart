import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Divider, showModalBottomSheet;
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

    showCupertinoModalPopup(
      context: context,
      builder: (context) {
        return KeyboardAdjustablePadding(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            decoration: const BoxDecoration(
              color: CupertinoColors.systemBackground,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      category == null ? 'Tambah Kategori' : 'Edit Kategori',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Icon(CupertinoIcons.xmark_circle),
                      onPressed: () {
                        Navigator.pop(context);
                        _nameController.clear();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                CupertinoTextField(
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
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: CupertinoButton(
                        padding: EdgeInsets.zero,
                        color: CupertinoColors.systemGrey6,
                        child: const Text(
                          'Batal',
                          style: TextStyle(
                            color: CupertinoColors.darkBackgroundGray,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          _nameController.clear();
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: CupertinoButton(
                        padding: EdgeInsets.zero,
                        color: const Color(0xFF1976D2),
                        child: const Text(
                          'Simpan',
                          style: TextStyle(
                            color: CupertinoColors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onPressed: () async {
                          if (_nameController.text.isNotEmpty) {
                            final categoryProvider =
                                Provider.of<CategoryProvider>(
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
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
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
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      CupertinoIcons.square_grid_2x2,
                      size: 60,
                      color: CupertinoColors.systemGrey,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Belum ada kategori',
                      style: TextStyle(
                        fontSize: 16,
                        color: CupertinoColors.systemGrey,
                      ),
                    ),
                    const SizedBox(height: 24),
                    CupertinoButton.filled(
                      onPressed: () => _showAddEditDialog(),
                      child: const Text('Tambah Kategori'),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(
                        CupertinoIcons.square_grid_2x2,
                        size: 20,
                        color: CupertinoColors.systemGrey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Total: ${categories.length} kategori',
                        style: const TextStyle(
                          fontSize: 14,
                          color: CupertinoColors.systemGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.separated(
                    itemCount: categories.length,
                    separatorBuilder:
                        (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      return Container(
                        color: CupertinoColors.systemBackground,
                        child: CupertinoListTile(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          leading: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: CupertinoColors.activeBlue.withOpacity(
                                0.1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Center(
                              child: Icon(
                                CupertinoIcons.tag_fill,
                                color: CupertinoColors.activeBlue,
                                size: 20,
                              ),
                            ),
                          ),
                          title: Text(
                            category.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CupertinoButton(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                child: const Icon(
                                  CupertinoIcons.pencil,
                                  size: 20,
                                  color: CupertinoColors.activeBlue,
                                ),
                                onPressed: () => _showAddEditDialog(category),
                              ),
                              CupertinoButton(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                child: const Icon(
                                  CupertinoIcons.delete,
                                  size: 20,
                                  color: CupertinoColors.destructiveRed,
                                ),
                                onPressed:
                                    () => _showDeleteConfirmation(category),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// Widget untuk menyesuaikan padding dengan keyboard
class KeyboardAdjustablePadding extends StatefulWidget {
  final Widget child;

  const KeyboardAdjustablePadding({super.key, required this.child});

  @override
  State<KeyboardAdjustablePadding> createState() =>
      _KeyboardAdjustablePaddingState();
}

class _KeyboardAdjustablePaddingState extends State<KeyboardAdjustablePadding> {
  @override
  Widget build(BuildContext context) {
    // Mendapatkan tinggi keyboard
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedPadding(
      padding: EdgeInsets.only(bottom: keyboardHeight > 0 ? keyboardHeight : 0),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutQuad,
      child: widget.child,
    );
  }
}
