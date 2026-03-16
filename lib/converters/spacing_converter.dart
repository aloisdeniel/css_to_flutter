import 'package:csslib/visitor.dart';

import 'converter.dart';

/// Converts CSS margin and padding properties to Flutter EdgeInsets.
class SpacingConverter extends CssPropertyConverter {
  @override
  Set<String> get supportedProperties => {
        'margin',
        'margin-top',
        'margin-right',
        'margin-bottom',
        'margin-left',
        'padding',
        'padding-top',
        'padding-right',
        'padding-bottom',
        'padding-left',
      };

  @override
  ConversionResult convert(Declaration declaration) {
    final property = getPropertyName(declaration);
    final expr = declaration.expression;

    if (property.contains('-')) {
      return _convertSingleSide(property, expr);
    }

    return _convertShorthand(property, expr);
  }

  ConversionResult _convertSingleSide(String property, dynamic expr) {
    final value = _extractSingleValue(expr);
    if (value == null) return ConversionResult.unsupported(property);

    final type = property.startsWith('margin') ? 'margin' : 'padding';
    final side = property.split('-').last;

    final edgeInsets = switch (side) {
      'top' => 'EdgeInsets.only(top: $value)',
      'right' => 'EdgeInsets.only(right: $value)',
      'bottom' => 'EdgeInsets.only(bottom: $value)',
      'left' => 'EdgeInsets.only(left: $value)',
      _ => null,
    };

    if (edgeInsets == null) return ConversionResult.unsupported(property);
    return ConversionResult(property: property, dartCode: '$type: $edgeInsets');
  }

  ConversionResult _convertShorthand(String property, dynamic expr) {
    final type = property == 'margin' ? 'margin' : 'padding';

    if (expr is! Expressions) {
      final value = _extractSingleValue(expr);
      if (value == null) return ConversionResult.unsupported(property);
      return ConversionResult(
        property: property,
        dartCode: '$type: EdgeInsets.all($value)',
      );
    }

    final values = expr.expressions
        .whereType<LiteralTerm>()
        .map(_parseLengthValue)
        .whereType<String>()
        .toList();

    final edgeInsets = switch (values.length) {
      1 => 'EdgeInsets.all(${values[0]})',
      2 =>
        'EdgeInsets.symmetric(vertical: ${values[0]}, horizontal: ${values[1]})',
      3 =>
        'EdgeInsets.only(top: ${values[0]}, right: ${values[1]}, bottom: ${values[2]}, left: ${values[1]})',
      4 =>
        'EdgeInsets.only(top: ${values[0]}, right: ${values[1]}, bottom: ${values[2]}, left: ${values[3]})',
      _ => null,
    };

    if (edgeInsets == null) return ConversionResult.unsupported(property);
    return ConversionResult(property: property, dartCode: '$type: $edgeInsets');
  }

  String? _extractSingleValue(dynamic expr) {
    if (expr is Expressions && expr.expressions.isNotEmpty) {
      final first = expr.expressions.first;
      if (first is LiteralTerm) return _parseLengthValue(first);
    }
    if (expr is LiteralTerm) return _parseLengthValue(expr);
    return null;
  }

  String? _parseLengthValue(LiteralTerm term) {
    if (term.text == '0') return '0';
    if (term.text == 'auto') return '0 /* auto */';
    final value = double.tryParse(term.text.replaceAll('px', ''));
    if (value != null) return value.toString();
    return null;
  }
}
