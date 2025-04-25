import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/store_info.dart';

class StoreInfoProvider with ChangeNotifier {
  static const String _prefKey = 'store_info';
  StoreInfo _storeInfo = StoreInfo.defaultInfo();

  StoreInfo get storeInfo => _storeInfo;

  // Initialize provider with stored data
  Future<void> initializeStoreInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedInfo = prefs.getString(_prefKey);

      if (storedInfo != null) {
        _storeInfo = StoreInfo.fromJson(storedInfo);
      } else {
        // If no stored info, use default
        _storeInfo = StoreInfo.defaultInfo();
        // Save default info
        await saveStoreInfo(_storeInfo);
      }

      notifyListeners();
    } catch (e) {
      print('Error initializing store info: $e');
      // In case of error, use default info
      _storeInfo = StoreInfo.defaultInfo();
      notifyListeners();
    }
  }

  // Update store information
  Future<void> updateStoreInfo({
    String? storeName,
    String? address,
    String? phone,
    String? cashierName,
    String? logoPath,
    bool? showLogo,
    String? receiptFooter,
  }) async {
    _storeInfo = _storeInfo.copyWith(
      storeName: storeName,
      address: address,
      phone: phone,
      cashierName: cashierName,
      logoPath: logoPath,
      showLogo: showLogo,
      receiptFooter: receiptFooter,
    );

    await saveStoreInfo(_storeInfo);
    notifyListeners();
  }

  // Save store info to persistent storage
  Future<void> saveStoreInfo(StoreInfo storeInfo) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, storeInfo.toJson());
    } catch (e) {
      print('Error saving store info: $e');
    }
  }

  // Reset to default store info
  Future<void> resetToDefault() async {
    _storeInfo = StoreInfo.defaultInfo();
    await saveStoreInfo(_storeInfo);
    notifyListeners();
  }
}
