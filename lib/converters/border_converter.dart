import 'package:csslib/visitor.dart';

import 'converter.dart';
import 'color_converter.dart';

/// Converts CSS border and border-radius properties to Flutter.
class BorderConverter extends CssPropertyConverter {
  final _colorConverter = ColorConverter();

  @override
  Set<String> get supportedProperties => {
        'border',
        'border-radius',
        'border-top-left-radius',
        'border-top-right-radius',
        'border-bottom-left-radius',
        'border-bottom-right-radius',
        'border-width',
        'border-style',
        'border-color',
      };

  @override
  ConversionResult convert(Declaration declaration) {
    final property = getPropertyName(declaration);
    final text = getExpressionText(declaration);

    if (property == 'border-radius') {
      return _convertBorderRadius(property, text);
    }
    if (property.contains('radius')) {
      return _convertSingleRadius(property, text);
    }
    if (property == 'border') {
      return _convertBorderShorthand(property, declaration);
    }
    if (property == 'border-width') {
      return ConversionResult(
        property: property,
        dartCode: 'width: ${_parseLength(text) ?? text}',
      );
    }
    if (property == 'border-style') {
      return ConversionResult(
        property: property,
        dartCode: _convertBorderStyle(text),
      );
    }
    if (property == 'border-color') {
      final colorResult = _colorConverter.convert(declaration);
      if (colorResult.supported) {
        return ConversionResult(
          property: property,
          dartCode: 'color: ${colorResult.dartCode}',
        );
      }
    }

    return ConversionResult.unsupported(property);
  }

  ConversionResult _convertBorderRadius(String property, String text) {
    final value = _parseLength(text);
    if (value == null) return ConversionResult.unsupported(property);
    return ConversionResult(
      property: property,
      dartCode: 'borderRadius: BorderRadius.circular($value)',
    );
  }

  ConversionResult _convertSingleRadius(String property, String text) {
    final value = _parseLength(text);
    if (value == null) return ConversionResult.unsupported(property);

    final corner = switch (property) {
      'border-top-left-radius' => 'topLeft: Radius.circular($value)',
      'border-top-right-radius' => 'topRight: Radius.circular($value)',
      'border-bottom-left-radius' => 'bottomLeft: Radius.circular($value)',
      'border-bottom-right-radius' => 'bottomRight: Radius.circular($value)',
      _ => null,
    };

    if (corner == null) return ConversionResult.unsupported(property);
    return ConversionResult(
      property: property,
      dartCode: 'borderRadius: BorderRadius.only($corner)',
    );
  }

  ConversionResult _convertBorderShorthand(
      String property, Declaration declaration) {
    final text = getExpressionText(declaration);
    final parts = text.split(RegExp(r'\s+'));

    final width = parts.isNotEmpty ? _parseLength(parts[0]) : null;
    final style =
        parts.length > 1 ? _convertBorderStyle(parts[1]) : 'style: BorderStyle.solid';

    return ConversionResult(
      property: property,
      dartCode:
          'Border.all(${width != null ? 'width: $width, ' : ''}$style)',
    );
  }

  String _convertBorderStyle(String style) {
    return switch (style.toLowerCase()) {
      'solid' => 'style: BorderStyle.solid',
      'none' => 'style: BorderStyle.none',
      _ => '/* border-style: $style - not directly supported */',
    };
  }

  String? _parseLength(String text) {
    final value = double.tryParse(text.replaceAll('px', ''));
    return value?.toString();
  }
}
