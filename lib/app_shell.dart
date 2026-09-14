import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'chatbot.dart';
import 'dermaire_state.dart';
import 'dermaire_theme.dart';
import 'dermaire_widgets.dart';
import 'products/products_ui.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.state});
  final DermaireState state;

  static const labels = [
    'Home',
    'Experiment',
    'Products',
    'Rewards',
    'Reports',
    'Profile',
  ];
  static const icons = [
    Icons.home_rounded,
    Icons.science_rounded,
    Icons.spa_rounded,
    Icons.redeem_rounded,
    Icons.analytics_rounded,
    Icons.person_rounded,
  ];

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: state,
    builder: (context, _) {
      final pages = [
        HomeTab(state: state),
        ExperimentTab(state: state),
        ProductsFeatureTab(state: state),
        RewardsTab(state: state),
        ReportsTab(state: state),
        ProfileTab(state: state),
      ];
      return Scaffold(
        body: IndexedStack(index: state.selectedTab, children: pages),
        floatingActionButton: FloatingActionButton.small(
          tooltip: 'Open Dermaire guide',
          onPressed: () => openPage(context, const SkinAssistantScreen()),
          child: const Icon(Icons.chat_bubble_outline_rounded),
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: state.selectedTab,
          onTap: state.selectTab,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Theme.of(context).colorScheme.surface,
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: Theme.of(
            context,
          ).colorScheme.onSurface.withValues(alpha: .38),
          selectedFontSize: 9.5,
          unselectedFontSize: 9,
          selectedLabelStyle: const TextStyle(
            fontFamily: 'Karla',
            fontWeight: FontWeight.w700,
          ),
          unselectedLabelStyle: const TextStyle(fontFamily: 'Karla'),
          items: List.generate(
            labels.length,
            (index) => BottomNavigationBarItem(
              icon: Icon(icons[index], size: 21),
              label: labels[index],
            ),
          ),
        ),
      );
    },
  );
}

class _TabPage extends StatelessWidget {
  const _TabPage({required this.children, this.header});
  final List<Widget> children;
  final Widget? header;

  @override
  Widget build(BuildContext context) => SafeArea(
    bottom: false,
    child: ListView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
      children: [?header, ...children],
    ),
  );
}

class HomeTab extends StatelessWidget {
  const HomeTab({super.key, required this.state});
  final DermaireState state;

  @override
  Widget build(BuildContext context) => _TabPage(
    header: Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Good morning, Salma 🌿',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
          ),
          Text(
            'Tue, Apr 22',
            style: TextStyle(
              fontSize: 11,
              color: DermaireColors.ink.withValues(alpha: .55),
            ),
          ),
        ],
      ),
    ),
    children: [
      Text(
        'Day ${state.experimentDay} of 28',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: 6),
      Text(
        'Testing: ${state.productController.active.where((product) => product.inExperiment).firstOrNull?.name ?? 'No active product'} for texture',
        style: TextStyle(
          fontSize: 13.5,
          color: DermaireColors.ink.withValues(alpha: .75),
        ),
      ),
      const SizedBox(height: 13),
      ClipRRect(
        borderRadius: BorderRadius.circular(99),
        child: LinearProgressIndicator(
          value: state.experimentDay / 28,
          minHeight: 6,
          color: DermaireColors.deep,
          backgroundColor: DermaireColors.line,
        ),
      ),
      const SizedBox(height: 16),
      const Row(
        children: [
          Expanded(child: MetricTile('↓ 8%', 'Redness vs baseline')),
          SizedBox(width: 10),
          Expanded(child: MetricTile('↓ 12%', 'Texture vs baseline')),
        ],
      ),
      const SizedBox(height: 14),
      DermaireCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        state.todayCheckedIn
                            ? "✓ Today's check-in"
                            : "🟢 Today's check-in",
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        state.todayCheckedIn
                            ? 'Completed'
                            : 'Not yet completed',
                        style: const TextStyle(fontSize: 11.5),
                      ),
                    ],
                  ),
                ),
                if (state.todayCheckedIn) const StatusPill('Done'),
              ],
            ),
            if (!state.todayCheckedIn) ...[
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => openPage(context, CameraScreen(state: state)),
                child: const Text('Check in now'),
              ),
            ],
          ],
        ),
      ),
      const Notice(
        icon: '🌤',
        text:
            'Weather today is within your normal range — no adjustment needed.',
      ),
      OutlinedButton(
        onPressed: () => openPage(context, TimelineScreen(state: state)),
        child: const Text('View experiment timeline'),
      ),
      const SizedBox(height: 18),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Latest journal entries',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontSize: 16),
          ),
          TextButton(
            onPressed: () => state.selectTab(2),
            child: const Text('View products'),
          ),
        ],
      ),
      ...state.journal
          .take(2)
          .map(
            (entry) => DermaireCard(
              color: DermaireColors.card,
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEAD3BC), Color(0xFFC9A47E)],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${entry.date} · ${entry.time}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          entry.summary,
                          style: const TextStyle(fontSize: 11.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
    ],
  );
}

class ExperimentTab extends StatefulWidget {
  const ExperimentTab({super.key, required this.state});
  final DermaireState state;

  @override
  State<ExperimentTab> createState() => _ExperimentTabState();
}

class _ExperimentTabState extends State<ExperimentTab> {
  int step = 0;
  static const goals = [
    ('🔥', 'Reduce Acne'),
    ('💧', 'Improve Hydration'),
    ('✨', 'Even Skin Tone'),
    ('🌸', 'Reduce Redness'),
    ('⚪', 'Minimize Pores'),
  ];

  @override
  Widget build(BuildContext context) {
    if (step == 0) return _goalStep(context);
    if (step == 1) return _reviewStep(context);
    if (step == 2) return _safetyStep(context);
    return _baselineStep(context);
  }

  Widget _goalStep(BuildContext context) => _TabPage(
    children: [
      const Eyebrow('New experiment'),
      Text(
        'Choose your goal',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: 6),
      const Text('What would you like to focus on?'),
      const SizedBox(height: 16),
      ...goals.map((goal) {
        final selected = widget.state.selectedGoal == goal.$2;
        return DermaireCard(
          color: selected ? DermaireColors.paper : DermaireColors.card,
          borderColor: selected ? DermaireColors.deep : DermaireColors.line,
          onTap: () => widget.state.selectGoal(goal.$2),
          child: Row(
            children: [
              Text(goal.$1),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  goal.$2,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? DermaireColors.deep : DermaireColors.caramel,
              ),
            ],
          ),
        );
      }),
      FilledButton(
        onPressed: () => setState(() => step = 1),
        child: const Text('Next'),
      ),
    ],
  );

  Widget _reviewStep(BuildContext context) => _TabPage(
    children: [
      const Eyebrow('New experiment'),
      Text(
        'What do you want to test?',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: 16),
      _LabeledValue(
        'Question',
        'Does ${widget.state.productController.active.where((product) => product.inExperiment).firstOrNull?.name ?? 'this product'} improve my skin texture?',
      ),
      _LabeledValue(
        'Variable',
        widget.state.productController.active
                .where((product) => product.inExperiment)
                .firstOrNull
                ?.name ??
            'Choose a product',
      ),
      const _LabeledValue('Target measurement', 'Texture'),
      const Row(
        children: [
          Expanded(child: MetricTile('Apr 22', 'Start date')),
          SizedBox(width: 10),
          Expanded(child: MetricTile('28 days', 'Duration')),
        ],
      ),
      const SizedBox(height: 14),
      FilledButton(
        onPressed: () => setState(() => step = 2),
        child: const Text('Review'),
      ),
      const SizedBox(height: 8),
      OutlinedButton(
        onPressed: () => setState(() => step = 0),
        child: const Text('Back'),
      ),
    ],
  );

  Widget _safetyStep(BuildContext context) => _TabPage(
    children: [
      const Eyebrow('Ready to begin?'),
      Text(
        'Experiment safety check',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: 16),
      _LabeledValue(
        'Test',
        '${widget.state.productController.active.where((product) => product.inExperiment).firstOrNull?.name ?? 'Choose a product'} · Texture · 28 days',
      ),
      const DermaireCard(
        color: DermaireColors.safeBackground,
        borderColor: Colors.transparent,
        child: Column(
          children: [
            StatusPill('🟢 GO'),
            SizedBox(height: 8),
            Text('Your experiment can begin.', style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
      FilledButton(
        onPressed: () => setState(() => step = 3),
        child: const Text('Begin baseline'),
      ),
      const SizedBox(height: 14),
      const Notice(
        icon: 'ⓘ',
        text:
            'If an interaction check flags a conflict or unstable conditions, Dermaire blocks the experiment and explains the next step.',
      ),
    ],
  );

  Widget _baselineStep(BuildContext context) => _TabPage(
    children: [
      const Eyebrow('Baseline period'),
      Text(
        'Establishing your baseline',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: 6),
      const Text(
        "We're learning what your skin looks like before the experiment begins.",
      ),
      const SizedBox(height: 16),
      DermaireCard(
        child: Column(
          children: [
            const Text('Day', style: TextStyle(fontSize: 13)),
            Text(
              '${widget.state.baselineCheckIns} of 5',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: widget.state.baselineCheckIns / 5,
              minHeight: 6,
              color: DermaireColors.deep,
              backgroundColor: DermaireColors.line,
            ),
          ],
        ),
      ),
      Row(
        children: [
          Expanded(
            child: MetricTile(
              '${widget.state.baselineCheckIns}',
              'Check-ins completed',
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(child: MetricTile('96%', 'Consistency score')),
        ],
      ),
      const SizedBox(height: 14),
      FilledButton(
        onPressed: () => openPage(context, CameraScreen(state: widget.state)),
        child: const Text("Take today's check-in"),
      ),
      const SizedBox(height: 8),
      OutlinedButton(
        onPressed: widget.state.togglePause,
        child: Text(
          widget.state.experimentPaused
              ? 'Resume experiment'
              : 'Pause experiment',
        ),
      ),
    ],
  );
}

class _LabeledValue extends StatelessWidget {
  const _LabeledValue(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => DermaireCard(
    color: DermaireColors.card,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            color: DermaireColors.ink.withValues(alpha: .6),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
        ),
      ],
    ),
  );
}

class ProductsTab extends StatelessWidget {
  const ProductsTab({super.key, required this.state});
  final DermaireState state;

  @override
  Widget build(BuildContext context) => _TabPage(
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Eyebrow('My products'),
              Text(
                'Current routine',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ],
          ),
          IconButton.filledTonal(
            onPressed: () => openPage(context, AddProductScreen(state: state)),
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      const SizedBox(height: 16),
      ...state.products.map(
        (product) => DermaireCard(
          color: product.inExperiment
              ? DermaireColors.paper
              : DermaireColors.card,
          onTap: () => openPage(context, ProductDetailScreen(product: product)),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: DermaireColors.paper,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Text(product.icon, style: const TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                      ),
                    ),
                    Text(
                      product.subtitle,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: DermaireColors.ink.withValues(alpha: .6),
                      ),
                    ),
                  ],
                ),
              ),
              if (product.inExperiment) const StatusPill('In experiment'),
            ],
          ),
        ),
      ),
      const Divider(height: 28),
      Text(
        'Inactive',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: DermaireColors.ink.withValues(alpha: .55),
        ),
      ),
      const SizedBox(height: 8),
      const Opacity(
        opacity: .6,
        child: DermaireCard(
          color: DermaireColors.card,
          child: _ProductSummary(
            'Salicylic Acid Cleanser',
            'Removed Mar 2025',
            '🧼',
          ),
        ),
      ),
      FilledButton(
        onPressed: () => openPage(context, AddProductScreen(state: state)),
        child: const Text('+ Add product'),
      ),
    ],
  );
}

class _ProductSummary extends StatelessWidget {
  const _ProductSummary(this.title, this.subtitle, this.icon);
  final String title;
  final String subtitle;
  final String icon;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(icon, style: const TextStyle(fontSize: 20)),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            Text(subtitle, style: const TextStyle(fontSize: 11.5)),
          ],
        ),
      ),
    ],
  );
}

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key, required this.state});
  final DermaireState state;

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final search = TextEditingController();
  String? query;

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results =
        const [
              Product('Vitamin C Brightening Drops', 'Serum · ★ 4.4', '🍊'),
              Product('Hydrating Toner Mist', 'Toner · ★ 4.3', '💦'),
              Product('AHA Exfoliant', 'Treatment · interaction warning', '🧪'),
              Product(
                'Custom Botanical Serum',
                'Ingredients unavailable',
                '🌿',
              ),
            ]
            .where(
              (item) =>
                  query == null ||
                  item.name.toLowerCase().contains(query!.toLowerCase()),
            )
            .toList();
    return DermairePage(
      eyebrow: 'Add product',
      title: 'How would you like to add it?',
      children: [
        TextField(
          controller: search,
          onChanged: (value) => setState(
            () => query = value.trim().isEmpty ? null : value.trim(),
          ),
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'Search product…',
          ),
        ),
        const SizedBox(height: 14),
        ...results.map(
          (product) => ActionCard(
            icon: product.icon,
            title: product.name,
            subtitle: product.subtitle,
            onTap: () {
              final kind = product.name.startsWith('AHA')
                  ? InteractionKind.conflict
                  : product.name.startsWith('Custom')
                  ? InteractionKind.unknown
                  : InteractionKind.safe;
              openPage(
                context,
                InteractionScreen(
                  state: widget.state,
                  product: product,
                  kind: kind,
                ),
              );
            },
          ),
        ),
        const Divider(height: 30),
        const ActionCard(
          icon: '📇',
          title: 'Scan product label',
          subtitle: 'OCR label scan · coming soon',
          enabled: false,
        ),
        ActionCard(
          icon: '✏️',
          title: 'Enter manually',
          subtitle: 'Name + active ingredients',
          onTap: () => showDermaireSnack(
            context,
            'Manual product form is ready for connection to your API',
          ),
        ),
        const Notice(
          icon: '🪙',
          text: 'Every product you add earns one reward token.',
        ),
      ],
    );
  }
}

enum InteractionKind { safe, conflict, unknown }

class InteractionScreen extends StatelessWidget {
  const InteractionScreen({
    super.key,
    required this.state,
    required this.product,
    required this.kind,
  });
  final DermaireState state;
  final Product product;
  final InteractionKind kind;

  @override
  Widget build(BuildContext context) {
    final safe = kind == InteractionKind.safe;
    final conflict = kind == InteractionKind.conflict;
    final title = safe
        ? 'Add product'
        : conflict
        ? 'Interaction detected'
        : "We couldn't verify this product";
    final message = safe
        ? 'No known ingredient conflict was found in our current rules.'
        : conflict
        ? 'Retinol and AHA are listed as a known conflict in our interaction rules.'
        : "We don't currently have enough ingredient information to complete the interaction check.";
    final color = safe
        ? DermaireColors.safeBackground
        : conflict
        ? DermaireColors.conflictBackground
        : DermaireColors.unknownBackground;
    return DermairePage(
      eyebrow: 'Interaction check',
      title: title,
      children: [
        DermaireCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('New product', style: TextStyle(fontSize: 11.5)),
              Text(
                product.name,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const Divider(height: 22),
              const Text('Current products', style: TextStyle(fontSize: 11.5)),
              const Text(
                'Product X, CeraVe Moisturizer, SPF 30',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
        DermaireCard(
          color: color,
          borderColor: Colors.transparent,
          child: Column(
            children: [
              StatusPill(
                safe
                    ? '🟢 No known conflict'
                    : conflict
                    ? '🔴 Potential conflict'
                    : '🟡 Not in our database',
                kind: safe
                    ? StatusKind.safe
                    : conflict
                    ? StatusKind.conflict
                    : StatusKind.warning,
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
        if (safe)
          FilledButton(
            onPressed: () {
              state.addProduct(product);
              Navigator.of(context).popUntil((route) => route.isFirst);
              state.selectTab(2);
            },
            child: const Text('Add product'),
          )
        else if (conflict) ...[
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: DermaireColors.conflict,
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text("Don't add"),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Review products'),
          ),
          const SizedBox(height: 14),
          const Notice(
            icon: 'ⓘ',
            text: "This is a safety gate. It can't be silently bypassed.",
            color: DermaireColors.conflictBackground,
          ),
        ] else ...[
          FilledButton(
            onPressed: () =>
                showDermaireSnack(context, 'Ingredient editor opened'),
            child: const Text('Enter ingredients manually'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Try another product'),
          ),
        ],
      ],
    );
  }
}

class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({super.key, required this.product});
  final Product product;

  @override
  Widget build(BuildContext context) => DermairePage(
    eyebrow: 'Product detail',
    title: product.name,
    children: [
      Container(
        height: 190,
        margin: const EdgeInsets.only(bottom: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFFF1E1CC), DermaireColors.caramel],
          ),
        ),
        child: Text(product.icon, style: const TextStyle(fontSize: 56)),
      ),
      const _LabeledValue(
        'Active ingredients',
        'Retinol 0.3%, Squalane, Niacinamide',
      ),
      const _LabeledValue('Usage', 'Evening'),
      const _LabeledValue(
        'Used in',
        'Texture Experiment — Day 14 of 28, active',
      ),
      OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: DermaireColors.conflict,
          side: const BorderSide(color: DermaireColors.conflict),
        ),
        onPressed: () => _showRemoveDialog(context),
        child: const Text('Remove product'),
      ),
    ],
  );

  void _showRemoveDialog(BuildContext context) => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: DermaireColors.card,
      title: const Text("You're changing your experiment"),
      content: const Text(
        'This product is the variable currently being tested. Removing it will affect the validity of your experiment.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Keep product'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'End experiment',
            style: TextStyle(color: DermaireColors.conflict),
          ),
        ),
      ],
    ),
  );
}

class RewardsTab extends StatelessWidget {
  const RewardsTab({super.key, required this.state});
  final DermaireState state;

  @override
  Widget build(BuildContext context) => _TabPage(
    children: [
      const Eyebrow('Rewards'),
      Text('Token rewards', style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [DermaireColors.caramel, DermaireColors.deep],
          ),
        ),
        child: Column(
          children: [
            const Text('🌿  🪙', style: TextStyle(fontSize: 28)),
            const SizedBox(height: 8),
            Text(
              '${state.tokens} tokens',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 6),
            const Text(
              'Every product you add to your routine earns tokens toward a free skincare product.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
            const SizedBox(height: 14),
            LinearProgressIndicator(
              value: math.min(1, state.tokens / 10),
              minHeight: 7,
              color: Colors.white,
              backgroundColor: Colors.white24,
            ),
            const SizedBox(height: 6),
            Text(
              '${state.tokens} / 10 tokens to your next free product',
              style: const TextStyle(color: Colors.white70, fontSize: 10.5),
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      FilledButton(
        onPressed: state.tokens >= 10 ? () => _redeem(context) : null,
        child: Text(
          state.tokens >= 10
              ? '🎁 Redeem your free serum'
              : 'Keep adding products to unlock a reward',
        ),
      ),
      const Divider(height: 34),
      Text(
        'How you earn tokens',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16),
      ),
      const SizedBox(height: 10),
      const ActionCard(
        icon: '+1',
        title: 'Add a product to your routine',
        subtitle: 'From search, all products, or a custom entry',
      ),
      const ActionCard(
        icon: '+1',
        title: 'Log a new journal entry',
        subtitle: 'Daily check-ins keep your streak going',
      ),
      const ActionCard(
        icon: '+1',
        title: 'Complete a daily check-in',
        subtitle: 'Consistent measurements improve your report',
      ),
      Text(
        'Reward tiers',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16),
      ),
      const SizedBox(height: 10),
      const _RewardTier('🧴', 'Travel-size Hydrating Serum', r'$12 value'),
      const _RewardTier('🧼', 'Full-size Gentle Cleanser', r'$18 value'),
      const _RewardTier('☀️', 'SPF 30 Mineral Sunscreen', r'$22 value'),
      const _RewardTier('🎁', 'Complete Hydration Bundle', r'$45 value'),
      if (state.redemptionHistory.isNotEmpty) ...[
        Text(
          'Redemption history',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16),
        ),
        const SizedBox(height: 10),
        ...state.redemptionHistory.map(
          (item) => DermaireCard(color: DermaireColors.card, child: Text(item)),
        ),
      ],
    ],
  );

  void _redeem(BuildContext context) {
    if (!state.redeemReward()) return;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: DermaireColors.card,
        icon: const Text('🧴', style: TextStyle(fontSize: 42)),
        title: const Text("You've earned a free product!"),
        content: const Text(
          'Your Travel-size Hydrating Serum has been added to your redemption history.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Great!'),
          ),
        ],
      ),
    );
  }
}

class _RewardTier extends StatelessWidget {
  const _RewardTier(this.icon, this.name, this.value);
  final String icon;
  final String name;
  final String value;

  @override
  Widget build(BuildContext context) => DermaireCard(
    color: DermaireColors.card,
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    child: Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 22)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 11,
            color: DermaireColors.ink.withValues(alpha: .6),
          ),
        ),
      ],
    ),
  );
}

class ReportsTab extends StatelessWidget {
  const ReportsTab({super.key, required this.state});
  final DermaireState state;

  @override
  Widget build(BuildContext context) => _TabPage(
    children: [
      const Eyebrow('Experiment complete'),
      Text('Your results', style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 6),
      const Text('Product X · 28-day experiment'),
      const SizedBox(height: 16),
      const DermaireCard(
        color: DermaireColors.card,
        child: SizedBox(height: 160, child: _ProgressChart()),
      ),
      const Row(
        children: [
          Expanded(child: MetricTile('−18%', 'Texture change')),
          SizedBox(width: 10),
          Expanded(child: MetricTile('25/28', 'Check-ins logged')),
        ],
      ),
      const SizedBox(height: 14),
      const Notice(
        icon: 'ⓘ',
        text:
            'Your result was adjusted for 3 days of recorded environmental conditions.',
      ),
      FilledButton(
        onPressed: () => openPage(context, ResultsScreen(state: state)),
        child: const Text('View full result'),
      ),
      const SizedBox(height: 8),
      OutlinedButton(
        onPressed: () => openPage(context, ReportScreen(state: state)),
        child: const Text('Generate report'),
      ),
    ],
  );
}

class _ProgressChart extends StatelessWidget {
  const _ProgressChart();

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _ChartPainter(), child: const SizedBox.expand());
}

class _ChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = DermaireColors.line
      ..strokeWidth = 1;
    for (var i = 1; i < 4; i++) {
      canvas.drawLine(
        Offset(0, size.height * i / 4),
        Offset(size.width, size.height * i / 4),
        grid,
      );
    }
    final values = [.82, .74, .78, .57, .52, .33, .28, .13];
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final point = Offset(
        size.width * i / (values.length - 1),
        size.height * values[i],
      );
      i == 0
          ? path.moveTo(point.dx, point.dy)
          : path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = DermaireColors.deep
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key, required this.state});
  final DermaireState state;

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  int interpretation = 0;

  @override
  Widget build(BuildContext context) {
    const titles = [
      'Your skin showed improvement',
      'No significant change detected',
      'Measurements changed negatively',
    ];
    const descriptions = [
      'Texture improved by 18% compared with your personal baseline.',
      'Your measurements stayed close to your personal baseline.',
      'Some measurements moved away from your baseline during the experiment.',
    ];
    final colors = [
      DermaireColors.safeBackground,
      DermaireColors.paper,
      DermaireColors.conflictBackground,
    ];
    return DermairePage(
      eyebrow: 'Result interpretation',
      title: 'What this means',
      children: [
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 0, label: Text('Positive')),
            ButtonSegment(value: 1, label: Text('No change')),
            ButtonSegment(value: 2, label: Text('Negative')),
          ],
          selected: {interpretation},
          onSelectionChanged: (value) =>
              setState(() => interpretation = value.first),
          showSelectedIcon: false,
          style: const ButtonStyle(visualDensity: VisualDensity.compact),
        ),
        const SizedBox(height: 16),
        DermaireCard(
          color: colors[interpretation],
          borderColor: Colors.transparent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${interpretation == 0
                    ? '🟢'
                    : interpretation == 1
                    ? '⚪'
                    : '🟠'} ${titles[interpretation]}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                descriptions[interpretation],
                style: const TextStyle(fontSize: 12.5),
              ),
            ],
          ),
        ),
        if (interpretation == 0)
          FilledButton(
            onPressed: () =>
                openPage(context, ReportScreen(state: widget.state)),
            child: const Text('Generate report'),
          )
        else
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              interpretation == 1
                  ? 'Start another experiment'
                  : 'Review experiment',
            ),
          ),
      ],
    );
  }
}

class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key, required this.state});
  final DermaireState state;

  @override
  Widget build(BuildContext context) {
    const sections = [
      ('1. Experiment', 'Product X · 28 days · Target: texture'),
      (
        '2. Baseline',
        'Personal average and standard deviation computed from your first 5 check-ins',
      ),
      ('3–4. Measurements & change', 'Texture improved 18% vs. baseline'),
      (
        '5. Context',
        '3 days excluded for abnormal weather; cycle context logged where provided',
      ),
      (
        '6. Conclusion',
        'The measured change was associated with the tested product during this controlled experiment.',
      ),
      ('7. Data quality', '25 of 28 check-ins · 89% consistency'),
    ];
    return DermairePage(
      eyebrow: 'AI-generated report',
      title: 'Personal Skin Lab report',
      children: [
        ...sections.map((item) => _LabeledValue(item.$1, item.$2)),
        FilledButton(
          onPressed: () => openPage(context, DoctorAccessScreen(state: state)),
          child: const Text('Share with doctor'),
        ),
      ],
    );
  }
}

class DoctorAccessScreen extends StatelessWidget {
  const DoctorAccessScreen({super.key, required this.state});
  final DermaireState state;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: state,
    builder: (context, _) => DermairePage(
      eyebrow: 'Doctor access',
      title: state.doctorLinkActive ? 'Scan to view report' : 'Access revoked',
      children: [
        if (state.doctorLinkActive) ...[
          Center(
            child: Container(
              width: 156,
              height: 156,
              margin: const EdgeInsets.symmetric(vertical: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: DermaireColors.paper,
                border: Border.all(color: DermaireColors.caramel),
              ),
              child: const _QrPattern(),
            ),
          ),
          const DermaireCard(
            color: DermaireColors.card,
            child: Column(
              children: [
                Text(
                  'Valid for 7 days',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                Text('Expires Apr 29, 2025', style: TextStyle(fontSize: 11.5)),
              ],
            ),
          ),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: DermaireColors.conflict,
              side: const BorderSide(color: DermaireColors.conflict),
            ),
            onPressed: state.revokeDoctorLink,
            child: const Text('Revoke access'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () =>
                showDermaireSnack(context, 'Report prepared for export'),
            child: const Text('Export report'),
          ),
          const SizedBox(height: 14),
          const Text(
            'No login required — your doctor opens this on any browser.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11.5),
          ),
        ] else ...[
          const SizedBox(height: 24),
          const Center(
            child: Icon(
              Icons.lock_outline_rounded,
              size: 48,
              color: DermaireColors.conflict,
            ),
          ),
          const SizedBox(height: 18),
          const Notice(
            icon: '✓',
            text: 'The previous link can no longer be used.',
            color: DermaireColors.safeBackground,
          ),
        ],
      ],
    ),
  );
}

class _QrPattern extends StatelessWidget {
  const _QrPattern();
  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _QrPainter(), child: const SizedBox.expand());
}

class _QrPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = DermaireColors.ink;
    const cells = 13;
    final cell = size.width / cells;
    for (var y = 0; y < cells; y++) {
      for (var x = 0; x < cells; x++) {
        if (((x * 7 + y * 11 + x * y) % 5 < 2) ||
            (x < 3 && y < 3) ||
            (x > 9 && y < 3) ||
            (x < 3 && y > 9)) {
          canvas.drawRect(
            Rect.fromLTWH(x * cell, y * cell, cell - 1, cell - 1),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key, required this.state});
  final DermaireState state;

  @override
  Widget build(BuildContext context) => _TabPage(
    children: [
      const Eyebrow('Settings'),
      Text(
        'Privacy dashboard',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: 16),
      const DermaireCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'What we store',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 6),
            Text(
              '• Skin measurement vectors\n• Check-in context (weather, cycle day)\n• No raw photos, ever',
              style: TextStyle(fontSize: 12, height: 1.6),
            ),
          ],
        ),
      ),
      ActionCard(
        icon: '👤',
        title: 'Account',
        subtitle: 'Salma Ahmed · Student plan',
        onTap: () => showDermaireSnack(context, 'Account settings opened'),
      ),
      ActionCard(
        icon: '🔔',
        title: 'Notifications',
        subtitle: 'Check-in and experiment reminders',
        onTap: () => openPage(context, NotificationsScreen()),
      ),
      ActionCard(
        icon: '🔒',
        title: 'Doctor access',
        subtitle: state.doctorLinkActive
            ? 'One active QR link'
            : 'No active links',
        onTap: () => openPage(context, DoctorAccessScreen(state: state)),
      ),
      ActionCard(
        icon: '♿',
        title: 'Accessibility',
        subtitle: 'Voice, larger text and contrast follow your device',
        onTap: () =>
            showDermaireSnack(context, 'Accessibility preferences opened'),
      ),
      ActionCard(
        icon: 'ⓘ',
        title: 'About & methodology',
        subtitle: 'How Personal Skin Lab works',
        onTap: () => openPage(context, const HowItWorksScreen()),
      ),
      ActionCard(
        icon: '💬',
        title: 'Dermaire guide',
        subtitle: 'App help, measurement explanations and safety escalation',
        onTap: () => openPage(context, const SkinAssistantScreen()),
      ),
      const SizedBox(height: 6),
      Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => showDermaireSnack(
                context,
                'Your data export is being prepared',
              ),
              child: const Text('Export data'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: DermaireColors.conflict,
                side: const BorderSide(color: DermaireColors.conflict),
              ),
              onPressed: () => _deleteWarning(context),
              child: const Text('Delete account'),
            ),
          ),
        ],
      ),
    ],
  );

  void _deleteWarning(BuildContext context) => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: DermaireColors.card,
      title: const Text('Delete account?'),
      content: const Text('This is a demo. No data will be deleted.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    ),
  );
}

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});
  static const templates = [
    (
      '☀️',
      'Your daily skin check-in is ready',
      "It's usually a good time for your check-in.",
    ),
    (
      '🕒',
      "You missed yesterday's check-in",
      'Consistency helps, but you can continue anytime.',
    ),
    (
      '⏳',
      'Your experiment ends tomorrow',
      'One more check-in to complete this round.',
    ),
    ('🎉', 'Your results are ready', 'Open the app to see your report.'),
    (
      '🔒',
      'Your doctor access expires tomorrow',
      'Generate a new link if they still need it.',
    ),
    ('⚠️', 'Interaction check required', 'Review before adding this product.'),
  ];
  @override
  Widget build(BuildContext context) => DermairePage(
    eyebrow: 'Notifications',
    title: 'Templates',
    children: templates
        .map(
          (item) =>
              ActionCard(icon: item.$1, title: item.$2, subtitle: item.$3),
        )
        .toList(),
  );
}

class HowItWorksScreen extends StatelessWidget {
  const HowItWorksScreen({super.key});
  static const steps = [
    ('1', 'Capture', 'Your phone guides you into the same position each time.'),
    ('2', 'Measure', 'Skin features are extracted on your device.'),
    (
      '3',
      'Compare',
      'Measurements are compared against your personal baseline.',
    ),
    ('4', 'Control', 'Weather and other context are considered.'),
    (
      '5',
      'Report',
      'AI turns your experiment data into an understandable report.',
    ),
  ];
  @override
  Widget build(BuildContext context) => DermairePage(
    eyebrow: 'About',
    title: 'How Personal Skin Lab works',
    children: [
      ...steps.map(
        (step) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: DermaireColors.deep,
                foregroundColor: Colors.white,
                child: Text(
                  step.$1,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.$2,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(step.$3, style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      const Notice(
        icon: 'ⓘ',
        text:
            'We measure changes in your skin measurements. Interaction checks use fixed rules, not AI guesswork.',
      ),
    ],
  );
}

class TimelineScreen extends StatelessWidget {
  const TimelineScreen({super.key, required this.state});
  final DermaireState state;
  static const events = [
    ('Day 1', 'Baseline period begins'),
    ('Day 5', 'Baseline established'),
    ('Day 7', 'Check-in logged'),
    ('Day 10', 'Product added — interaction check passed'),
    ('Day 14', 'Environmental anomaly recorded'),
    ('Day 21', 'Check-in logged'),
    ('Day 28', 'Experiment complete'),
  ];

  @override
  Widget build(BuildContext context) => DermairePage(
    eyebrow: 'Experiment timeline',
    title:
        '${state.productController.active.where((product) => product.inExperiment).firstOrNull?.name ?? 'No active product'} · Texture',
    actions: [
      IconButton(
        onPressed: state.togglePause,
        icon: Icon(
          state.experimentPaused
              ? Icons.play_arrow_rounded
              : Icons.pause_rounded,
        ),
      ),
    ],
    children: [
      if (state.experimentPaused)
        const Notice(
          icon: '⏸',
          text: 'Experiment paused. Resume any time.',
          color: DermaireColors.unknownBackground,
        ),
      ...events.indexed.map((entry) {
        final current = entry.$1 + 1 == state.experimentDay;
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 26,
                child: Column(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: current
                            ? DermaireColors.deep
                            : DermaireColors.caramel,
                        shape: BoxShape.circle,
                      ),
                    ),
                    if (entry.$1 < events.length - 1)
                      Expanded(
                        child: Container(
                          width: 1,
                          color: DermaireColors.caramel,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.$2.$1,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                        ),
                      ),
                      Text(entry.$2.$2, style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    ],
  );
}

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key, required this.state});
  final DermaireState state;

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  double alignment = .25;
  bool issue = false;

  @override
  Widget build(BuildContext context) => DermairePage(
    eyebrow: 'Guided check-in',
    title: 'Position your face',
    subtitle: issue
        ? 'We need to match your previous position.'
        : 'Tilt slightly left, then hold still',
    children: [
      FaceGuide(
        label: issue
            ? 'Previous vs.\ncurrent position'
            : alignment >= 1
            ? 'Position locked ✓'
            : 'Aligning…',
        warning: issue,
      ),
      LinearProgressIndicator(
        value: alignment,
        minHeight: 6,
        color: issue ? DermaireColors.unknown : DermaireColors.deep,
        backgroundColor: DermaireColors.line,
      ),
      const SizedBox(height: 14),
      Notice(
        icon: issue ? '🟡' : 'ⓘ',
        text: issue
            ? 'Tilt slightly to the right, keep your whole face in frame, and hold steady.'
            : 'Matching your exact angle each day is what makes measurements comparable.',
        color: issue ? DermaireColors.unknownBackground : DermaireColors.paper,
      ),
      FilledButton(
        onPressed: () {
          if (issue) {
            setState(() {
              issue = false;
              alignment = .45;
            });
          } else if (alignment < 1) {
            setState(() => alignment = 1);
          } else {
            widget.state.completeCheckIn();
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => CheckInCompleteScreen(state: widget.state),
              ),
            );
          }
        },
        child: Text(
          issue
              ? 'Try again'
              : alignment < 1
              ? 'Lock position'
              : 'Capture measurement',
        ),
      ),
      const SizedBox(height: 8),
      OutlinedButton(
        onPressed: () => setState(() => issue = !issue),
        child: const Text('Simulate camera issue'),
      ),
    ],
  );
}

class CheckInCompleteScreen extends StatelessWidget {
  const CheckInCompleteScreen({super.key, required this.state});
  final DermaireState state;

  @override
  Widget build(BuildContext context) => DermairePage(
    title: 'Check-in complete',
    subtitle: "Today's measurement has been added to your experiment.",
    centered: true,
    children: [
      const SizedBox(height: 8),
      const Row(
        children: [
          Expanded(child: MetricTile('Good', 'Redness')),
          SizedBox(width: 10),
          Expanded(child: MetricTile('Stable', 'Texture')),
        ],
      ),
      const SizedBox(height: 14),
      const Notice(
        icon: 'ⓘ',
        text:
            "One day's result doesn't prove anything on its own — your report looks at the trend over time.",
      ),
      FilledButton(
        onPressed: () => openPage(context, ContextScreen(state: state)),
        child: const Text("Add today's context"),
      ),
      const SizedBox(height: 8),
      OutlinedButton(
        onPressed: () =>
            Navigator.of(context).popUntil((route) => route.isFirst),
        child: const Text('View experiment'),
      ),
    ],
  );
}

class ContextScreen extends StatefulWidget {
  const ContextScreen({super.key, required this.state});
  final DermaireState state;

  @override
  State<ContextScreen> createState() => _ContextScreenState();
}

class _ContextScreenState extends State<ContextScreen> {
  bool unusualWeather = false;
  double cycleDay = 12;

  @override
  Widget build(BuildContext context) => DermairePage(
    eyebrow: "Today's context",
    title: unusualWeather
        ? 'Unusual conditions detected'
        : 'A few quick details',
    children: [
      if (unusualWeather)
        const Notice(
          icon: '🟡',
          text:
              "Today's environmental conditions differ significantly from your usual measurements. We'll account for this in your result.",
          color: DermaireColors.unknownBackground,
        ),
      DermaireCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Weather',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: MetricTile(
                    unusualWeather ? '34°C' : '22°C',
                    'Temperature',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: MetricTile(unusualWeather ? '88%' : '48%', 'Humidity'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Simulate unusual weather',
                style: TextStyle(fontSize: 12.5),
              ),
              value: unusualWeather,
              activeTrackColor: DermaireColors.deep,
              onChanged: (value) => setState(() => unusualWeather = value),
            ),
          ],
        ),
      ),
      DermaireCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Personal context (optional)',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Cycle day ${cycleDay.round()}',
              style: const TextStyle(fontSize: 12),
            ),
            Slider(
              value: cycleDay,
              min: 1,
              max: 28,
              divisions: 27,
              activeColor: DermaireColors.deep,
              onChanged: (value) => setState(() => cycleDay = value),
            ),
          ],
        ),
      ),
      FilledButton(
        onPressed: () {
          Navigator.of(context).popUntil((route) => route.isFirst);
          showDermaireSnack(context, 'Context saved');
        },
        child: const Text('Save context'),
      ),
    ],
  );
}
