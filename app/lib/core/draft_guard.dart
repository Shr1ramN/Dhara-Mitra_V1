import 'dart:convert';

import 'package:flutter/material.dart';

import 'v1.dart';

bool _visible(_DraftGuardState draft) {
  if (!draft.mounted || draft.route?.isCurrent != true) return false;
  var active = true;
  draft.context.visitAncestorElements((element) {
    if (element.widget is! Navigator) return true;
    final route = ModalRoute.of(element);
    if (route != null && !route.isCurrent) {
      active = false;
      return false;
    }
    return true;
  });
  return active;
}

final _drafts = <_DraftGuardState>{};
bool _asking = false;
void acceptDrafts() {
  for (final draft in _drafts.where((d) => _visible(d))) {
    draft.accept();
  }
}

Future<bool> confirmLeaving(BuildContext context) async {
  final pending = _drafts.where((d) => _visible(d) && d.dirty).toList();
  if (pending.isEmpty) return true;
  if (_asking) return false;
  _asking = true;
  try {
    final discard =
        await showDialog<bool>(
          context: context,
          builder: (c) => AlertDialog(
            title: Text(v1Text(c, 'Unsaved changes', 'ಉಳಿಸದ ಬದಲಾವಣೆಗಳು')),
            content: Text(
              v1Text(
                c,
                'Your changes have not been saved. Leaving will discard only these unsaved changes.',
                'ನಿಮ್ಮ ಬದಲಾವಣೆಗಳನ್ನು ಉಳಿಸಿಲ್ಲ. ಹೊರಹೋದರೆ ಉಳಿಸದ ಬದಲಾವಣೆಗಳು ಮಾತ್ರ ಕಳೆದುಹೋಗುತ್ತವೆ.',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c, false),
                child: Text(v1Text(c, 'Keep editing', 'ತಿದ್ದುಪಡಿ ಮುಂದುವರಿಸಿ')),
              ),
              TextButton(
                onPressed: () => Navigator.pop(c, true),
                child: Text(v1Text(c, 'Discard and leave', 'ಬಿಟ್ಟು ಹೊರಹೋಗಿ')),
              ),
            ],
          ),
        ) ??
        false;
    if (discard) {
      for (final d in pending) {
        if (d.mounted) d.accept();
      }
    }
    return discard;
  } finally {
    _asking = false;
  }
}

class DraftGuard extends StatefulWidget {
  const DraftGuard({
    super.key,
    required this.controllers,
    required this.child,
    this.extra,
  });
  final List<TextEditingController> controllers;
  final Object? Function()? extra;
  final Widget child;
  @override
  State<DraftGuard> createState() => _DraftGuardState();
}

class _DraftGuardState extends State<DraftGuard> implements PopEntry<Object?> {
  String? baseline;
  ModalRoute<dynamic>? route;
  @override
  final ValueNotifier<bool> canPopNotifier = ValueNotifier<bool>(true);
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = ModalRoute.of(context);
    if (next != route) {
      route?.unregisterPopEntry(this);
      route = next;
      route?.registerPopEntry(this);
    }
  }

  @override
  void onPopInvoked(bool didPop) {}
  @override
  Future<void> onPopInvokedWithResult(bool didPop, Object? result) async {
    if (!didPop && await confirmLeaving(context) && mounted) {
      Navigator.of(context).pop(result);
    }
  }

  String get value => jsonEncode([
    for (final c in widget.controllers) c.text,
    widget.extra?.call().toString(),
  ]);
  bool get dirty => baseline != null && baseline != value;
  @override
  void initState() {
    super.initState();
    baseline = value;
    _drafts.add(this);
    for (final c in widget.controllers) {
      c.addListener(changed);
    }
  }

  @override
  void didUpdateWidget(covariant DraftGuard oldWidget) {
    super.didUpdateWidget(oldWidget);
    changed();
    for (final c in oldWidget.controllers) {
      if (!widget.controllers.contains(c)) c.removeListener(changed);
    }
    for (final c in widget.controllers) {
      if (!oldWidget.controllers.contains(c)) c.addListener(changed);
    }
  }

  void changed() {
    canPopNotifier.value = !dirty;
  }

  void accept() {
    baseline = value;
    canPopNotifier.value = true;
  }

  @override
  void dispose() {
    route?.unregisterPopEntry(this);
    canPopNotifier.dispose();
    _drafts.remove(this);
    for (final c in widget.controllers) {
      c.removeListener(changed);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
