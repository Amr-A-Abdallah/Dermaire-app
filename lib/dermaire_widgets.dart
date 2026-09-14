import 'package:flutter/material.dart';

import 'dermaire_theme.dart';

class DermairePage extends StatelessWidget {
  const DermairePage({
    super.key,
    this.eyebrow,
    required this.title,
    this.subtitle,
    required this.children,
    this.actions,
    this.centered = false,
    this.showBack = true,
  });

  final String? eyebrow;
  final String title;
  final String? subtitle;
  final List<Widget> children;
  final List<Widget>? actions;
  final bool centered;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final header = <Widget>[
      if (eyebrow != null) Eyebrow(eyebrow!),
      Text(
        title,
        textAlign: centered ? TextAlign.center : TextAlign.start,
        style: Theme.of(
          context,
        ).textTheme.headlineSmall?.copyWith(fontSize: 23),
      ),
      if (subtitle != null) ...[
        const SizedBox(height: 6),
        Text(
          subtitle!,
          textAlign: centered ? TextAlign.center : TextAlign.start,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: .72),
          ),
        ),
      ],
      const SizedBox(height: 18),
    ];
    return Scaffold(
      appBar: showBack ? AppBar(actions: actions) : null,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            if (centered)
              Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: header),
              )
            else
              ...header,
            ...children,
          ],
        ),
      ),
    );
  }
}

class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontFamily: 'Karla',
        fontSize: 11,
        color: DermaireColors.deep,
        letterSpacing: .4,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class DermaireCard extends StatelessWidget {
  const DermaireCard({
    super.key,
    required this.child,
    this.color,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.borderColor,
  });

  final Widget child;
  final Color? color;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Material(
      color: color ?? Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor ?? Theme.of(context).dividerColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    ),
  );
}

class ActionCard extends StatelessWidget {
  const ActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.enabled = true,
  });
  final String icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: enabled ? 1 : .55,
    child: DermaireCard(
      color: DermaireColors.card,
      onTap: enabled ? onTap : null,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: DermaireColors.caramel,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Text(icon, style: const TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: DermaireColors.ink.withValues(alpha: .65),
                  ),
                ),
              ],
            ),
          ),
          if (onTap != null)
            const Icon(
              Icons.chevron_right_rounded,
              color: DermaireColors.caramel,
            ),
        ],
      ),
    ),
  );
}

class Notice extends StatelessWidget {
  const Notice({
    super.key,
    required this.icon,
    required this.text,
    this.color = DermaireColors.paper,
  });
  final String icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: DermaireColors.line),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(icon),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 12.5, height: 1.45),
          ),
        ),
      ],
    ),
  );
}

class MetricTile extends StatelessWidget {
  const MetricTile(this.value, this.label, {super.key, this.icon});
  final String value;
  final String label;
  final String? icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: DermaireColors.card,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: DermaireColors.line),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) Text(icon!, style: const TextStyle(fontSize: 17)),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 17),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: DermaireColors.ink.withValues(alpha: .6),
          ),
        ),
      ],
    ),
  );
}

class StatusPill extends StatelessWidget {
  const StatusPill(this.label, {super.key, this.kind = StatusKind.safe});
  final String label;
  final StatusKind kind;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (kind) {
      StatusKind.safe => (DermaireColors.safeBackground, DermaireColors.safe),
      StatusKind.warning => (
        DermaireColors.unknownBackground,
        DermaireColors.unknown,
      ),
      StatusKind.conflict => (
        DermaireColors.conflictBackground,
        DermaireColors.conflict,
      ),
      StatusKind.neutral => (DermaireColors.line, DermaireColors.ink),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: foreground,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

enum StatusKind { safe, warning, conflict, neutral }

class ButtonStack extends StatelessWidget {
  const ButtonStack({
    super.key,
    required this.primaryLabel,
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
  });
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      FilledButton(onPressed: onPrimary, child: Text(primaryLabel)),
      if (secondaryLabel != null) ...[
        const SizedBox(height: 8),
        OutlinedButton(onPressed: onSecondary, child: Text(secondaryLabel!)),
      ],
    ],
  );
}

class FaceGuide extends StatelessWidget {
  const FaceGuide({super.key, this.label = 'Aligning…', this.warning = false});
  final String label;
  final bool warning;

  @override
  Widget build(BuildContext context) => Container(
    height: 210,
    margin: const EdgeInsets.only(bottom: 14),
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: DermaireColors.paper,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: warning ? DermaireColors.unknown : DermaireColors.caramel,
        width: 1.5,
      ),
    ),
    child: Container(
      width: 148,
      height: 178,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(74),
          bottom: Radius.circular(62),
        ),
        border: Border.all(
          color: warning ? DermaireColors.unknown : DermaireColors.safe,
          width: 3,
        ),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 12, color: DermaireColors.deep),
      ),
    ),
  );
}

Future<T?> openPage<T>(BuildContext context, Widget page) =>
    Navigator.of(context).push<T>(MaterialPageRoute(builder: (_) => page));

void showDermaireSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
