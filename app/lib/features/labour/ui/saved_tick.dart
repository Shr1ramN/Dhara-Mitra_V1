import 'package:flutter/material.dart';

void showSavedTick(BuildContext context, String message) {
  final entry = OverlayEntry(
    builder: (context) => IgnorePointer(
      child: Center(
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(20),
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, size: 48),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  Overlay.of(context).insert(entry);
  Future<void>.delayed(const Duration(milliseconds: 900), entry.remove);
}
