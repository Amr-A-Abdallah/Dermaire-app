import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';
import 'product.dart';

abstract interface class ProductRepository {
  Future<List<Product>> fetchProducts();
  Future<void> saveProducts(List<Product> products);
}

class LocalProductRepository implements ProductRepository {
  static const storageKey = 'dermaire_products_v2';

  @override
  Future<List<Product>> fetchProducts() async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = preferences.getString(storageKey);
    if (encoded == null) return seedProducts();
    final decoded = jsonDecode(encoded) as List<Object?>;
    return decoded
        .whereType<Map<String, Object?>>()
        .map(Product.fromJson)
        .toList();
  }

  @override
  Future<void> saveProducts(List<Product> products) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      storageKey,
      jsonEncode(products.map((product) => product.toJson()).toList()),
    );
  }
}

class MemoryProductRepository implements ProductRepository {
  MemoryProductRepository([List<Product>? initial])
    : _products = List.of(initial ?? seedProducts());

  List<Product> _products;
  bool failNextOperation = false;

  @override
  Future<List<Product>> fetchProducts() async {
    _throwIfNeeded();
    return List.of(_products);
  }

  @override
  Future<void> saveProducts(List<Product> products) async {
    _throwIfNeeded();
    _products = List.of(products);
  }

  void _throwIfNeeded() {
    if (!failNextOperation) return;
    failNextOperation = false;
    throw StateError('Simulated repository failure');
  }
}

List<Product> seedProducts() {
  final created = DateTime(2025, 3, 1);
  return [
    Product(
      id: 'product-x',
      name: 'Product X',
      brand: 'Derma Lab',
      category: ProductCategory.treatment,
      productType: 'Retinol treatment',
      activeIngredients: const ['Retinol 0.3%', 'Squalane', 'Niacinamide'],
      skinConcerns: const ['Texture', 'Acne'],
      usageInstructions: 'Apply a pea-sized amount after cleansing.',
      frequencyPerWeek: 3,
      timeOfUse: UsageTime.evening,
      startDate: DateTime(2025, 4, 9),
      notes: 'Increase slowly if skin remains comfortable.',
      tags: const ['active', 'night'],
      rating: 4.2,
      inExperiment: true,
      createdAt: created,
      updatedAt: DateTime(2025, 4, 9),
    ),
    Product(
      id: 'cerave-moisturizer',
      name: 'CeraVe Moisturizer',
      brand: 'CeraVe',
      category: ProductCategory.moisturizer,
      productType: 'Barrier moisturizer',
      activeIngredients: const ['Ceramides', 'Hyaluronic acid'],
      skinConcerns: const ['Dryness'],
      usageInstructions: 'Apply after serum.',
      frequencyPerWeek: 14,
      timeOfUse: UsageTime.both,
      startDate: DateTime(2025, 3, 1),
      rating: 4.7,
      createdAt: created,
      updatedAt: created,
    ),
    Product(
      id: 'spf-30',
      name: 'SPF 30 Sunscreen',
      category: ProductCategory.sunscreen,
      productType: 'Broad spectrum sunscreen',
      activeIngredients: const ['Zinc oxide'],
      usageInstructions: 'Apply as the final morning step and reapply.',
      frequencyPerWeek: 7,
      timeOfUse: UsageTime.morning,
      startDate: DateTime(2025, 3, 1),
      rating: 4.5,
      createdAt: created,
      updatedAt: created,
    ),
    Product(
      id: 'salicylic-cleanser',
      name: 'Salicylic Acid Cleanser',
      category: ProductCategory.cleanser,
      activeIngredients: const ['Salicylic acid'],
      usageInstructions: 'Massage onto damp skin and rinse.',
      frequencyPerWeek: 4,
      timeOfUse: UsageTime.evening,
      status: ProductStatus.archived,
      inRoutine: false,
      endDate: DateTime(2025, 3, 25),
      createdAt: created,
      updatedAt: DateTime(2025, 3, 25),
    ),
  ];
}

class RemoteProductRepository implements ProductRepository {
  RemoteProductRepository({LocalProductRepository? localFallback})
      : _local = localFallback ?? LocalProductRepository();

  final LocalProductRepository _local;

  @override
  Future<List<Product>> fetchProducts() async {
    try {
      final remoteList = await ApiService.instance.getProducts();
      if (remoteList.isNotEmpty) {
        final products = remoteList.map(Product.fromJson).toList();
        await _local.saveProducts(products);
        return products;
      }
    } catch (_) {
      // Fallback to local cache when server is unreachable or offline
    }
    return _local.fetchProducts();
  }

  @override
  Future<void> saveProducts(List<Product> products) async {
    await _local.saveProducts(products);
  }
}

