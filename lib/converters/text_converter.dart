import 'package:csslib/visitor.dart';

import 'converter.dart';

/// Converts CSS text/font properties to Flutter TextStyle.
class TextConverter extends CssPropertyConverter {
  @override
  Set<String> get supportedProperties => {
        'font-size',
        'font-weight',
        'font-style',
        'font-family',
        'text-align',
        'text-decoration',
        'text-transform',
        'letter-spacing',
        'word-spacing',
        'line-height',
        'text-overflow',
      };

  @override
  ConversionResult convert(Declaration declaration) {
    final property = getPropertyName(declaration);
    final text = getExpressionText(declaration);

    final dartCode = switch (property) {
      'font-size' => _convertFontSize(text),
      'font-weight' => _convertFontWeight(text),
      'font-style' => _convertFontStyle(text),
      'font-family' => "fontFamily: '${text.replaceAll("'", "").replaceAll('"', '').split(',').first.trim()}'",
      'text-align' => _convertTextAlign(text),
      'text-decoration' => _convertTextDecoration(text),
      'text-transform' =>
        '/* text-transform: $text - handle in code with .toUpperCase()/.toLowerCase() */',
      'letter-spacing' => 'letterSpacing: ${_parseLength(text)}',
      'word-spacing' => 'wordSpacing: ${_parseLength(text)}',
      'line-height' => _convertLineHeight(text),
      'text-overflow' => _convertTextOverflow(text),
      _ => null,
    };

    if (dartCode == null) return ConversionResult.unsupported(property);
    return ConversionResult(property: property, dartCode: dartCode);
  }

  String? _convertFontSize(String text) {
    final value = _parseLength(text);
    return value != null ? 'fontSize: $value' : null;
  }

  String? _convertFontWeight(String text) {
    final weight = switch (text.toLowerCase()) {
      'normal' || '400' => 'FontWeight.normal',
      'bold' || '700' => 'FontWeight.bold',
      '100' => 'FontWeight.w100',
      '200' => 'FontWeight.w200',
      '300' => 'FontWeight.w300',
      '500' => 'FontWeight.w500',
      '600' => 'FontWeight.w600',
      '800' => 'FontWeight.w800',
      '900' => 'FontWeight.w900',
      _ => null,
    };
    return weight != null ? 'fontWeight: $weight' : null;
  }

  String? _convertFontStyle(String text) {
    return switch (text.toLowerCase()) {
      'italic' => 'fontStyle: FontStyle.italic',
      'normal' => 'fontStyle: FontStyle.normal',
      _ => null,
    };
  }

  String? _convertTextAlign(String text) {
    final align = switch (text.toLowerCase()) {
      'left' => 'TextAlign.left',
      'right' => 'TextAlign.right',
      'center' => 'TextAlign.center',
      'justify' => 'TextAlign.justify',
      'start' => 'TextAlign.start',
      'end' => 'TextAlign.end',
      _ => null,
    };
    return align != null ? 'textAlign: $align' : null;
  }

  String? _convertTextDecoration(String text) {
    final decoration = switch (text.toLowerCase()) {
      'none' => 'TextDecoration.none',
      'underline' => 'TextDecoration.underline',
      'overline' => 'TextDecoration.overline',
      'line-through' => 'TextDecoration.lineThrough',
      _ => null,
    };
    return decoration != null ? 'decoration: $decoration' : null;
  }

  String? _convertLineHeight(String text) {
    final lower = text.toLowerCase().trim();

    if (lower == 'normal') return 'height: 1.2 /* normal */';

    // Percentage: line-height: 150% → 1.5
    if (lower.endsWith('%')) {
      final value = double.tryParse(lower.replaceAll('%', ''));
      if (value != null) return 'height: ${value / 100}';
      return null;
    }

    // em/rem: line-height: 1.5em → 1.5 (already a multiplier)
    if (lower.endsWith('em') || lower.endsWith('rem')) {
      final value = double.tryParse(lower.replaceAll('rem', '').replaceAll('em', ''));
      if (value != null) return 'height: $value';
      return null;
    }

    // px: line-height: 24px → needs fontSize to compute ratio, output as comment
    if (lower.endsWith('px')) {
      final value = double.tryParse(lower.replaceAll('px', ''));
      if (value != null) return 'height: ${value / 16} /* $text - assumes 16px font */';
      return null;
    }

    // Unitless: line-height: 1.5 → direct multiplier
    final value = double.tryParse(lower);
    if (value != null) return 'height: $value';

    return null;
  }

  String? _convertTextOverflow(String text) {
    return switch (text.toLowerCase()) {
      'ellipsis' => 'overflow: TextOverflow.ellipsis',
      'clip' => 'overflow: TextOverflow.clip',
      'fade' => 'overflow: TextOverflow.fade',
      _ => null,
    };
  }

  String? _parseLength(String text) {
    final value = double.tryParse(text.replaceAll('px', '').replaceAll('em', '').replaceAll('rem', ''));
    return value?.toString();
  }
}
