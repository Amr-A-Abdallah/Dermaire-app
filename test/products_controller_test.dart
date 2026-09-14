import 'package:dermaire_app/products/product.dart';
import 'package:dermaire_app/products/product_repository.dart';
import 'package:dermaire_app/products/products_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Product product(
    String id,
    String name, {
    ProductCategory category = ProductCategory.serum,
  }) {
    final now = DateTime(2026, 1, 1);
    return Product(
      id: id,
      name: name,
      category: category,
      activeIngredients: const ['Niacinamide'],
      frequencyPerWeek: 3,
      timeOfUse: UsageTime.evening,
      createdAt: now,
      updatedAt: now,
    );
  }

  test('loads, searches case-insensitively, filters and sorts', () async {
    final controller = ProductsController(
      MemoryProductRepository([
        product('2', 'Vitamin C', category: ProductCategory.serum),
        product('1', 'Daily Cleanser', category: ProductCategory.cleanser),
      ]),
    );
    await controller.load();
    controller.setQuery('VITAMIN');
    expect(controller.visibleProducts.single.name, 'Vitamin C');
    controller.setQuery('');
    controller.setCategory(ProductCategory.cleanser);
    expect(controller.visibleProducts.single.name, 'Daily Cleanser');
    controller.setCategory(null);
    controller.setSort(ProductSort.name);
    expect(controller.visibleProducts.first.name, 'Daily Cleanser');
  });

  test(
    'add rejects duplicates and repository errors remain recoverable',
    () async {
      final repository = MemoryProductRepository([product('1', 'Vitamin C')]);
      final controller = ProductsController(repository);
      await controller.load();
      final duplicate = await controller.add(product('2', ' vitamin c '));
      expect(duplicate.success, isFalse);
      repository.failNextOperation = true;
      final failed = await controller.add(product('3', 'Barrier Cream'));
      expect(failed.success, isFalse);
      expect(controller.errorMessage, isNotNull);
      final success = await controller.add(product('3', 'Barrier Cream'));
      expect(success.success, isTrue);
    },
  );

  test(
    'archive, restore and delete protect experiment relationships',
    () async {
      final active = product('1', 'Test Serum').copyWith(inExperiment: true);
      final controller = ProductsController(MemoryProductRepository([active]));
      await controller.load();
      expect((await controller.archive('1')).success, isFalse);
      expect((await controller.delete('1')).success, isFalse);
      expect(
        (await controller.delete('1', endExperiment: true)).success,
        isTrue,
      );

      final restorable = product(
        '2',
        'Old Cream',
      ).copyWith(status: ProductStatus.archived, inRoutine: false);
      final restoreController = ProductsController(
        MemoryProductRepository([restorable]),
      );
      await restoreController.load();
      expect((await restoreController.restore('2')).success, isTrue);
      expect(restoreController.byId('2')!.status, ProductStatus.active);
    },
  );
}
