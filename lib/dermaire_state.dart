import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'products/product_repository.dart';
import 'products/products_controller.dart';
import 'services/api_service.dart';

class Product {
  const Product(
    this.name,
    this.subtitle,
    this.icon, {
    this.inExperiment = false,
  });
  final String name;
  final String subtitle;
  final String icon;
  final bool inExperiment;
}

class JournalEntry {
  const JournalEntry(this.date, this.time, this.summary);
  final String date;
  final String time;
  final String summary;
}

class DermaireState extends ChangeNotifier {
  DermaireState({ProductRepository? productRepository}) {
    productController = ProductsController(
      productRepository ?? RemoteProductRepository(),
    )..addListener(notifyListeners);
  }

  late final ProductsController productController;
  static const _darkModeKey = 'dermaire_dark_mode';
  static const _safetyAcceptedKey = 'dermaire_safety_accepted';

  ThemeMode themeMode = ThemeMode.light;
  bool safetyAccepted = false;
  int selectedTab = 0;
  int tokens = 6;
  int baselineCheckIns = 2;
  int experimentDay = 14;
  bool experimentPaused = false;
  bool todayCheckedIn = false;
  bool doctorLinkActive = true;
  String selectedGoal = 'Reduce Acne';
  final Set<String> skinConcerns = {'Redness'};
  final List<String> redemptionHistory = [];
  final List<Product> products = [
    const Product(
      'Product X',
      'Retinol 0.3% · Evening',
      '🧴',
      inExperiment: true,
    ),
    const Product('CeraVe Moisturizer', 'Morning & evening', '💧'),
    const Product('SPF 30 Sunscreen', 'Morning', '☀️'),
  ];
  final List<JournalEntry> journal = [
    const JournalEntry(
      'Apr 22, 2025',
      'Morning',
      'Hydration: Good · Texture: Smooth',
    ),
    const JournalEntry(
      'Apr 20, 2025',
      'Evening',
      'Redness: Low · Texture: Slightly rough',
    ),
    const JournalEntry(
      'Apr 17, 2025',
      'Morning',
      'Hydration: Good · Texture: Good',
    ),
  ];

  Future<void> loadPreferences() async {
    await ApiService.instance.init();
    await productController.load();
    try {
      final preferences = await SharedPreferences.getInstance();
      themeMode = preferences.getBool(_darkModeKey) == true
          ? ThemeMode.dark
          : ThemeMode.light;
      safetyAccepted = preferences.getBool(_safetyAcceptedKey) ?? false;
      
      // Sync remote experiment if active
      final remoteExp = await ApiService.instance.getCurrentExperiment();
      if (remoteExp != null) {
        experimentDay = remoteExp['current_day'] as int? ?? experimentDay;
        experimentPaused = remoteExp['status'] == 'paused';
      }
      notifyListeners();
    } catch (_) {
      // Keep safe defaults when platform storage or network is unavailable.
    }
  }

  Future<void> toggleTheme() async {
    themeMode = themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setBool(_darkModeKey, themeMode == ThemeMode.dark);
    } catch (_) {}
  }

  Future<void> acceptSafety() async {
    safetyAccepted = true;
    notifyListeners();
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setBool(_safetyAcceptedKey, true);
    } catch (_) {}
  }

  void selectTab(int value) {
    selectedTab = value;
    notifyListeners();
  }

  void selectGoal(String value) {
    selectedGoal = value;
    notifyListeners();
  }

  void toggleConcern(String value) {
    skinConcerns.contains(value)
        ? skinConcerns.remove(value)
        : skinConcerns.add(value);
    notifyListeners();
  }

  void earnToken([String? reason]) {
    tokens++;
    notifyListeners();
  }

  void addProduct(Product product) {
    if (products.any((item) => item.name == product.name)) return;
    products.add(product);
    earnToken();
  }

  void addJournalEntry() {
    journal.insert(
      0,
      const JournalEntry(
        'Today',
        'Morning',
        'Hydration: Good · Texture: Stable',
      ),
    );
    earnToken();
  }

  void completeCheckIn() {
    if (!todayCheckedIn) {
      todayCheckedIn = true;
      baselineCheckIns = (baselineCheckIns + 1).clamp(0, 5);
      earnToken();
      // Sync with Azure Backend
      ApiService.instance.submitCheckIn(
        timeOfDay: 'Morning',
        hydration: 82.0,
        texture: 76.0,
        redness: 18.0,
        notes: 'Check-in completed from mobile skin lab',
      ).catchError((_) => <String, dynamic>{});
    }
  }

  bool redeemReward() {
    if (tokens < 10) return false;
    tokens -= 10;
    redemptionHistory.insert(0, 'Travel-size Hydrating Serum · Today');
    notifyListeners();
    // Sync redemption with Azure Backend
    ApiService.instance.redeemReward('travel_serum').catchError((_) => <String, dynamic>{});
    return true;
  }

  void togglePause() {
    experimentPaused = !experimentPaused;
    notifyListeners();
  }

  void revokeDoctorLink() {
    doctorLinkActive = false;
    notifyListeners();
    final user = ApiService.instance.currentUser;
    if (user != null && user['user_id'] != null) {
      ApiService.instance.revokeDoctorAccess(user['user_id'].toString()).catchError((_) => false);
    }
  }

  @override
  void dispose() {
    productController
      ..removeListener(notifyListeners)
      ..dispose();
    super.dispose();
  }
}
