import 'package:dermaire_app/products/product.dart';
import 'package:dermaire_app/products/product_validation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Product sample({
    String id = '1',
    String name = 'Barrier Serum',
    String? brand = 'Derma',
  }) {
    final now = DateTime(2026, 1, 2);
    return Product(
      id: id,
      name: name,
      brand: brand,
      category: ProductCategory.serum,
      activeIngredients: const ['Niacinamide'],
      frequencyPerWeek: 4,
      timeOfUse: UsageTime.evening,
      createdAt: now,
      updatedAt: now,
    );
  }

  test('product serializes and parses without losing typed values', () {
    final product = sample();
    final parsed = Product.fromJson(product.toJson());
    expect(parsed.id, product.id);
    expect(parsed.category, ProductCategory.serum);
    expect(parsed.activeIngredients, ['Niacinamide']);
    expect(parsed.frequencyPerWeek, 4);
  });

  test('validation cleans input and enforces meaningful names', () {
    expect(ProductValidation.clean('  Barrier   Serum '), 'Barrier Serum');
    expect(ProductValidation.name('   '), isNotNull);
    expect(ProductValidation.name('aaaaaa'), isNotNull);
    expect(ProductValidation.name('Barrier Serum'), isNull);
    expect(ProductValidation.notes(' '), isNotNull);
    expect(ProductValidation.frequency(0, inRoutine: true), isNotNull);
    expect(ProductValidation.frequency(3, inRoutine: true), isNull);
  });

  test('date and duplicate rules are safe', () {
    expect(
      ProductValidation.dates(DateTime(2026, 2, 2), DateTime(2026, 1, 1)),
      isNotNull,
    );
    expect(
      ProductValidation.duplicate(sample(id: '2', name: ' barrier  serum '), [
        sample(),
      ]),
      isTrue,
    );
  });
}
