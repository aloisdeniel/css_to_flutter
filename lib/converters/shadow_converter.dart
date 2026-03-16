import 'package:csslib/visitor.dart';

import 'converter.dart';

/// Converts CSS shadow properties to Flutter BoxShadow/Shadow.
class ShadowConverter extends CssPropertyConverter {
  @override
  Set<String> get supportedProperties => {
        'box-shadow',
        'text-shadow',
      };

  @override
  ConversionResult convert(Declaration declaration) {
    final property = getPropertyName(declaration);
    final text = getExpressionText(declaration);

    if (text.toLowerCase() == 'none') {
      return ConversionResult(property: property, dartCode: '// No shadow');
    }

    final parts = text.split(RegExp(r'\s+'));
    final numbers = <double>[];
    for (final part in parts) {
      final v = double.tryParse(part.replaceAll('px', ''));
      if (v != null) numbers.add(v);
    }

    if (property == 'box-shadow') {
      final offsetX = numbers.isNotEmpty ? numbers[0] : 0;
      final offsetY = numbers.length > 1 ? numbers[1] : 0;
      final blur = numbers.length > 2 ? numbers[2] : 0;
      final spread = numbers.length > 3 ? numbers[3] : 0;

      return ConversionResult(
        property: property,
        dartCode:
            'boxShadow: [BoxShadow(offset: Offset($offsetX, $offsetY), blurRadius: $blur, spreadRadius: $spread)]',
      );
    }

    if (property == 'text-shadow') {
      final offsetX = numbers.isNotEmpty ? numbers[0] : 0;
      final offsetY = numbers.length > 1 ? numbers[1] : 0;
      final blur = numbers.length > 2 ? numbers[2] : 0;

      return ConversionResult(
        property: property,
        dartCode:
            'Shadow(offset: Offset($offsetX, $offsetY), blurRadius: $blur)',
      );
    }

    return ConversionResult.unsupported(property);
  }
}
