import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:lottie/lottie.dart';
import '../models/category.dart';
import '../providers/category_provider.dart';
import '../widgets/custom_notification.dart';

class CategoryScreen extends StatefulWidget {
  final Function(int)? onScreenChange;
  const CategoryScreen({Key? key, this.onScreenChange}) : super(key: key);

  @override
  _CategoryScreenState createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Selected color for the category (default blue)
  String _selectedColor = '0xFF64B5F6'; // Default color

  // Available colors for selection
  final List<ColorOption> _colorOptions = [
    ColorOption('0xFF64B5F6', 'Biru'),
    ColorOption('0xFFFFA726', 'Oranye'),
    ColorOption('0xFF66BB6A', 'Hijau'),
    ColorOption('0xFFEF5350', 'Merah'),
    ColorOption('0xFF9575CD', 'Ungu'),
    ColorOption('0xFF4DB6AC', 'Tosca'),
    ColorOption('0xFFFFEE58', 'Kuning'),
    ColorOption('0xFFFF7043', 'Jingga'),
  ];

  Category? _editingCategory;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    await Provider.of<CategoryProvider>(
      context,
      listen: false,
    ).loadCategories();
  }

  void _resetForm() {
    _nameController.clear();
    _descriptionController.clear();
    _selectedColor = '0xFF64B5F6'; // Reset to default color
    setState(() {
      _isEditing = false;
      _editingCategory = null;
    });
  }

  void _prepareEditCategory(Category category) {
    setState(() {
      _isEditing = true;
      _editingCategory = category;
      _nameController.text = category.name;
      _descriptionController.text = category.description ?? '';
      _selectedColor = category.color ?? '0xFF64B5F6';
    });
  }

  void _showAddEditCategoryDialog() {
    // Store the current color selection in a local variable
    String selectedColor = _selectedColor;

    // Use this to avoid setState on an unmounted widget
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 10,
                top: 16,
                left: 16,
                right: 16,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Handle
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 15),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      // Title
                      Center(
                        child: Text(
                          _isEditing ? 'Edit Kategori' : 'Tambah Kategori',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Name field
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nama Kategori',
                          prefixIcon: Icon(Icons.category),
                          border: OutlineInputBorder(),
                        ),
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.words,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Nama kategori tidak boleh kosong';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Description field
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Deskripsi (Opsional)',
                          prefixIcon: Icon(Icons.description),
                          border: OutlineInputBorder(),
                        ),
                        textInputAction: TextInputAction.done,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),

                      // Color selection
                      const Text(
                        'Pilih Warna:',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 50,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _colorOptions.length,
                          itemBuilder: (context, index) {
                            final colorOption = _colorOptions[index];
                            final color = int.parse(colorOption.value);
                            final isSelected =
                                selectedColor == colorOption.value;

                            return GestureDetector(
                              onTap: () {
                                selectedColor = colorOption.value;
                                setModalState(() {});
                                setState(() {
                                  _selectedColor = selectedColor;
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.only(right: 8),
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Color(color),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color:
                                        isSelected
                                            ? Colors.white
                                            : Colors.transparent,
                                    width: 2,
                                  ),
                                  boxShadow:
                                      isSelected
                                          ? [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(
                                                0.3,
                                              ),
                                              blurRadius: 4,
                                              spreadRadius: 1,
                                            ),
                                          ]
                                          : null,
                                ),
                                child:
                                    isSelected
                                        ? const Icon(
                                          Icons.check,
                                          color: Colors.white,
                                        )
                                        : null,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Action buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _resetForm();
                            },
                            child: const Text('Batal'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {
                                _selectedColor = selectedColor;
                                _saveCategory();
                                Navigator.pop(context);
                              }
                            },
                            child: Text(_isEditing ? 'Update' : 'Simpan'),
                          ),
                        ],
                      ),
                      // Add extra space at the bottom to prevent overlap with keyboard
                      SizedBox(
                        height:
                            MediaQuery.of(context).viewInsets.bottom > 0
                                ? 20
                                : 8,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    ).then((_) => setState(() {})); // Refresh state after dialog closed
  }

  Future<void> _saveCategory() async {
    final categoryProvider = Provider.of<CategoryProvider>(
      context,
      listen: false,
    );

    if (_isEditing && _editingCategory != null) {
      // Update existing category
      final updatedCategory = _editingCategory!.copyWith(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        color: _selectedColor,
      );

      final success = await categoryProvider.updateCategory(updatedCategory);

      if (success && mounted) {
        showCustomNotification(
          context: context,
          message: 'Kategori berhasil diperbarui',
          type: NotificationType.success,
        );
      } else if (mounted) {
        showCustomNotification(
          context: context,
          message: 'Gagal memperbarui kategori',
          type: NotificationType.error,
        );
      }
    } else {
      // Create new category
      final newCategory = Category(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        color: _selectedColor,
      );

      final success = await categoryProvider.addCategory(newCategory);

      if (success && mounted) {
        showCustomNotification(
          context: context,
          message: 'Kategori berhasil ditambahkan',
          type: NotificationType.success,
        );
      } else if (mounted) {
        showCustomNotification(
          context: context,
          message: 'Gagal menambahkan kategori',
          type: NotificationType.error,
        );
      }
    }

    _resetForm();
  }

  Future<void> _confirmDeleteCategory(Category category) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Konfirmasi Hapus'),
                content: Text(
                  'Yakin ingin menghapus kategori "${category.name}"?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Batal'),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Hapus'),
                  ),
                ],
              ),
        ) ??
        false;

    if (confirmed) {
      final categoryProvider = Provider.of<CategoryProvider>(
        context,
        listen: false,
      );
      final success = await categoryProvider.deleteCategory(category.id!);

      if (success && mounted) {
        showCustomNotification(
          context: context,
          message: 'Kategori berhasil dihapus',
          type: NotificationType.success,
        );
      } else if (mounted) {
        showCustomNotification(
          context: context,
          message: 'Gagal menghapus kategori',
          type: NotificationType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<CategoryProvider>(
          builder: (context, categoryProvider, child) {
            if (categoryProvider.isLoading) {
              return Center(
                child: Lottie.asset(
                  'assets/animations/loading.json',
                  width: 200,
                  height: 200,
                ),
              );
            }

            if (categoryProvider.categories.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Lottie.asset(
                      'assets/animations/empty_box.json',
                      width: 200,
                      height: 200,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Belum ada kategori',
                      style: TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        _resetForm();
                        _showAddEditCategoryDialog();
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Tambah Kategori'),
                    ),
                  ],
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Daftar Kategori',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${categoryProvider.categories.length} item',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: AnimationLimiter(
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(
                          bottom: 80,
                        ), // Space for FAB
                        itemCount: categoryProvider.categories.length,
                        itemBuilder: (context, index) {
                          final category = categoryProvider.categories[index];
                          final color =
                              category.color != null
                                  ? Color(int.parse(category.color!))
                                  : Theme.of(context).primaryColor;

                          return AnimationConfiguration.staggeredList(
                            position: index,
                            duration: const Duration(milliseconds: 375),
                            child: SlideAnimation(
                              verticalOffset: 50.0,
                              child: FadeInAnimation(
                                child: Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    leading: CircleAvatar(
                                      backgroundColor: color,
                                      child: Text(
                                        category.name
                                            .substring(0, 1)
                                            .toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      category.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle:
                                        category.description != null &&
                                                category.description!.isNotEmpty
                                            ? Text(
                                              category.description!,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            )
                                            : null,
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit),
                                          color: Colors.blue,
                                          onPressed: () {
                                            _prepareEditCategory(category);
                                            _showAddEditCategoryDialog();
                                          },
                                          tooltip: 'Edit',
                                          constraints: const BoxConstraints(),
                                          padding: const EdgeInsets.all(8),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete),
                                          color: Colors.red,
                                          onPressed:
                                              () => _confirmDeleteCategory(
                                                category,
                                              ),
                                          tooltip: 'Hapus',
                                          constraints: const BoxConstraints(),
                                          padding: const EdgeInsets.all(8),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _resetForm();
          _showAddEditCategoryDialog();
        },
        backgroundColor: Theme.of(context).primaryColor,
        tooltip: 'Tambah Kategori',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class ColorOption {
  final String value;
  final String name;

  ColorOption(this.value, this.name);
}
