import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n.dart';
import '../../core/widgets.dart';
import '../documents/documents_screen.dart';
import 'forms.dart';

class RecordItem {
  const RecordItem({
    required this.id,
    required this.title,
    required this.subtitle,
    this.details = const {},
    this.refType,
    this.onEdit,
    this.onDelete,
    this.actions = const [],
  });
  final String id, title, subtitle;
  final Map<String, String> details;
  final String? refType;
  final Future<void> Function()? onEdit, onDelete;
  final List<Widget> actions;
}

class RecordPage<T> extends StatelessWidget {
  const RecordPage({
    super.key,
    required this.title,
    required this.value,
    required this.itemBuilder,
    required this.onAdd,
    this.intro,
    this.actions = const [],
    this.embedded = false,
  });
  final String title;
  final AsyncValue<List<T>> value;
  final RecordItem Function(T) itemBuilder;
  final VoidCallback onAdd;
  final String? intro;
  final List<Widget> actions;
  final bool embedded;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: embedded ? null : AppBar(title: Text(title), actions: actions),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: onAdd,
      icon: const Icon(Icons.add),
      label: Text(context.l.add),
    ),
    body: AsyncBody(
      value: value,
      builder: (all) => ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          if (intro != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(intro!),
            ),
          if (all.isEmpty)
            EmptyState(icon: Icons.folder_open, text: context.l.xEmpty),
          for (final record in all) _RecordCard(itemBuilder(record)),
        ],
      ),
    ),
  );
}

class _RecordCard extends StatelessWidget {
  const _RecordCard(this.item);
  final RecordItem item;
  @override
  Widget build(BuildContext context) => Card(
    child: ExpansionTile(
      title: Text(item.title),
      subtitle: Text(item.subtitle),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final e in item.details.entries) KvRow(e.key, e.value),
        if (item.refType != null)
          OutlinedButton.icon(
            icon: const Icon(Icons.attach_file),
            label: Text(context.l.xDocuments),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    DocumentsScreen(refType: item.refType, refId: item.id),
              ),
            ),
          ),
        ...item.actions,
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (item.onEdit != null)
              TextButton.icon(
                icon: const Icon(Icons.edit_outlined),
                label: Text(context.l.edit),
                onPressed: () => perform(context, item.onEdit!),
              ),
            if (item.onDelete != null)
              TextButton.icon(
                icon: const Icon(Icons.delete_outline),
                label: Text(context.l.delete),
                onPressed: () async {
                  if (await confirm(context, title: context.l.confirmDelete) &&
                      context.mounted) {
                    await perform(context, item.onDelete!);
                  }
                },
              ),
          ],
        ),
      ],
    ),
  );
}
