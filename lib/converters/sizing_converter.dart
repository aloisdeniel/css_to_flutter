import 'package:csslib/visitor.dart';

import 'converter.dart';

/// Converts CSS sizing properties (width, height, min/max variants) to Flutter.
class SizingConverter extends CssPropertyConverter {
  @override
  Set<String> get supportedProperties => {
        'width',
        'height',
        'min-width',
        'min-height',
        'max-width',
        'max-height',
      };

  @override
  ConversionResult convert(Declaration declaration) {
    final property = getPropertyName(declaration);
    final value = _extractValue(declaration);

    if (value == null) {
      return ConversionResult.unsupported(property);
    }

    final dartCode = switch (property) {
      'width' => 'width: $value',
      'height' => 'height: $value',
      'min-width' => 'constraints: BoxConstraints(minWidth: $value)',
      'min-height' => 'constraints: BoxConstraints(minHeight: $value)',
      'max-width' => 'constraints: BoxConstraints(maxWidth: $value)',
      'max-height' => 'constraints: BoxConstraints(maxHeight: $value)',
      _ => null,
    };

    if (dartCode == null) return ConversionResult.unsupported(property);
    return ConversionResult(property: property, dartCode: dartCode);
  }

  String? _extractValue(Declaration declaration) {
    final expr = declaration.expression;
    if (expr is Expressions && expr.expressions.isNotEmpty) {
      return _termToValue(expr.expressions.first);
    }
    if (expr is LiteralTerm) {
      return _termToValue(expr);
    }
    return null;
  }

  String? _termToValue(dynamic term) {
    if (term is LengthTerm) return _convertLength(term);
    if (term is PercentageTerm) {
      return '/* ${term.text}% - use MediaQuery or LayoutBuilder */';
    }
    if (term is LiteralTerm) {
      if (term.text == 'auto') return 'double.infinity';
      return _tryParsePixels(term.text);
    }
    return null;
  }

  String _convertLength(LengthTerm term) {
    final value = double.tryParse(term.text) ?? 0;
    return value.toString();
  }

  String? _tryParsePixels(String text) {
    final numValue = double.tryParse(text.replaceAll('px', ''));
    if (numValue != null) return numValue.toString();
    return null;
  }
}
