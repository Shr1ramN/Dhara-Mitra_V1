import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'enums.dart';
import 'l10n.dart';
import 'theme.dart';

/// Loading / error / data for a provider value.
class AsyncBody<T> extends StatelessWidget {
  const AsyncBody({super.key, required this.value, required this.builder});

  final AsyncValue<T> value;
  final Widget Function(T data) builder;

  @override
  Widget build(BuildContext context) => switch (value) {
    AsyncData(:final value) => builder(value),
    AsyncError(:final error) => Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text('$error', style: const TextStyle(color: AppColors.down)),
      ),
    ),
    _ => const Center(child: CircularProgressIndicator()),
  };
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 20, 4, 10),
    child: Row(
      children: [
        Expanded(
          child: Text(
            Localizations.localeOf(context).languageCode == 'en'
                ? text.toUpperCase()
                : text,
            style: const TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontFamilyFallback: ['NotoSansKannada'],
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
              letterSpacing: 0.7,
              color: AppColors.textMuted,
            ),
          ),
        ),
        if (trailing != null) Flexible(child: trailing!),
      ],
    ),
  );
}

class PaddedCard extends StatelessWidget {
  const PaddedCard({
    super.key,
    required this.child,
    this.onTap,
    this.color,
    this.borderColor,
  });

  final Widget child;
  final VoidCallback? onTap;
  final Color? color;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) => Card(
    color: color,
    shape: borderColor == null
        ? null
        : RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: borderColor!),
          ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(padding: const EdgeInsets.all(14), child: child),
    ),
  );
}

class Kpi extends StatelessWidget {
  const Kpi({
    super.key,
    required this.label,
    required this.value,
    this.onTap,
    this.highlight = false,
    this.valueColor,
  });

  final String label;
  final String value;
  final VoidCallback? onTap;
  final bool highlight;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) => PaddedCard(
    onTap: onTap,
    color: highlight ? const Color(0xFFFFFAF6) : null,
    borderColor: highlight ? AppColors.accent.withValues(alpha: 0.4) : null,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: display(
              20,
              color:
                  valueColor ??
                  (highlight ? AppColors.accentDark : AppColors.text),
            ),
          ),
        ),
      ],
    ),
  );
}

/// Two KPIs side by side.
class KpiRow extends StatelessWidget {
  const KpiRow({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (var i = 0; i < children.length; i++) ...[
        if (i > 0) const SizedBox(width: 10),
        Expanded(child: children[i]),
      ],
    ],
  );
}

class KvRow extends StatelessWidget {
  const KvRow(this.label, this.value, {super.key, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: AppColors.textMuted),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(fontWeight: FontWeight.w600, color: valueColor),
          ),
        ),
      ],
    ),
  );
}

class Pill extends StatelessWidget {
  const Pill(
    this.text, {
    super.key,
    required this.background,
    required this.foreground,
    this.icon,
  });

  final String text;
  final Color background;
  final Color foreground;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 12, color: foreground),
          const SizedBox(width: 4),
        ],
        Text(
          text,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: foreground,
          ),
        ),
      ],
    ),
  );
}

class StagePill extends StatelessWidget {
  const StagePill(this.stage, {super.key});

  final LotStage stage;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, icon) = switch (stage) {
      LotStage.harvest => (
        AppColors.okBg,
        AppColors.okText,
        Icons.eco_outlined,
      ),
      LotStage.drying => (
        AppColors.warnBg,
        AppColors.warnText,
        Icons.wb_sunny_outlined,
      ),
      LotStage.peeling || LotStage.grading => (
        AppColors.accentSoft,
        AppColors.accentDark,
        Icons.content_cut,
      ),
      LotStage.storage => (
        AppColors.infoBg,
        AppColors.infoText,
        Icons.inventory_2_outlined,
      ),
      LotStage.sold => (
        const Color(0xFFF0EEEC),
        AppColors.textMuted,
        Icons.check,
      ),
    };
    return Pill(
      context.l.stage(stage),
      background: bg,
      foreground: fg,
      icon: icon,
    );
  }
}

class CropDot extends StatelessWidget {
  const CropDot(this.crop, {super.key});

  final Crop crop;

  @override
  Widget build(BuildContext context) => Container(
    width: 9,
    height: 9,
    decoration: BoxDecoration(
      color: AppColors.crop(crop),
      shape: BoxShape.circle,
    ),
  );
}

class RoundIcon extends StatelessWidget {
  const RoundIcon(
    this.icon, {
    super.key,
    this.color = AppColors.text,
    this.background = AppColors.background,
  });

  final IconData icon;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) => Container(
    width: 38,
    height: 38,
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(11),
      border: Border.all(color: AppColors.border),
    ),
    child: Icon(icon, size: 19, color: color),
  );
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.text,
    this.action,
  });

  final IconData icon;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
    child: Column(
      children: [
        RoundIcon(
          icon,
          color: AppColors.accent,
          background: AppColors.accentSoft,
        ),
        const SizedBox(height: 14),
        Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textMuted, height: 1.45),
        ),
        if (action != null) ...[const SizedBox(height: 16), action!],
      ],
    ),
  );
}

class ProgressLine extends StatelessWidget {
  const ProgressLine(this.value, {super.key});

  final double value;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(99),
    child: LinearProgressIndicator(
      value: value,
      minHeight: 8,
      backgroundColor: AppColors.background,
      color: AppColors.accent,
    ),
  );
}

void showSnack(BuildContext context, String text) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));
}

Future<bool> confirm(
  BuildContext context, {
  required String title,
  String? body,
  String? action,
}) async {
  final l = context.l;
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: body == null ? null : Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(action ?? l.delete),
        ),
      ],
    ),
  );
  return ok ?? false;
}

/// Standard bottom sheet with a title, scrollable body and the keyboard pushing it up.
Future<T?> showFormSheet<T>(
  BuildContext context, {
  required String title,
  required WidgetBuilder builder,
}) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  backgroundColor: AppColors.background,
  builder: (context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: display(20)),
          const SizedBox(height: 16),
          builder(context),
        ],
      ),
    ),
  ),
);
