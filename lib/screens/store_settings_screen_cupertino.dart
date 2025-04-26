import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../providers/store_info_provider.dart';

class StoreSettingsScreenCupertino extends StatefulWidget {
  final Function(int)? onScreenChange;

  const StoreSettingsScreenCupertino({super.key, this.onScreenChange});

  @override
  State<StoreSettingsScreenCupertino> createState() =>
      _StoreSettingsScreenCupertinoState();
}

class _StoreSettingsScreenCupertinoState
    extends State<StoreSettingsScreenCupertino> {
  final _storeNameController = TextEditingController();
  final _storeAddressController = TextEditingController();
  final _storePhoneController = TextEditingController();
  final _cashierNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadStoreInfo();
  }

  @override
  void dispose() {
    _storeNameController.dispose();
    _storeAddressController.dispose();
    _storePhoneController.dispose();
    _cashierNameController.dispose();
    super.dispose();
  }

  Future<void> _loadStoreInfo() async {
    final storeInfoProvider = Provider.of<StoreInfoProvider>(
      context,
      listen: false,
    );
    final storeInfo = storeInfoProvider.storeInfo;

    if (storeInfo != null) {
      _storeNameController.text = storeInfo.storeName;
      _storeAddressController.text = storeInfo.address;
      _storePhoneController.text = storeInfo.phone;
      _cashierNameController.text = storeInfo.cashierName;
    }
  }

  Future<void> _saveStoreInfo() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);

      try {
        final storeInfoProvider = Provider.of<StoreInfoProvider>(
          context,
          listen: false,
        );

        await storeInfoProvider.updateStoreInfo(
          storeName: _storeNameController.text,
          address: _storeAddressController.text,
          phone: _storePhoneController.text,
          cashierName: _cashierNameController.text,
        );

        if (mounted) {
          _showSuccessDialog();
        }
      } catch (e) {
        _showErrorDialog(e.toString());
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccessDialog() {
    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: const Text('Sukses'),
            content: const Text('Informasi toko berhasil disimpan'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
    );
  }

  void _showErrorDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: Text(message),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Pengaturan Toko'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.check_mark),
          onPressed: _saveStoreInfo,
        ),
      ),
      child: SafeArea(
        child:
            _isLoading
                ? const Center(child: CupertinoActivityIndicator())
                : Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      const Text('Nama Toko'),
                      const SizedBox(height: 8),
                      CupertinoTextField(
                        controller: _storeNameController,
                        placeholder: 'Masukkan nama toko',
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: CupertinoColors.white,
                          border: Border.all(
                            color: CupertinoColors.systemGrey4,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('Alamat'),
                      const SizedBox(height: 8),
                      CupertinoTextField(
                        controller: _storeAddressController,
                        placeholder: 'Masukkan alamat toko',
                        padding: const EdgeInsets.all(12),
                        maxLines: 3,
                        decoration: BoxDecoration(
                          color: CupertinoColors.white,
                          border: Border.all(
                            color: CupertinoColors.systemGrey4,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('Nomor Telepon'),
                      const SizedBox(height: 8),
                      CupertinoTextField(
                        controller: _storePhoneController,
                        placeholder: 'Masukkan nomor telepon',
                        keyboardType: TextInputType.phone,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: CupertinoColors.white,
                          border: Border.all(
                            color: CupertinoColors.systemGrey4,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('Nama Kasir'),
                      const SizedBox(height: 8),
                      CupertinoTextField(
                        controller: _cashierNameController,
                        placeholder: 'Masukkan nama kasir',
                        keyboardType: TextInputType.name,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: CupertinoColors.white,
                          border: Border.all(
                            color: CupertinoColors.systemGrey4,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ],
                  ),
                ),
      ),
    );
  }
}
