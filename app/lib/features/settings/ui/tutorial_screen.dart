import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/l10n.dart';
import '../../../core/providers.dart';
import '../../../core/v1.dart';

class TutorialScreen extends ConsumerStatefulWidget {
  const TutorialScreen({super.key});
  @override
  ConsumerState<TutorialScreen> createState() => _TutorialState();
}

class _TutorialState extends ConsumerState<TutorialScreen> {
  int step = 0;
  final scroll = ScrollController();
  void move(int next) {
    setState(() => step = next);
    if (scroll.hasClients) {
      scroll.jumpTo(0);
    }
  }

  @override
  void dispose() {
    scroll.dispose();
    super.dispose();
  }

  static const lessons = <(IconData, String, String, String, String, String)>[
    (
      Icons.home_outlined,
      'Home',
      'ಮುಖಪುಟ',
      'Home shows attendance, wages due, recent work, harvests and crop-sale income. The house button returns here.',
      'ಮುಖಪುಟದಲ್ಲಿ ಹಾಜರಾತಿ, ಬಾಕಿ ವೇತನ, ಇತ್ತೀಚಿನ ಕೆಲಸ, ಕೊಯ್ಲು ಮತ್ತು ಮಾರಾಟದ ಆದಾಯ ನೋಡಿ. ಮನೆ ಬಟನ್ ಒತ್ತಿ ಇಲ್ಲಿಗೆ ಮರಳಿ.',
      '/',
    ),
    (
      Icons.calendar_month,
      'Calendar',
      'ಕ್ಯಾಲೆಂಡರ್',
      'Tap a date to add labour work, farm activity, harvest or a sale on that day. Search and filters help find saved records.',
      'ಒಂದು ದಿನಾಂಕ ಒತ್ತಿ ಆ ದಿನದ ಕಾರ್ಮಿಕ ಕೆಲಸ, ತೋಟದ ಕೆಲಸ, ಕೊಯ್ಲು ಅಥವಾ ಮಾರಾಟ ಸೇರಿಸಿ. ಹುಡುಕಾಟ ಮತ್ತು ಫಿಲ್ಟರ್‌ಗಳಿಂದ ದಾಖಲೆಗಳನ್ನು ಹುಡುಕಿ.',
      '/calendar',
    ),
    (
      Icons.person_add,
      'Add workers',
      'ಕಾರ್ಮಿಕರನ್ನು ಸೇರಿಸಿ',
      'Open Labour Management and Add Worker. Choose Daily wage or Other. Other workers have the actual wage entered on each attended day.',
      'ಕಾರ್ಮಿಕ ನಿರ್ವಹಣೆಯಲ್ಲಿ ಕಾರ್ಮಿಕರನ್ನು ಸೇರಿಸಿ. ದಿನಗೂಲಿ ಅಥವಾ ಇತರೆ ಆಯ್ಕೆಮಾಡಿ. ಇತರೆ ಕಾರ್ಮಿಕರ ಆ ದಿನದ ಕೂಲಿಯನ್ನು ಹಾಜರಾತಿಯಲ್ಲಿ ನಮೂದಿಸಿ.',
      '/labour',
    ),
    (
      Icons.how_to_reg,
      'Attendance',
      'ಹಾಜರಾತಿ',
      'Choose Present, Half day or Absent. Each tap saves automatically. Enter the day’s work once at the top.',
      'ಹಾಜರು, ಅರ್ಧ ದಿನ ಅಥವಾ ಗೈರು ಆಯ್ಕೆಮಾಡಿ. ಒತ್ತಿದಾಗ ತಾನಾಗಿಯೇ ಉಳಿಯುತ್ತದೆ. ದಿನದ ಕೆಲಸವನ್ನು ಮೇಲೆ ಒಮ್ಮೆ ನಮೂದಿಸಿ.',
      '/labour?tab=attendance',
    ),
    (
      Icons.payments_outlined,
      'Pay wages and reports',
      'ವೇತನ ಮತ್ತು ವರದಿಗಳು',
      'Dues shows what is unpaid. Settle wages records the amount actually paid. Labour Reports shows weekly, monthly and yearly history. Worker loans stay in worker profiles.',
      'ಬಾಕಿಯಲ್ಲಿ ಪಾವತಿಸಬೇಕಾದ ವೇತನ ನೋಡಿ. ವೇತನ ಪಾವತಿಯಲ್ಲಿ ಕೊಟ್ಟ ಮೊತ್ತ ನಮೂದಿಸಿ. ವರದಿಗಳಲ್ಲಿ ವಾರ, ತಿಂಗಳು ಮತ್ತು ವರ್ಷದ ವಿವರ ನೋಡಿ. ಕಾರ್ಮಿಕರ ಸಾಲ ಪ್ರೊಫೈಲ್‌ನಲ್ಲಿ ಇರುತ್ತದೆ.',
      '/labour?tab=reports',
    ),
    (
      Icons.grass,
      'Farm Activity',
      'ತೋಟದ ಕೆಲಸ',
      'Choose a work type or Add work type. Long-press a suggestion to remove it; past records stay safe. Add a description, then Save.',
      'ಕೆಲಸದ ಪ್ರಕಾರ ಆಯ್ಕೆಮಾಡಿ ಅಥವಾ ಹೊಸದು ಸೇರಿಸಿ. ಸೂಚನೆಯನ್ನು ತೆಗೆದುಹಾಕಲು ದೀರ್ಘವಾಗಿ ಒತ್ತಿ; ಹಳೆಯ ದಾಖಲೆಗಳು ಉಳಿಯುತ್ತವೆ. ವಿವರಣೆ ನೀಡಿ ಉಳಿಸಿ.',
      '/date-note',
    ),
    (
      Icons.eco_outlined,
      'Harvest',
      'ಕೊಯ್ಲು',
      'Record the crop and quantity in bags or kilograms. Open a saved harvest and choose Sold to Buyer when you sell it.',
      'ಬೆಳೆ ಮತ್ತು ಪ್ರಮಾಣವನ್ನು ಚೀಲ ಅಥವಾ ಕೆಜಿಯಲ್ಲಿ ದಾಖಲಿಸಿ. ಮಾರಾಟ ಮಾಡುವಾಗ ಉಳಿಸಿದ ಕೊಯ್ಲು ತೆರೆದು ಖರೀದಿದಾರರಿಗೆ ಮಾರಾಟ ಆಯ್ಕೆಮಾಡಿ.',
      '/date-note?label=harvest',
    ),
    (
      Icons.sell_outlined,
      'Sold to Buyer',
      'ಖರೀದಿದಾರರಿಗೆ ಮಾರಾಟ',
      'Select one or more crops, or add a crop. Give each crop its quantity and unit. Enter the buyer and total income. Additional Notes is optional. Save records the sale.',
      'ಒಂದು ಅಥವಾ ಹೆಚ್ಚಿನ ಬೆಳೆಗಳನ್ನು ಆಯ್ಕೆಮಾಡಿ ಅಥವಾ ಹೊಸದು ಸೇರಿಸಿ. ಪ್ರತಿ ಬೆಳೆಯ ಪ್ರಮಾಣ ಮತ್ತು ಘಟಕ ನೀಡಿ. ಖರೀದಿದಾರ ಮತ್ತು ಒಟ್ಟು ಆದಾಯ ನಮೂದಿಸಿ. ಹೆಚ್ಚುವರಿ ಟಿಪ್ಪಣಿ ಐಚ್ಛಿಕ. ಉಳಿಸಿ ಒತ್ತಿ.',
      '/date-note?label=sale',
    ),
    (
      Icons.more_horiz,
      'More',
      'ಇನ್ನಷ್ಟು',
      'Change language or Light/Dark/System theme. Edit farm crops, switch farms, back up/restore, export to Excel or replay Tutorial here. Backups protect your phone’s records.',
      'ಭಾಷೆ ಅಥವಾ ಬೆಳಕು/ಕತ್ತಲು/ಫೋನ್‌ನಂತೆ ನೋಟ ಬದಲಿಸಿ. ಬೆಳೆ ತಿದ್ದುಪಡಿ, ತೋಟ ಬದಲಾವಣೆ, ಸುರಕ್ಷಿತ ಪ್ರತಿ/ಮರುಸ್ಥಾಪನೆ, Excel ರಫ್ತು ಮತ್ತು ತರಬೇತಿ ಇಲ್ಲಿ ಇವೆ. ಸುರಕ್ಷಿತ ಪ್ರತಿ ಇಟ್ಟುಕೊಳ್ಳಿ.',
      '/more',
    ),
    (
      Icons.save_outlined,
      'Save before leaving',
      'ಹೊರಹೋಗುವ ಮೊದಲು ಉಳಿಸಿ',
      'Untouched forms can be left immediately. If you edit a record without saving, choose Keep editing or Discard and leave. Only unsaved changes are discarded.',
      'ತಿದ್ದುಪಡಿ ಮಾಡದ ಪುಟದಿಂದ ನೇರವಾಗಿ ಹೊರಹೋಗಬಹುದು. ಉಳಿಸದ ಬದಲಾವಣೆ ಇದ್ದರೆ ತಿದ್ದುಪಡಿ ಮುಂದುವರಿಸಿ ಅಥವಾ ಬಿಟ್ಟು ಹೊರಹೋಗಿ ಆಯ್ಕೆಮಾಡಿ. ಉಳಿಸದ ಬದಲಾವಣೆಗಳು ಮಾತ್ರ ಕಳೆದುಹೋಗುತ್ತವೆ.',
      '/calendar',
    ),
  ];
  Future<void> finish() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('tutorial.seen', true);
    if (mounted) {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lesson = lessons[step];
    final kn = ref.watch(localeProvider).languageCode == 'kn';
    return Scaffold(
      appBar: AppBar(title: Text(v1Text(context, 'Tutorial', 'ಬಳಕೆಯ ತರಬೇತಿ'))),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              if (step > 0) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => move(step - 1),
                    child: Text(v1Text(context, 'Previous', 'ಹಿಂದೆ')),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: FilledButton(
                  onPressed: step == lessons.length - 1
                      ? finish
                      : () => move(step + 1),
                  child: Text(
                    step == lessons.length - 1
                        ? v1Text(context, 'Finish', 'ಮುಗಿಸಿ')
                        : v1Text(context, 'Next', 'ಮುಂದೆ'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: ListView(
        controller: scroll,
        padding: const EdgeInsets.all(20),
        children: [
          SegmentedButton<String>(
            segments: [
              ButtonSegment(value: 'en', label: Text(context.l.english)),
              ButtonSegment(value: 'kn', label: Text(context.l.kannada)),
            ],
            selected: {kn ? 'kn' : 'en'},
            onSelectionChanged: (v) =>
                ref.read(localeProvider.notifier).set(v.first),
          ),
          const SizedBox(height: 24),
          LinearProgressIndicator(value: (step + 1) / lessons.length),
          const SizedBox(height: 16),
          Text('${step + 1} / ${lessons.length}'),
          const SizedBox(height: 24),
          Icon(
            lesson.$1,
            size: 72,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 20),
          Text(
            kn ? lesson.$3 : lesson.$2,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          Text(
            kn ? lesson.$5 : lesson.$4,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            icon: const Icon(Icons.touch_app_outlined),
            label: Text(
              v1Text(context, 'Try this screen', 'ಈ ಪುಟವನ್ನು ಪ್ರಯತ್ನಿಸಿ'),
            ),
            onPressed: () => context.push(lesson.$6),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: finish,
            child: Text(
              v1Text(
                context,
                'Finish for now — replay in More',
                'ಈಗ ಮುಗಿಸಿ — ಇನ್ನಷ್ಟು ಪುಟದಲ್ಲಿ ಮತ್ತೆ ನೋಡಿ',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
