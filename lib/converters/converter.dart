import 'package:csslib/visitor.dart';

/// Result of converting a CSS declaration to Flutter/Dart code.
class ConversionResult {
  final String property;
  final String dartCode;
  final bool supported;

  const ConversionResult({
    required this.property,
    required this.dartCode,
    this.supported = true,
  });

  const ConversionResult.unsupported(this.property)
      : dartCode = '',
        supported = false;
}

/// Base class for CSS property converters.
///
/// Each converter handles one or more CSS properties and produces
/// the equivalent Flutter/Dart code.
abstract class CssPropertyConverter {
  /// The CSS property names this converter handles.
  Set<String> get supportedProperties;

  /// Whether this converter can handle the given property.
  bool canConvert(String property) => supportedProperties.contains(property);

  /// Convert a CSS declaration into a Dart code snippet.
  ConversionResult convert(Declaration declaration);

  /// Extract the property name from a declaration.
  String getPropertyName(Declaration declaration) {
    try {
      return declaration.property;
    } catch (_) {
      return '';
    }
  }

  /// Extract the expression value as a string (simple, no function args).
  String getExpressionText(Declaration declaration) {
    final expr = declaration.expression;
    if (expr is Expressions) {
      return expr.expressions.map(_expressionToString).join(' ');
    }
    if (expr != null) {
      return _expressionToString(expr);
    }
    return '';
  }

  /// Extract the full CSS value text using CssPrinter,
  /// which can reconstruct function calls including their arguments.
  String getCssValueText(Declaration declaration) {
    final printer = CssPrinter();
    declaration.expression?.visit(printer);
    return printer.toString();
  }

  String _expressionToString(dynamic expr) {
    if (expr is HexColorTerm) return '#${expr.text}';
    if (expr is LiteralTerm) return expr.text;
    return expr.toString();
  }
}
