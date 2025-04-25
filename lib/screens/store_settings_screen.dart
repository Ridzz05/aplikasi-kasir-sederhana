import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../models/store_info.dart';
import '../providers/store_info_provider.dart';
import '../widgets/custom_notification.dart';

class StoreSettingsScreen extends StatefulWidget {
  const StoreSettingsScreen({Key? key}) : super(key: key);

  @override
  _StoreSettingsScreenState createState() => _StoreSettingsScreenState();
}

class _StoreSettingsScreenState extends State<StoreSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _storeNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cashierNameController = TextEditingController();
  final _receiptFooterController = TextEditingController();
  bool _isLoading = false;
  bool _showLogo = false;
  String? _logoPath;

  @override
  void initState() {
    super.initState();
    _loadStoreInfo();
  }

  @override
  void dispose() {
    _storeNameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _cashierNameController.dispose();
    _receiptFooterController.dispose();
    super.dispose();
  }

  // Load existing store info
  void _loadStoreInfo() {
    final storeInfo =
        Provider.of<StoreInfoProvider>(context, listen: false).storeInfo;
    _storeNameController.text = storeInfo.storeName;
    _addressController.text = storeInfo.address;
    _phoneController.text = storeInfo.phone;
    _cashierNameController.text = storeInfo.cashierName;
    _receiptFooterController.text = storeInfo.receiptFooter ?? '';
    setState(() {
      _showLogo = storeInfo.showLogo;
      _logoPath = storeInfo.logoPath;
    });
  }

  // Save store info
  Future<void> _saveStoreInfo() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final storeProvider = Provider.of<StoreInfoProvider>(
        context,
        listen: false,
      );

      await storeProvider.updateStoreInfo(
        storeName: _storeNameController.text,
        address: _addressController.text,
        phone: _phoneController.text,
        cashierName: _cashierNameController.text,
        logoPath: _logoPath,
        showLogo: _showLogo,
        receiptFooter:
            _receiptFooterController.text.isNotEmpty
                ? _receiptFooterController.text
                : null,
      );

      if (mounted) {
        showCustomNotification(
          context: context,
          message: 'Informasi toko berhasil disimpan',
          type: NotificationType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        showCustomNotification(
          context: context,
          message: 'Gagal menyimpan informasi toko: ${e.toString()}',
          type: NotificationType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Pick logo image
  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _logoPath = image.path;
          _showLogo = true;
        });
      }
    } catch (e) {
      showCustomNotification(
        context: context,
        message: 'Gagal memilih gambar: ${e.toString()}',
        type: NotificationType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan Toko'),
        actions: [
          TextButton.icon(
            onPressed: _saveStoreInfo,
            icon: const Icon(Icons.save, color: Colors.white),
            label: const Text('Simpan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    // Store Logo
                    Center(
                      child: Column(
                        children: [
                          InkWell(
                            onTap: _pickImage,
                            borderRadius: BorderRadius.circular(75),
                            child: Container(
                              width: 150,
                              height: 150,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.grey.shade300,
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(75),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(75),
                                child:
                                    _logoPath != null
                                        ? Image.file(
                                          File(_logoPath!),
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (_, __, ___) => const Icon(
                                                Icons.store,
                                                size: 80,
                                                color: Colors.grey,
                                              ),
                                        )
                                        : const Icon(
                                          Icons.store,
                                          size: 80,
                                          color: Colors.grey,
                                        ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Logo Toko',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SwitchListTile(
                            title: const Text('Tampilkan Logo pada Struk'),
                            value: _showLogo,
                            onChanged:
                                _logoPath != null
                                    ? (value) {
                                      setState(() {
                                        _showLogo = value;
                                      });
                                    }
                                    : null,
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                          ),
                        ],
                      ),
                    ),

                    const Divider(height: 32),

                    // Store Name Field
                    TextFormField(
                      controller: _storeNameController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Toko',
                        hintText: 'Masukkan nama toko',
                        prefixIcon: Icon(Icons.store),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Nama toko tidak boleh kosong';
                        }
                        return null;
                      },
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 16),

                    // Address Field
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Alamat',
                        hintText: 'Masukkan alamat toko',
                        prefixIcon: Icon(Icons.location_on),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Alamat tidak boleh kosong';
                        }
                        return null;
                      },
                      maxLines: 2,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 16),

                    // Phone Field
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Nomor Telepon',
                        hintText: 'Masukkan nomor telepon',
                        prefixIcon: Icon(Icons.phone),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Nomor telepon tidak boleh kosong';
                        }
                        return null;
                      },
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),

                    // Cashier Name Field
                    TextFormField(
                      controller: _cashierNameController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Kasir Default',
                        hintText: 'Masukkan nama kasir default',
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Nama kasir tidak boleh kosong';
                        }
                        return null;
                      },
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 16),

                    // Receipt Footer Field
                    TextFormField(
                      controller: _receiptFooterController,
                      decoration: const InputDecoration(
                        labelText: 'Catatan Kaki Struk',
                        hintText: 'Masukkan catatan untuk struk (opsional)',
                        prefixIcon: Icon(Icons.receipt),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),

                    // Reset to Default Button
                    OutlinedButton.icon(
                      onPressed: () {
                        _showResetConfirmation();
                      },
                      icon: const Icon(Icons.restore),
                      label: const Text('Reset ke Pengaturan Default'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  void _showResetConfirmation() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Reset Pengaturan'),
            content: const Text(
              'Ini akan mengembalikan semua pengaturan toko ke kondisi awal. Yakin ingin melanjutkan?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  final storeProvider = Provider.of<StoreInfoProvider>(
                    context,
                    listen: false,
                  );
                  await storeProvider.resetToDefault();
                  _loadStoreInfo();

                  if (mounted) {
                    showCustomNotification(
                      context: context,
                      message: 'Pengaturan toko telah direset',
                      type: NotificationType.success,
                    );
                  }
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Reset'),
              ),
            ],
          ),
    );
  }
}
