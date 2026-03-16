import 'package:csslib/visitor.dart';

import 'converter.dart';

/// Converts CSS positioning properties (top, right, bottom, left, z-index)
/// to Flutter Positioned widget parameters.
class PositioningConverter extends CssPropertyConverter {
  @override
  Set<String> get supportedProperties => {
        'top',
        'right',
        'bottom',
        'left',
        'z-index',
        'inset',
      };

  @override
  ConversionResult convert(Declaration declaration) {
    final property = getPropertyName(declaration);
    final text = getExpressionText(declaration);

    final dartCode = switch (property) {
      'top' => _convertOffset('top', text),
      'right' => _convertOffset('right', text),
      'bottom' => _convertOffset('bottom', text),
      'left' => _convertOffset('left', text),
      'z-index' => _convertZIndex(text),
      'inset' => _convertInset(text),
      _ => null,
    };

    if (dartCode == null) return ConversionResult.unsupported(property);
    return ConversionResult(property: property, dartCode: dartCode);
  }

  String? _convertOffset(String side, String text) {
    if (text == 'auto') return '$side: /* auto - omit for unconstrained */';

    final value = _parseLength(text);
    if (value == null) return null;
    return '$side: $value';
  }

  String? _convertZIndex(String text) {
    final value = int.tryParse(text);
    if (value == null) return null;
    return '// z-index: $value - control with child order in Stack (last = on top)';
  }

  String? _convertInset(String text) {
    final parts = text.split(RegExp(r'\s+'));
    final values = parts.map(_parseLength).whereType<String>().toList();

    return switch (values.length) {
      1 => 'top: ${values[0]}, right: ${values[0]}, bottom: ${values[0]}, left: ${values[0]}',
      2 => 'top: ${values[0]}, right: ${values[1]}, bottom: ${values[0]}, left: ${values[1]}',
      3 => 'top: ${values[0]}, right: ${values[1]}, bottom: ${values[2]}, left: ${values[1]}',
      4 => 'top: ${values[0]}, right: ${values[1]}, bottom: ${values[2]}, left: ${values[3]}',
      _ => null,
    };
  }

  String? _parseLength(String text) {
    if (text == '0') return '0';
    final value = double.tryParse(
      text.replaceAll('px', '').replaceAll('em', '').replaceAll('rem', '').replaceAll('%', ''),
    );
    if (value == null) return null;
    if (text.endsWith('%')) return '/* $text - use fractional layout */';
    return value.toString();
  }
}
