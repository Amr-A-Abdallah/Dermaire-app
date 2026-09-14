import 'package:dermaire_app/app_shell.dart';
import 'package:dermaire_app/dermaire_state.dart';
import 'package:dermaire_app/dermaire_theme.dart';
import 'package:dermaire_app/products/product_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('complete product flow adds, finds and opens a product', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final state = DermaireState(productRepository: MemoryProductRepository([]));
    await state.productController.load();
    state.selectTab(2);
    await tester.pumpWidget(
      MaterialApp(
        theme: DermaireTheme.light,
        home: AppShell(state: state),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Build your routine'), findsOneWidget);
    await tester.tap(find.text('Add my first product'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enter manually'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('productName')),
      '  Barrier   Serum  ',
    );
    await tester.enterText(
      find.byKey(const Key('productIngredients')),
      'Niacinamide',
    );
    await tester.drag(find.byType(ListView).last, const Offset(0, -600));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('saveProduct')));
    await tester.pumpAndSettle();
    expect(find.text('No known conflict'), findsWidgets);
    await tester.tap(find.text('Add product'));
    await tester.pumpAndSettle();
    expect(find.text('Barrier Serum'), findsOneWidget);

    await tester.tap(find.text('Barrier Serum'));
    await tester.pumpAndSettle();
    expect(find.text('PRODUCT DETAIL'), findsOneWidget);
    expect(find.textContaining('3× weekly'), findsOneWidget);
  });

  testWidgets('products support dark mode and search empty results', (
    tester,
  ) async {
    final state = DermaireState(productRepository: MemoryProductRepository());
    await state.productController.load();
    state
      ..themeMode = ThemeMode.dark
      ..selectTab(2);
    await tester.pumpWidget(
      MaterialApp(
        theme: DermaireTheme.light,
        darkTheme: DermaireTheme.dark,
        themeMode: state.themeMode,
        home: AppShell(state: state),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.byType(AppShell))).brightness,
      Brightness.dark,
    );
    await tester.tap(find.byTooltip('Search products'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('productSearch')), r'%%%[]');
    await tester.pumpAndSettle();
    expect(find.text('No matching products'), findsOneWidget);
  });
}
