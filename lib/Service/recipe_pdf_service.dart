import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:recipe_ai/Controllers/home_controller.dart';
import 'package:recipe_ai/Model/nutrition_model.dart';
import 'package:vector_math/vector_math_64.dart' show Matrix4;

/// Builds a professionally designed, print-ready recipe PDF that mirrors the
/// Recipe Detail screen: a full-width hero image, title + meta strip, a
/// highlighted description, a nutrition summary card, checkbox ingredients
/// (grouped by section), numbered instruction cards, optional notes and a
/// footer on every page.
///
/// Built entirely with pdf-package widgets (no screenshots / HTML / WebView).
/// Long content flows onto additional A4 pages automatically because the
/// ingredient/instruction sections are top-level spanning Columns.
class RecipePdfService {
  RecipePdfService._();

  // ── Palette (mirrors AppColors) ────────────────────────────────────────────
  static const _orange = PdfColor.fromInt(0xFFF2623E);
  static const _orangeDark = PdfColor.fromInt(0xFFE0481F);
  static const _orangeSoft = PdfColor.fromInt(0xFFFDEDE8);
  static const _ink = PdfColor.fromInt(0xFF2A211B);
  static const _body = PdfColor.fromInt(0xFF4A423A);
  static const _muted = PdfColor.fromInt(0xFF8A7E70);
  static const _line = PdfColor.fromInt(0xFFEDE3D2);
  static const _cream = PdfColor.fromInt(0xFFFBF7F0);
  static const _white = PdfColor.fromInt(0xFFFFFFFF);
  static const _green = PdfColor.fromInt(0xFF1F7A5E);
  static const _blue = PdfColor.fromInt(0xFF2D6FE0);
  static const _gold = PdfColor.fromInt(0xFFC0860F);
  static const _purple = PdfColor.fromInt(0xFF7A45E0);

  // Bundled Lato faces (Latin + typographic punctuation; loaded once).
  static pw.Font? _regular, _bold, _italic;

  static Future<void> _ensureFonts() async {
    if (_regular != null) return;
    _regular = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Lato-Regular.ttf'),
    );
    _bold = pw.Font.ttf(await rootBundle.load('assets/fonts/Lato-Bold.ttf'));
    _italic = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Lato-Italic.ttf'),
    );
  }

  /// A safe, sanitized file name for the export.
  static String fileName(RecipeModel recipe) {
    final base = recipe.title.trim().isEmpty ? 'recipe' : recipe.title.trim();
    final slug = base
        .replaceAll(RegExp(r'[^A-Za-z0-9 ]'), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), '-')
        .toLowerCase();
    return '${slug.isEmpty ? 'recipe' : slug}.pdf';
  }

  static Future<Uint8List> build(
    RecipeModel recipe, {
    NutritionModel? nutrition,
    String? note,
    Uint8List? imageBytes,
  }) async {
    await _ensureFonts();
    final bytes = imageBytes ?? await _fetchImage(recipe.imageUrl);
    final image = bytes == null ? null : pw.MemoryImage(bytes);
    final dateStr = _today();

    final doc = pw.Document(
      title: recipe.title,
      author: 'Recipe AI',
      theme: pw.ThemeData.withFont(
        base: _regular,
        bold: _bold,
        italic: _italic,
      ),
    );

    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          theme: pw.ThemeData.withFont(
            base: _regular,
            bold: _bold,
            italic: _italic,
          ),
        ),
        footer: (ctx) => _footer(ctx, dateStr),
        build: (ctx) => [
          ..._header(recipe, image),
          ..._descriptionBlock(recipe),
          ..._nutritionBlock(nutrition),
          ..._ingredientsSection(recipe),
          ..._instructionsSection(recipe),
          ..._notesSection(note),
        ],
      ),
    );

    return doc.save();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PdfHeader — logo, hero image, title, meta strip
  // ═══════════════════════════════════════════════════════════════════════════

  static List<pw.Widget> _header(RecipeModel recipe, pw.MemoryImage? image) {
    return [
      _logoRow(),
      pw.SizedBox(height: 14),
      _hero(image),
      pw.SizedBox(height: 16),
      pw.Text(
        recipe.title,
        style: pw.TextStyle(
          fontSize: 25,
          fontWeight: pw.FontWeight.bold,
          color: _ink,
          lineSpacing: 1,
        ),
      ),
      if (_taxonomy(recipe) != null) ...[
        pw.SizedBox(height: 6),
        pw.Text(
          _taxonomy(recipe)!,
          style: pw.TextStyle(
            fontSize: 11,
            color: _orangeDark,
            fontWeight: pw.FontWeight.bold,
            letterSpacing: 0.3,
          ),
        ),
      ],
      pw.SizedBox(height: 14),
      _statStrip(recipe),
      if (_sourceHost(recipe.sourceUrl) != null) ...[
        pw.SizedBox(height: 12),
        pw.Row(
          children: [
            pw.Text(
              'Source:  ',
              style: const pw.TextStyle(fontSize: 10, color: _muted),
            ),
            pw.Text(
              _sourceHost(recipe.sourceUrl)!,
              style: pw.TextStyle(
                fontSize: 10,
                color: _body,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
      pw.SizedBox(height: 16),
      pw.Divider(height: 1, thickness: 1, color: _line),
      pw.SizedBox(height: 18),
    ];
  }

  static pw.Widget _logoRow() {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        _logoBadge(28),
        pw.SizedBox(width: 8),
        pw.RichText(
          text: pw.TextSpan(
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            children: const [
              pw.TextSpan(
                text: 'Recipe ',
                style: pw.TextStyle(color: _ink),
              ),
              pw.TextSpan(
                text: 'AI',
                style: pw.TextStyle(color: _orange),
              ),
            ],
          ),
        ),
        pw.Spacer(),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: pw.BoxDecoration(
            color: _orangeSoft,
            borderRadius: pw.BorderRadius.circular(20),
          ),
          child: pw.Text(
            'RECIPE CARD',
            style: pw.TextStyle(
              fontSize: 7,
              color: _orange,
              letterSpacing: 1.5,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  /// The Recipe AI brand badge — an orange rounded square with the white
  /// chef's-hat mark, redrawn from app_logo.dart's 48×48 paths (no asset).
  static pw.Widget _logoBadge(double size) {
    return pw.CustomPaint(
      size: PdfPoint(size, size),
      painter: (canvas, sz) => _paintLogo(canvas, sz.x, sz.y),
    );
  }

  static void _paintLogo(PdfGraphics c, double w, double h) {
    // Orange rounded-square background.
    c.setFillColor(_orange);
    c.drawRRect(0, 0, w, h, w * 0.32, w * 0.32);
    c.fillPath();

    // Draw the hat on the source 48×48 grid, scaled to the box. PDF space is
    // y-up while the source paths are y-down, so flip Y: translate up, scale −Y.
    final sc = w / 48.0;
    c.saveContext();
    c.setTransform(
      Matrix4.identity()
        ..translate(0.0, h)
        ..scale(sc, -sc),
    );

    const white = PdfColor.fromInt(0xFFFFFFFF);
    // Puffy top of the hat.
    c
      ..setFillColor(white)
      ..moveTo(14, 31)
      ..curveTo(7, 31, 3.5, 24.5, 8.5, 20.5)
      ..curveTo(4.5, 14.5, 11, 9.5, 16, 12.5)
      ..curveTo(17, 5, 31, 5, 32, 12.5)
      ..curveTo(37, 9.5, 43.5, 14.5, 39.5, 20.5)
      ..curveTo(44.5, 24.5, 41, 31, 34, 31)
      ..closePath()
      ..fillPath();

    // Hat band (base).
    c
      ..setFillColor(white)
      ..drawRRect(13.5, 28.5, 21, 13.5, 3.6, 3.6)
      ..fillPath();

    // Three pleats.
    c
      ..setStrokeColor(const PdfColor.fromInt(0xFFF6A98F))
      ..setLineWidth(1.7)
      ..setLineCap(PdfLineCap.round);
    for (final x in const [19.0, 24.0, 29.0]) {
      c
        ..moveTo(x, 32.5)
        ..lineTo(x, 38);
    }
    c.strokePath();

    // Sparkle.
    c
      ..setFillColor(const PdfColor.fromInt(0xFFFFE3B0))
      ..moveTo(34.5, 8.5)
      ..lineTo(35.65, 11.85)
      ..lineTo(39, 13)
      ..lineTo(35.65, 14.15)
      ..lineTo(34.5, 17.5)
      ..lineTo(33.35, 14.15)
      ..lineTo(30, 13)
      ..lineTo(33.35, 11.85)
      ..closePath()
      ..fillPath();

    c.restoreContext();
  }

  static pw.Widget _hero(pw.MemoryImage? image) {
    return pw.ClipRRect(
      horizontalRadius: 16,
      verticalRadius: 16,
      child: pw.Container(
        height: 205,
        width: double.infinity,
        color: const PdfColor.fromInt(0xFFF0E6D6),
        // fit: cover with no explicit image width/height — the image fills the
        // fixed-height, full-width box and centre-crops.
        child: image == null
            ? pw.Center(
                child: pw.Text(
                  'Recipe',
                  style: const pw.TextStyle(fontSize: 14, color: _muted),
                ),
              )
            : pw.Image(image, fit: pw.BoxFit.cover),
      ),
    );
  }

  /// Prep / Cook / Total / Serves / Level as a strip of stat cards.
  static pw.Widget _statStrip(RecipeModel recipe) {
    final cells = <pw.Widget>[];
    void add(String? value, String label, PdfColor accent) {
      if (value == null || value.trim().isEmpty) return;
      cells.add(_statCard(value.trim(), label, accent));
    }

    add(recipe.prepTime, 'PREP', _orange);
    add(recipe.cookTime, 'COOK', _orange);
    add(recipe.totalTime, 'TOTAL', _orange);
    add(_fmtNum(recipe.servingCount), 'SERVES', _green);
    add(_difficulty(recipe), 'LEVEL', _purple);

    return _grid(cells, cells.length <= 4 ? cells.length.clamp(1, 4) : 5, 8);
  }

  static pw.Widget _statCard(String value, String label, PdfColor accent) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: pw.BoxDecoration(
        color: _cream,
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: _line, width: 0.8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            value,
            maxLines: 1,
            style: pw.TextStyle(
              fontSize: 12.5,
              color: _ink,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 3),
          pw.Row(
            children: [
              pw.Container(width: 12, height: 2.5, color: accent),
              pw.SizedBox(width: 5),
              pw.Text(
                label,
                style: const pw.TextStyle(
                  fontSize: 7,
                  color: _muted,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Description — highlighted card
  // ═══════════════════════════════════════════════════════════════════════════

  static List<pw.Widget> _descriptionBlock(RecipeModel recipe) {
    final d = recipe.description?.trim() ?? '';
    if (d.isEmpty) return [];
    return [
      pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: pw.BoxDecoration(
          color: _orangeSoft,
          borderRadius: pw.BorderRadius.circular(12),
          border: pw.Border.all(
            color: const PdfColor.fromInt(0xFFF6D9CE),
            width: 0.8,
          ),
        ),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(width: 3, height: 34, color: _orange),
            pw.SizedBox(width: 12),
            pw.Expanded(
              child: pw.Text(
                d,
                style: const pw.TextStyle(
                  fontSize: 11,
                  color: _body,
                  lineSpacing: 2.5,
                ),
              ),
            ),
          ],
        ),
      ),
      pw.SizedBox(height: 20),
    ];
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PdfNutritionCard
  // ═══════════════════════════════════════════════════════════════════════════

  static List<pw.Widget> _nutritionBlock(NutritionModel? n) {
    if (n == null || n.isEmpty) return [];
    final macros = <pw.Widget>[
      _nutrientCard(_g(n.protein), 'PROTEIN', _blue),
      _nutrientCard(_g(n.carbs), 'CARBS', _gold),
      _nutrientCard(_g(n.fat), 'FAT', _orange),
      _nutrientCard(_g(n.fiber), 'FIBER', _green),
      _nutrientCard(_g(n.sugar), 'SUGAR', _purple),
      _nutrientCard(_mg(n.sodium), 'SODIUM', _muted),
    ];

    return [
      _sectionHeader(
        'NUTRITION',
        trailing: 'Estimated · per serving · serves ${n.servings}',
      ),
      pw.SizedBox(height: 10),
      // Featured calories.
      pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        margin: const pw.EdgeInsets.only(bottom: 8),
        decoration: pw.BoxDecoration(
          color: _orange,
          borderRadius: pw.BorderRadius.circular(12),
        ),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(
              'CALORIES',
              style: pw.TextStyle(
                fontSize: 10,
                color: _white,
                letterSpacing: 1.2,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.Spacer(),
            pw.Text(
              '${n.caloriesPerServing.round()}',
              style: pw.TextStyle(
                fontSize: 24,
                color: _white,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(width: 4),
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 3),
              child: pw.Text(
                'kcal',
                style: const pw.TextStyle(
                  fontSize: 11,
                  color: PdfColor.fromInt(0xFFFFE3D8),
                ),
              ),
            ),
          ],
        ),
      ),
      _grid(macros, 3, 8),
      pw.SizedBox(height: 22),
    ];
  }

  static pw.Widget _nutrientCard(String value, String label, PdfColor accent) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: pw.BoxDecoration(
        color: _cream,
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: _line, width: 0.8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 15,
              color: accent,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            label,
            style: const pw.TextStyle(
              fontSize: 7.5,
              color: _muted,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PdfIngredientSection — grouped, checkbox bullets, qty left / name right
  // ═══════════════════════════════════════════════════════════════════════════

  static List<pw.Widget> _ingredientsSection(RecipeModel recipe) {
    final groups = recipe.ingredientSections.isNotEmpty
        ? recipe.ingredientSections.map((s) => _Group(s.name, s.items)).toList()
        : [_Group(null, recipe.ingredients)];
    if (groups.every((g) => g.items.isEmpty)) return [];

    final rows = <pw.Widget>[];
    for (final g in groups) {
      if (g.items.isEmpty) continue;
      if (g.title != null && g.title!.trim().isNotEmpty) {
        rows.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 6, bottom: 6),
            child: pw.Text(
              g.title!,
              style: pw.TextStyle(
                fontSize: 11.5,
                color: _ink,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        );
      }
      for (final item in g.items) {
        rows.add(_ingredientRow(item));
      }
    }

    return [
      _sectionHeader('INGREDIENTS'),
      pw.SizedBox(height: 8),
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: rows,
      ),
      pw.SizedBox(height: 20),
    ];
  }

  static pw.Widget _ingredientRow(String text) {
    final parsed = _parseIngredient(text);
    final qty = parsed.$1;
    final name = parsed.$2;
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 6),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _line, width: 0.6)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          if (qty != null) ...[
            pw.SizedBox(
              width: 68,
              child: pw.Text(
                qty,
                style: pw.TextStyle(
                  fontSize: 11,
                  color: _orangeDark,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(width: 8),
          ],
          pw.Expanded(
            child: pw.Text(
              name,
              style: const pw.TextStyle(fontSize: 11, color: _body, lineSpacing: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PdfInstructionSection — numbered, each step in a rounded container
  // ═══════════════════════════════════════════════════════════════════════════

  static List<pw.Widget> _instructionsSection(RecipeModel recipe) {
    final groups = recipe.instructionSections.isNotEmpty
        ? recipe.instructionSections
              .map((s) => _Group(s.name, s.steps))
              .toList()
        : [_Group(null, recipe.instructions)];
    if (groups.every((g) => g.items.isEmpty)) return [];

    final children = <pw.Widget>[];
    var step = 1;
    for (final g in groups) {
      if (g.items.isEmpty) continue;
      if (g.title != null && g.title!.trim().isNotEmpty) {
        children.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 8, bottom: 8),
            child: pw.Text(
              g.title!,
              style: pw.TextStyle(
                fontSize: 11.5,
                color: _ink,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        );
      }
      for (final item in g.items) {
        children.add(_instructionCard(step++, item));
      }
    }

    return [
      _sectionHeader('INSTRUCTIONS'),
      pw.SizedBox(height: 10),
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: children,
      ),
      pw.SizedBox(height: 20),
    ];
  }

  static pw.Widget _instructionCard(int number, String text) {
    return pw.Container(
      width: double.infinity,
      margin: const pw.EdgeInsets.only(bottom: 8),
      padding: const pw.EdgeInsets.fromLTRB(12, 11, 12, 11),
      decoration: pw.BoxDecoration(
        color: _cream,
        borderRadius: pw.BorderRadius.circular(11),
        border: pw.Border.all(color: _line, width: 0.8),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 24,
            height: 24,
            decoration: pw.BoxDecoration(
              color: _orange,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            alignment: pw.Alignment.center,
            child: pw.Text(
              '$number',
              style: pw.TextStyle(
                fontSize: 12,
                color: _white,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.SizedBox(width: 12),
          pw.Expanded(
            child: pw.Padding(
              padding: const pw.EdgeInsets.only(top: 4),
              child: pw.Text(
                text,
                style: const pw.TextStyle(
                  fontSize: 11,
                  color: _body,
                  lineSpacing: 2.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Notes (only when a note was captured on the recipe screen)
  // ═══════════════════════════════════════════════════════════════════════════

  static List<pw.Widget> _notesSection(String? note) {
    final n = note?.trim() ?? '';
    if (n.isEmpty) return [];
    return [
      _sectionHeader('NOTES'),
      pw.SizedBox(height: 8),
      pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: pw.BoxDecoration(
          color: const PdfColor.fromInt(0xFFFFF8E9),
          borderRadius: pw.BorderRadius.circular(11),
          border: pw.Border.all(
            color: const PdfColor.fromInt(0xFFF1E4C3),
            width: 0.8,
          ),
        ),
        child: pw.Text(
          n,
          style: const pw.TextStyle(fontSize: 11, color: _body, lineSpacing: 2.5),
        ),
      ),
      pw.SizedBox(height: 20),
    ];
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PdfFooter
  // ═══════════════════════════════════════════════════════════════════════════

  static pw.Widget _footer(pw.Context ctx, String dateStr) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 10),
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: _line, width: 0.7)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.RichText(
            text: pw.TextSpan(
              style: const pw.TextStyle(fontSize: 8.5, color: _muted),
              children: [
                const pw.TextSpan(text: 'Generated by '),
                pw.TextSpan(
                  text: 'Recipe AI',
                  style: pw.TextStyle(
                    color: _orange,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.TextSpan(text: '  ·  $dateStr'),
              ],
            ),
          ),
          pw.Text(
            'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
            style: const pw.TextStyle(fontSize: 8.5, color: _muted),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Shared helpers
  // ═══════════════════════════════════════════════════════════════════════════

  static pw.Widget _sectionHeader(String title, {String? trailing}) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Container(width: 18, height: 3, color: _orange),
        pw.SizedBox(width: 9),
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 13,
            color: _ink,
            fontWeight: pw.FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        if (trailing != null) ...[
          pw.Spacer(),
          pw.Text(trailing, style: const pw.TextStyle(fontSize: 8.5, color: _muted)),
        ],
      ],
    );
  }

  /// Lays [cells] out in rows of [perRow] equal-width, equal-height cards.
  static pw.Widget _grid(List<pw.Widget> cells, int perRow, double gap) {
    if (cells.isEmpty) return pw.SizedBox();
    perRow = perRow < 1 ? 1 : perRow;
    final rows = <pw.Widget>[];
    for (var i = 0; i < cells.length; i += perRow) {
      final children = <pw.Widget>[];
      for (var j = 0; j < perRow; j++) {
        if (j > 0) children.add(pw.SizedBox(width: gap));
        final idx = i + j;
        children.add(
          pw.Expanded(child: idx < cells.length ? cells[idx] : pw.SizedBox()),
        );
      }
      if (rows.isNotEmpty) rows.add(pw.SizedBox(height: gap));
      rows.add(
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: children,
        ),
      );
    }
    return pw.Column(children: rows);
  }

  static Future<Uint8List?> _fetchImage(String? url) async {
    if (url == null || !url.startsWith('http')) return null;
    try {
      final res = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 12));
      if (res.statusCode == 200 && res.bodyBytes.isNotEmpty) {
        return res.bodyBytes;
      }
    } catch (_) {}
    return null;
  }

  // "Cuisine • Category" line (whichever are present).
  static String? _taxonomy(RecipeModel r) {
    final parts = <String>[
      if ((r.cuisine ?? '').trim().isNotEmpty) r.cuisine!.trim(),
      if ((r.category ?? '').trim().isNotEmpty) r.category!.trim(),
    ];
    return parts.isEmpty ? null : parts.join('  •  ');
  }

  static String? _firstNonEmpty(List<String?> values) {
    for (final v in values) {
      if (v != null && v.trim().isNotEmpty) return v.trim();
    }
    return null;
  }

  /// Mirrors the detail screen's Easy/Medium/Hard estimate.
  static String _difficulty(RecipeModel r) {
    final ingredients = r.ingredients.length;
    final steps = r.instructions.length;
    final mins = _totalMinutes(r);
    var score = 0;
    if (ingredients >= 13) {
      score += 2;
    } else if (ingredients >= 8) {
      score += 1;
    }
    if (steps >= 11) {
      score += 2;
    } else if (steps >= 6) {
      score += 1;
    }
    if (mins >= 90) {
      score += 2;
    } else if (mins >= 45) {
      score += 1;
    }
    if (score >= 4) return 'hard'.tr;
    if (score >= 2) return 'medium'.tr;
    return 'easy'.tr;
  }

  static int _totalMinutes(RecipeModel r) {
    final t = _firstNonEmpty([r.totalTime, r.cookTime, r.prepTime]);
    if (t == null) return 0;
    final hourMatch = RegExp(r'(\d+)\s*h', caseSensitive: false).firstMatch(t);
    final minMatch = RegExp(r'(\d+)\s*m', caseSensitive: false).firstMatch(t);
    var total = 0;
    if (hourMatch != null) {
      total += (int.tryParse(hourMatch.group(1)!) ?? 0) * 60;
    }
    if (minMatch != null) total += int.tryParse(minMatch.group(1)!) ?? 0;
    if (total == 0) {
      final bare = RegExp(r'\d+').firstMatch(t);
      if (bare != null) total = int.tryParse(bare.group(0)!) ?? 0;
    }
    return total;
  }

  /// Splits a leading quantity/unit off an ingredient line (mirrors the screen).
  static (String?, String) _parseIngredient(String text) {
    final match = RegExp(
      r'^([\d½¼¾⅓⅔⅛⅜⅝⅞/.\s]+(?:\s*(?:cup|cups|tbsp|tsp|oz|lb|lbs|g|kg|ml|l|piece|pieces|clove|cloves|inch|pinch|bunch|handful|can|cans|packet|packets|slice|slices|medium|large|small)\b)?)\s+(.*)$',
      caseSensitive: false,
    ).firstMatch(text);
    if (match != null) {
      final qty = match.group(1)!.trim();
      final rest = match.group(2)!.trim();
      if (qty.isNotEmpty && rest.isNotEmpty) return (qty, rest);
    }
    final simple = RegExp(r'^([\d½¼¾⅓⅔⅛/.\s]+)\s+(.*)$').firstMatch(text);
    if (simple != null) {
      final qty = simple.group(1)!.trim();
      final rest = simple.group(2)!.trim();
      if (qty.isNotEmpty && rest.isNotEmpty) return (qty, rest);
    }
    return (null, text);
  }

  static String? _sourceHost(String url) {
    if (url.isEmpty || !url.startsWith('http')) return null;
    if (url.contains('gemini_image') || url.contains('recipe_name')) {
      return null;
    }
    try {
      return Uri.parse(url).host.replaceFirst('www.', '');
    } catch (_) {
      return null;
    }
  }

  static String _g(double v) => '${_fmtNum(v)} g';
  static String _mg(double v) => '${v.round()} mg';

  static String _fmtNum(double n) =>
      n == n.roundToDouble() ? n.round().toString() : n.toStringAsFixed(1);

  static String _today() {
    final d = DateTime.now();
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}

class _Group {
  final String? title;
  final List<String> items;
  _Group(this.title, this.items);
}
