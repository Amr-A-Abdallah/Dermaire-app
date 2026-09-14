import 'package:flutter/material.dart';

import '../dermaire_state.dart' hide Product;
import '../dermaire_theme.dart';
import '../dermaire_widgets.dart';
import 'product.dart';
import 'product_validation.dart';
import 'products_controller.dart';

class ProductsFeatureTab extends StatelessWidget {
  const ProductsFeatureTab({super.key, required this.state});
  final DermaireState state;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: state.productController,
    builder: (context, _) {
      final controller = state.productController;
      return SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: controller.load,
          child: CustomScrollView(
            key: const Key('productsOverview'),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Eyebrow('My products'),
                            Text(
                              'Current routine',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                          ],
                        ),
                      ),
                      IconButton.filledTonal(
                        tooltip: 'Search products',
                        onPressed: () => openPage(
                          context,
                          ProductsSearchScreen(state: state),
                        ),
                        icon: const Icon(Icons.search_rounded),
                      ),
                      const SizedBox(width: 6),
                      IconButton.filledTonal(
                        key: const Key('addProduct'),
                        tooltip: 'Add product',
                        onPressed: () => openPage(
                          context,
                          ProductAddChoiceScreen(state: state),
                        ),
                        icon: const Icon(Icons.add_rounded),
                      ),
                    ],
                  ),
                ),
              ),
              if (controller.isLoading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (controller.errorMessage != null)
                SliverFillRemaining(
                  child: _ErrorState(
                    message: controller.errorMessage!,
                    onRetry: controller.load,
                  ),
                )
              else if (controller.active.isEmpty)
                SliverFillRemaining(
                  child: _EmptyProducts(
                    onAdd: () =>
                        openPage(context, ProductAddChoiceScreen(state: state)),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 28),
                  sliver: SliverList.list(
                    children: [
                      ...controller.active.map(
                        (product) => ProductCard(
                          product: product,
                          onTap: () => openPage(
                            context,
                            ProductFeatureDetailScreen(
                              state: state,
                              productId: product.id,
                            ),
                          ),
                        ),
                      ),
                      if (controller.archived.isNotEmpty) ...[
                        const Divider(height: 30),
                        Text(
                          'INACTIVE',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: .8,
                              ),
                        ),
                        const SizedBox(height: 8),
                        ...controller.archived.map(
                          (product) => Opacity(
                            opacity: .65,
                            child: ProductCard(
                              product: product,
                              onTap: () => openPage(
                                context,
                                ProductFeatureDetailScreen(
                                  state: state,
                                  productId: product.id,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      FilledButton(
                        onPressed: () => openPage(
                          context,
                          ProductAddChoiceScreen(state: state),
                        ),
                        child: const Text('+ Add product'),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}

class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product, required this.onTap});
  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: '${product.name}, ${product.timeOfUse.label}',
    child: DermaireCard(
      onTap: onTap,
      color: product.inExperiment
          ? DermaireColors.caramel.withValues(alpha: .18)
          : null,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: DermaireColors.caramel.withValues(alpha: .22),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Text(
              product.category.icon,
              style: const TextStyle(fontSize: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  [
                    product.brand,
                    product.timeOfUse.label,
                  ].whereType<String>().join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          if (product.inExperiment)
            const StatusPill('In experiment')
          else
            const Icon(Icons.chevron_right_rounded, size: 20),
        ],
      ),
    ),
  );
}

class _EmptyProducts extends StatelessWidget {
  const _EmptyProducts({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(28),
    children: [
      const SizedBox(height: 70),
      Icon(
        Icons.spa_outlined,
        size: 64,
        color: Theme.of(context).colorScheme.primary,
      ),
      const SizedBox(height: 18),
      Text(
        'Build your routine',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: 8),
      const Text(
        'Add the products you already use. Dermaire will check interactions and keep your experiments consistent.',
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 22),
      FilledButton(onPressed: onAdd, child: const Text('Add my first product')),
    ],
  );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 54),
          const SizedBox(height: 14),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    ),
  );
}

class ProductAddChoiceScreen extends StatelessWidget {
  const ProductAddChoiceScreen({super.key, required this.state});
  final DermaireState state;

  @override
  Widget build(BuildContext context) => DermairePage(
    eyebrow: 'Add product',
    title: 'How would you like to add it?',
    children: [
      ActionCard(
        icon: '🔍',
        title: 'Search product',
        subtitle: 'Match a product from the library',
        onTap: () => openPage(context, ProductsSearchScreen(state: state)),
      ),
      ActionCard(
        icon: '📇',
        title: 'Scan product label',
        subtitle: 'Review the extracted details before saving',
        onTap: () => showDermaireSnack(
          context,
          'Label scanning needs camera permission and OCR integration.',
        ),
      ),
      ActionCard(
        icon: '✏️',
        title: 'Enter manually',
        subtitle: 'Name, ingredients and usage',
        onTap: () => openPage(context, ProductEditorScreen(state: state)),
      ),
      const Notice(
        icon: '🪙',
        text: 'Every product you add earns one reward token.',
      ),
    ],
  );
}

class ProductsSearchScreen extends StatefulWidget {
  const ProductsSearchScreen({super.key, required this.state});
  final DermaireState state;

  @override
  State<ProductsSearchScreen> createState() => _ProductsSearchScreenState();
}

class _ProductsSearchScreenState extends State<ProductsSearchScreen> {
  late final ProductsController controller = widget.state.productController;
  final search = TextEditingController();

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) => DermairePage(
      eyebrow: 'Product library',
      title: 'Search products',
      actions: [
        IconButton(
          tooltip: 'Filters',
          onPressed: () => _showFilters(context),
          icon: const Icon(Icons.tune_rounded),
        ),
      ],
      children: [
        SearchBar(
          key: const Key('productSearch'),
          controller: search,
          autoFocus: true,
          hintText: 'Name, brand or ingredient',
          leading: const Icon(Icons.search_rounded),
          trailing: [
            if (search.text.isNotEmpty)
              IconButton(
                tooltip: 'Clear search',
                onPressed: () {
                  search.clear();
                  controller.setQuery('');
                },
                icon: const Icon(Icons.close_rounded),
              ),
          ],
          onChanged: (value) {
            controller.setQuery(value);
            setState(() {});
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<ProductSort>(
          initialValue: controller.sort,
          decoration: const InputDecoration(labelText: 'Sort by'),
          items: ProductSort.values
              .map(
                (value) => DropdownMenuItem(
                  value: value,
                  child: Text(_sortLabel(value)),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) controller.setSort(value);
          },
        ),
        const SizedBox(height: 14),
        if (controller.visibleProducts.isEmpty)
          DermaireCard(
            child: Column(
              children: [
                const Icon(Icons.search_off_rounded, size: 42),
                const SizedBox(height: 8),
                const Text(
                  'No matching products',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Try another spelling or add the product manually.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => openPage(
                    context,
                    ProductEditorScreen(
                      state: widget.state,
                      initialName: ProductValidation.clean(search.text),
                    ),
                  ),
                  child: const Text('Enter manually'),
                ),
              ],
            ),
          )
        else
          ...controller.visibleProducts.map(
            (product) => ProductCard(
              product: product,
              onTap: () => openPage(
                context,
                ProductFeatureDetailScreen(
                  state: widget.state,
                  productId: product.id,
                ),
              ),
            ),
          ),
      ],
    ),
  );

  String _sortLabel(ProductSort value) => switch (value) {
    ProductSort.recentlyUpdated => 'Recently updated',
    ProductSort.name => 'Name',
    ProductSort.newest => 'Newest',
    ProductSort.rating => 'Effectiveness rating',
  };

  Future<void> _showFilters(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, setSheetState) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filter products',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('All categories'),
                    selected: controller.categoryFilter == null,
                    onSelected: (_) {
                      controller.setCategory(null);
                      setSheetState(() {});
                    },
                  ),
                  ...ProductCategory.values.map(
                    (category) => ChoiceChip(
                      label: Text(category.label),
                      selected: controller.categoryFilter == category,
                      onSelected: (_) {
                        controller.setCategory(category);
                        setSheetState(() {});
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SegmentedButton<ProductStatus?>(
                segments: const [
                  ButtonSegment(value: null, label: Text('All')),
                  ButtonSegment(
                    value: ProductStatus.active,
                    label: Text('Active'),
                  ),
                  ButtonSegment(
                    value: ProductStatus.archived,
                    label: Text('Archived'),
                  ),
                ],
                selected: {controller.statusFilter},
                onSelectionChanged: (value) {
                  controller.setStatus(value.first);
                  setSheetState(() {});
                },
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: () => Navigator.pop(sheetContext),
                child: const Text('Show results'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class ProductEditorScreen extends StatefulWidget {
  const ProductEditorScreen({
    super.key,
    required this.state,
    this.product,
    this.initialName,
  });
  final DermaireState state;
  final Product? product;
  final String? initialName;

  @override
  State<ProductEditorScreen> createState() => _ProductEditorScreenState();
}

class _ProductEditorScreenState extends State<ProductEditorScreen> {
  final formKey = GlobalKey<FormState>();
  final nameFocus = FocusNode();
  late final name = TextEditingController(
    text: widget.product?.name ?? widget.initialName,
  );
  late final brand = TextEditingController(text: widget.product?.brand);
  late final ingredients = TextEditingController(
    text: widget.product?.activeIngredients.join(', ') ?? '',
  );
  late final notes = TextEditingController(text: widget.product?.notes);
  late ProductCategory category =
      widget.product?.category ?? ProductCategory.serum;
  late UsageTime time = widget.product?.timeOfUse ?? UsageTime.evening;
  late int frequency = widget.product?.frequencyPerWeek ?? 3;
  late bool inRoutine = widget.product?.inRoutine ?? true;
  DateTime? startDate;
  bool submitted = false;

  @override
  void initState() {
    super.initState();
    startDate = widget.product?.startDate ?? DateTime.now();
  }

  @override
  void dispose() {
    name.dispose();
    brand.dispose();
    ingredients.dispose();
    notes.dispose();
    nameFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.state.productController,
    builder: (context, _) => DermairePage(
      eyebrow: widget.product == null ? 'Add product' : 'Edit product',
      title: widget.product == null
          ? 'Enter product details'
          : 'Update product',
      subtitle: 'Keep usage accurate so experiments remain comparable.',
      children: [
        Form(
          key: formKey,
          autovalidateMode: submitted
              ? AutovalidateMode.onUserInteraction
              : AutovalidateMode.disabled,
          child: Column(
            children: [
              TextFormField(
                key: const Key('productName'),
                controller: name,
                focusNode: nameFocus,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Product name *'),
                validator: ProductValidation.name,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: brand,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Brand (optional)',
                ),
                validator: ProductValidation.brand,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<ProductCategory>(
                key: const Key('productCategory'),
                initialValue: category,
                decoration: const InputDecoration(labelText: 'Category *'),
                items: ProductCategory.values
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text(value.label),
                      ),
                    )
                    .toList(),
                onChanged: (value) =>
                    setState(() => category = value ?? category),
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('productIngredients'),
                controller: ingredients,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Active ingredients',
                  hintText: 'Retinol, Niacinamide',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<UsageTime>(
                initialValue: time,
                decoration: const InputDecoration(labelText: 'Time of use *'),
                items: UsageTime.values
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text(value.label),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => time = value ?? time),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Add to current routine'),
                value: inRoutine,
                onChanged: (value) => setState(() => inRoutine = value),
              ),
              if (inRoutine) ...[
                Row(
                  children: [
                    const Expanded(child: Text('Frequency per week')),
                    IconButton(
                      tooltip: 'Decrease frequency',
                      onPressed: frequency > 1
                          ? () => setState(() => frequency--)
                          : null,
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Text('$frequency', key: const Key('productFrequency')),
                    IconButton(
                      tooltip: 'Increase frequency',
                      onPressed: frequency < 14
                          ? () => setState(() => frequency++)
                          : null,
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Start date'),
                  subtitle: Text(_dateLabel(startDate!)),
                  trailing: const Icon(Icons.calendar_month_outlined),
                  onTap: _pickDate,
                ),
              ],
              TextFormField(
                controller: notes,
                maxLength: 500,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                ),
                validator: ProductValidation.notes,
              ),
            ],
          ),
        ),
        if (widget.state.productController.isSaving)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: LinearProgressIndicator(),
          ),
        FilledButton(
          key: const Key('saveProduct'),
          onPressed: widget.state.productController.isSaving ? null : _save,
          child: Text(
            widget.product == null ? 'Review product' : 'Save changes',
          ),
        ),
      ],
    ),
  );

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: startDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (selected != null) setState(() => startDate = selected);
  }

  Future<void> _save() async {
    setState(() => submitted = true);
    if (!formKey.currentState!.validate()) {
      nameFocus.requestFocus();
      return;
    }
    final frequencyError = ProductValidation.frequency(
      frequency,
      inRoutine: inRoutine,
    );
    final dateError = ProductValidation.dates(startDate, null);
    if (frequencyError != null || dateError != null) {
      showDermaireSnack(context, frequencyError ?? dateError!);
      return;
    }
    final now = DateTime.now();
    final product = Product(
      id: widget.product?.id ?? 'product-${now.microsecondsSinceEpoch}',
      name: ProductValidation.clean(name.text),
      brand: ProductValidation.clean(brand.text).isEmpty
          ? null
          : ProductValidation.clean(brand.text),
      category: category,
      productType: category.label,
      activeIngredients: ingredients.text
          .split(',')
          .map(ProductValidation.clean)
          .where((value) => value.isNotEmpty)
          .toSet()
          .toList(),
      skinConcerns: widget.state.skinConcerns.toList(),
      usageInstructions: widget.product?.usageInstructions ?? '',
      frequencyPerWeek: frequency,
      timeOfUse: time,
      startDate: startDate,
      status: widget.product?.status ?? ProductStatus.active,
      notes: ProductValidation.clean(notes.text).isEmpty
          ? null
          : ProductValidation.clean(notes.text),
      tags: widget.product?.tags ?? const [],
      rating: widget.product?.rating,
      inRoutine: inRoutine,
      inExperiment: widget.product?.inExperiment ?? false,
      createdAt: widget.product?.createdAt ?? now,
      updatedAt: now,
    );
    if (widget.product == null) {
      if (ProductValidation.duplicate(
        product,
        widget.state.productController.all,
      )) {
        showDermaireSnack(context, 'This product is already in your routine.');
        return;
      }
      await openPage(
        context,
        ProductInteractionScreen(state: widget.state, product: product),
      );
    } else {
      final result = await widget.state.productController.update(product);
      if (!mounted) return;
      showDermaireSnack(context, result.message);
      if (result.success) Navigator.pop(context);
    }
  }

  String _dateLabel(DateTime date) => '${date.day}/${date.month}/${date.year}';
}

class ProductInteractionScreen extends StatelessWidget {
  const ProductInteractionScreen({
    super.key,
    required this.state,
    required this.product,
  });
  final DermaireState state;
  final Product product;

  @override
  Widget build(BuildContext context) {
    final risk = state.productController.interactionRisk(product);
    final (title, message, color, kind) = switch (risk) {
      InteractionRisk.safe => (
        'No known conflict',
        'No known ingredient conflict was found in the current safety rules.',
        DermaireColors.safeBackground,
        StatusKind.safe,
      ),
      InteractionRisk.conflict => (
        'Potential interaction',
        'AHA and the retinol in your active experiment may increase irritation.',
        DermaireColors.conflictBackground,
        StatusKind.conflict,
      ),
      InteractionRisk.unknown => (
        'Ingredients not verified',
        'Add active ingredients before using this product in an experiment.',
        DermaireColors.unknownBackground,
        StatusKind.warning,
      ),
    };
    return DermairePage(
      eyebrow: 'Interaction check',
      title: title,
      children: [
        DermaireCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('NEW PRODUCT', style: TextStyle(fontSize: 10)),
              Text(
                product.name,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const Divider(height: 22),
              const Text('CURRENT ROUTINE', style: TextStyle(fontSize: 10)),
              Text(
                state.productController.active
                    .map((item) => item.name)
                    .join(', '),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
        DermaireCard(
          color: color,
          borderColor: Colors.transparent,
          child: Column(
            children: [
              StatusPill(title, kind: kind),
              const SizedBox(height: 10),
              Text(message, textAlign: TextAlign.center),
            ],
          ),
        ),
        if (risk == InteractionRisk.safe)
          FilledButton(
            onPressed: () => _add(context),
            child: const Text('Add product'),
          )
        else if (risk == InteractionRisk.conflict) ...[
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: DermaireColors.conflict,
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text("Don't add"),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => _add(context, inRoutineOnly: true),
            child: const Text('Add to routine only'),
          ),
        ] else ...[
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Enter ingredients'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => _add(context, inRoutineOnly: true),
            child: const Text('Save without experiment'),
          ),
        ],
      ],
    );
  }

  Future<void> _add(BuildContext context, {bool inRoutineOnly = false}) async {
    final result = await state.productController.add(
      product.copyWith(inExperiment: false, inRoutine: true),
    );
    if (!context.mounted) return;
    showDermaireSnack(context, result.message);
    if (result.success) {
      state.earnToken();
      Navigator.of(context).popUntil((route) => route.isFirst);
      state.selectTab(2);
    }
  }
}

class ProductFeatureDetailScreen extends StatelessWidget {
  const ProductFeatureDetailScreen({
    super.key,
    required this.state,
    required this.productId,
  });
  final DermaireState state;
  final String productId;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: state.productController,
    builder: (context, _) {
      final product = state.productController.byId(productId);
      if (product == null) {
        return Scaffold(
          appBar: AppBar(),
          body: const Center(
            child: Text('This product is no longer available.'),
          ),
        );
      }
      return DermairePage(
        eyebrow: 'Product detail',
        title: product.name,
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Product actions',
            onSelected: (value) => _action(context, product, value),
            itemBuilder: (_) => [
              if (product.status == ProductStatus.archived)
                const PopupMenuItem(
                  value: 'restore',
                  child: Text('Restore product'),
                )
              else ...[
                const PopupMenuItem(value: 'edit', child: Text('Edit product')),
                const PopupMenuItem(
                  value: 'archive',
                  child: Text('Archive product'),
                ),
              ],
              const PopupMenuItem(
                value: 'delete',
                child: Text('Delete product'),
              ),
            ],
          ),
        ],
        children: [
          Container(
            height: 170,
            margin: const EdgeInsets.only(bottom: 16),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                colors: [Color(0xFFF1E1CC), DermaireColors.caramel],
              ),
            ),
            child: Text(
              product.category.icon,
              style: const TextStyle(fontSize: 58),
            ),
          ),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              StatusPill(product.status.name.toUpperCase()),
              if (product.inExperiment) const StatusPill('IN EXPERIMENT'),
              if (product.rating != null) StatusPill('★ ${product.rating}'),
            ],
          ),
          const SizedBox(height: 14),
          _DetailValue(
            'Brand & category',
            [
              product.brand,
              product.category.label,
            ].whereType<String>().join(' · '),
          ),
          _DetailValue(
            'Active ingredients',
            product.activeIngredients.isEmpty
                ? 'Not provided'
                : product.activeIngredients.join(', '),
          ),
          _DetailValue(
            'Usage',
            '${product.timeOfUse.label} · ${product.frequencyPerWeek}× weekly',
          ),
          _DetailValue(
            'Instructions',
            product.usageInstructions.isEmpty
                ? 'No instructions added'
                : product.usageInstructions,
          ),
          if (product.notes != null) _DetailValue('Notes', product.notes!),
          if (product.status != ProductStatus.archived) ...[
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Part of my routine'),
              value: product.inRoutine,
              onChanged: state.productController.isSaving
                  ? null
                  : (value) => _showResult(
                      context,
                      state.productController.setRoutine(product.id, value),
                    ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Use in current experiment'),
              subtitle: const Text('Only one active test product is allowed.'),
              value: product.inExperiment,
              onChanged: state.productController.isSaving
                  ? null
                  : (value) => _showResult(
                      context,
                      state.productController.setExperiment(product.id, value),
                    ),
            ),
          ],
        ],
      );
    },
  );

  Future<void> _action(
    BuildContext context,
    Product product,
    String value,
  ) async {
    if (value == 'edit') {
      await openPage(
        context,
        ProductEditorScreen(state: state, product: product),
      );
      return;
    }
    if (value == 'restore') {
      await _showResult(context, state.productController.restore(product.id));
      return;
    }
    if (value == 'archive') {
      final confirmed = await _confirm(
        context,
        'Archive this product?',
        product.inExperiment
            ? 'This product is being tested. End the experiment before archiving it.'
            : 'It will leave your routine but remain in your history.',
        confirm: 'Archive',
        enabled: !product.inExperiment,
      );
      if (confirmed && context.mounted) {
        final result = await state.productController.archive(product.id);
        if (!context.mounted) return;
        showDermaireSnack(context, result.message);
        if (result.success) Navigator.pop(context);
      }
      return;
    }
    final confirmed = await _confirm(
      context,
      product.inExperiment
          ? "You're changing your experiment"
          : 'Delete this product?',
      product.inExperiment
          ? 'Deleting the tested product ends the active experiment and affects result validity.'
          : 'This permanently removes the product from this device.',
      confirm: product.inExperiment ? 'End experiment & delete' : 'Delete',
    );
    if (confirmed && context.mounted) {
      final result = await state.productController.delete(
        product.id,
        endExperiment: product.inExperiment,
      );
      if (!context.mounted) return;
      showDermaireSnack(context, result.message);
      if (result.success) Navigator.pop(context);
    }
  }

  Future<bool> _confirm(
    BuildContext context,
    String title,
    String message, {
    required String confirm,
    bool enabled = true,
  }) async =>
      await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Keep product'),
            ),
            TextButton(
              onPressed: enabled
                  ? () => Navigator.pop(dialogContext, true)
                  : null,
              child: Text(
                confirm,
                style: const TextStyle(color: DermaireColors.conflict),
              ),
            ),
          ],
        ),
      ) ??
      false;

  Future<void> _showResult(
    BuildContext context,
    Future<ProductOperationResult> operation,
  ) async {
    final result = await operation;
    if (context.mounted) showDermaireSnack(context, result.message);
  }
}

class _DetailValue extends StatelessWidget {
  const _DetailValue(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => DermaireCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    ),
  );
}
