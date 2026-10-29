import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:excel/excel.dart' hide TextSpan;
import 'package:flutter/painting.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

/// Renders PDF text with Flutter's bundled Indic font shaping. Kannada shaping
/// is preserved on every page instead of depending on a PDF viewer's fonts.
class ReportExport {
  static Future<File> excel(String title, List<List<Object?>> rows) async {
    final book = Excel.createExcel();
    final sheet = book['Dhara Mitra'];
    book.delete('Sheet1');
    sheet.appendRow([TextCellValue(title)]);
    for (final row in rows) {
      sheet.appendRow([
        for (final value in row)
          value is num
              ? DoubleCellValue(value.toDouble())
              : TextCellValue(value?.toString() ?? ''),
      ]);
    }
    final data = book.encode();
    if (data == null) throw const FileSystemException('Cannot encode workbook');
    final file = File(
      p.join(
        (await getTemporaryDirectory()).path,
        'dhara-mitra-${DateTime.now().microsecondsSinceEpoch}.xlsx',
      ),
    );
    return file.writeAsBytes(data, flush: true);
  }

  static Future<File> pdf(
    String title,
    List<List<Object?>> rows, {
    required bool kannada,
    String footer = '',
  }) async {
    final document = pw.Document();
    const width = 595.0, height = 842.0, margin = 28.0;
    var recorder = ui.PictureRecorder();
    var canvas = ui.Canvas(recorder);
    var y = 0.0;
    var page = 1;
    TextPainter text(
      String value,
      double size,
      double maxWidth, {
      bool bold = false,
    }) => TextPainter(
      text: TextSpan(
        text: value,
        style: TextStyle(
          fontFamily: kannada ? 'NotoSansKannada' : 'Inter',
          fontFamilyFallback: const ['NotoSansKannada', 'Inter'],
          fontSize: size,
          height: 1.45,
          fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
          color: const Color(0xff152c25),
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 8,
      ellipsis: '…',
    )..layout(maxWidth: maxWidth);
    void begin() {
      canvas.scale(2);
      canvas.drawRect(
        const ui.Rect.fromLTWH(0, 0, width, height),
        ui.Paint()..color = const ui.Color(0xffffffff),
      );
      final heading = text(title, 18, width - 2 * margin, bold: true);
      heading.paint(canvas, const ui.Offset(margin, margin));
      y = margin + heading.height + 16;
      canvas.drawLine(
        ui.Offset(margin, y),
        ui.Offset(width - margin, y),
        ui.Paint()..color = const ui.Color(0xffc5d3ca),
      );
      y += 12;
    }

    Future<void> end() async {
      if (footer.isNotEmpty) {
        final foot = text(footer, 8.5, width - 2 * margin);
        foot.paint(
          canvas,
          ui.Offset(margin, height - margin - foot.height - 16),
        );
      }
      text(
        '$page',
        9,
        30,
      ).paint(canvas, const ui.Offset(width - 45, height - 26));
      final picture = recorder.endRecording();
      final image = await picture.toImage(
        (width * 2).toInt(),
        (height * 2).toInt(),
      );
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      picture.dispose();
      document.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.zero,
          build: (_) => pw.Image(
            pw.MemoryImage(bytes!.buffer.asUint8List()),
            width: width,
            height: height,
            fit: pw.BoxFit.fill,
          ),
        ),
      );
    }

    begin();
    for (final row in rows) {
      final columns = row.length.clamp(1, 6);
      final columnWidth = (width - 2 * margin) / columns;
      final painters = [
        for (var i = 0; i < columns; i++)
          text(row[i]?.toString() ?? '', 10.5, columnWidth - 10),
      ];
      final rowHeight =
          painters.fold(0.0, (s, t) => math.max(s, t.height)) + 14;
      if (y + rowHeight > height - 140) {
        await end();
        page++;
        recorder = ui.PictureRecorder();
        canvas = ui.Canvas(recorder);
        begin();
      }
      for (var i = 0; i < painters.length; i++) {
        painters[i].paint(canvas, ui.Offset(margin + i * columnWidth, y));
      }
      y += rowHeight;
      canvas.drawLine(
        ui.Offset(margin, y - 5),
        ui.Offset(width - margin, y - 5),
        ui.Paint()..color = const ui.Color(0xffe6ece8),
      );
    }
    await end();
    final file = File(
      p.join(
        (await getTemporaryDirectory()).path,
        'dhara-mitra-${DateTime.now().microsecondsSinceEpoch}.pdf',
      ),
    );
    return file.writeAsBytes(await document.save(), flush: true);
  }

  static Future<void> share(File file, String title) => SharePlus.instance
      .share(ShareParams(files: [XFile(file.path)], subject: title));
}
