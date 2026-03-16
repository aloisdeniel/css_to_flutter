import 'package:csslib/visitor.dart';

import 'converter.dart';

/// Converts CSS color properties to Flutter Color/Colors.
class ColorConverter extends CssPropertyConverter {
  @override
  Set<String> get supportedProperties => {
        'color',
        'background-color',
        'border-color',
        'outline-color',
      };

  static const _namedColors = <String, String>{
    'red': 'Colors.red',
    'blue': 'Colors.blue',
    'green': 'Colors.green',
    'yellow': 'Colors.yellow',
    'orange': 'Colors.orange',
    'purple': 'Colors.purple',
    'pink': 'Colors.pink',
    'black': 'Colors.black',
    'white': 'Colors.white',
    'grey': 'Colors.grey',
    'gray': 'Colors.grey',
    'transparent': 'Colors.transparent',
    'cyan': 'Colors.cyan',
    'teal': 'Colors.teal',
    'amber': 'Colors.amber',
    'indigo': 'Colors.indigo',
    'lime': 'Colors.lime',
    'brown': 'Colors.brown',
  };

  @override
  ConversionResult convert(Declaration declaration) {
    final property = getPropertyName(declaration);
    final expr = declaration.expression;

    String? dartColor;

    if (expr is Expressions && expr.expressions.isNotEmpty) {
      dartColor = _convertExpression(expr.expressions.first);
    } else if (expr != null) {
      dartColor = _convertExpression(expr);
    }

    if (dartColor == null) {
      return ConversionResult.unsupported(property);
    }

    return ConversionResult(property: property, dartCode: dartColor);
  }

  String? _convertExpression(dynamic expr) {
    if (expr is HexColorTerm) {
      return _hexToColor(expr.text);
    }
    if (expr is LiteralTerm) {
      final named = _namedColors[expr.text.toLowerCase()];
      if (named != null) return named;
    }
    return null;
  }

  String _hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 3) {
      hex = hex.split('').map((c) => '$c$c').join();
    }
    if (hex.length == 6) {
      return 'Color(0xFF${hex.toUpperCase()})';
    }
    if (hex.length == 8) {
      return 'Color(0x${hex.toUpperCase()})';
    }
    return 'Color(0xFF${hex.toUpperCase()})';
  }
}
