import 'package:csslib/visitor.dart';

import 'converter.dart';

/// Converts CSS layout properties (display, flexbox) to Flutter.
class LayoutConverter extends CssPropertyConverter {
  @override
  Set<String> get supportedProperties => {
        'display',
        'flex-direction',
        'justify-content',
        'align-items',
        'align-self',
        'flex-wrap',
        'flex',
        'flex-grow',
        'flex-shrink',
        'gap',
        'row-gap',
        'column-gap',
        'overflow',
        'position',
        'opacity',
      };

  @override
  ConversionResult convert(Declaration declaration) {
    final property = getPropertyName(declaration);
    final text = getExpressionText(declaration);

    final dartCode = switch (property) {
      'display' => _convertDisplay(text),
      'flex-direction' => _convertFlexDirection(text),
      'justify-content' => _convertMainAxisAlignment(text),
      'align-items' => _convertCrossAxisAlignment(text),
      'align-self' => '/* align-self: $text - use Align widget */',
      'flex-wrap' => _convertFlexWrap(text),
      'flex' => 'flex: ${int.tryParse(text) ?? 1}',
      'flex-grow' => 'flex: ${int.tryParse(text) ?? 1}',
      'flex-shrink' => '/* flex-shrink: $text - use Flexible widget */',
      'gap' => _convertGap(text),
      'row-gap' => _convertRowGap(text),
      'column-gap' => _convertColumnGap(text),
      'overflow' => _convertOverflow(text),
      'position' => _convertPosition(text),
      'opacity' => 'opacity: ${double.tryParse(text) ?? 1.0}',
      _ => null,
    };

    if (dartCode == null) return ConversionResult.unsupported(property);
    return ConversionResult(property: property, dartCode: dartCode);
  }

  String? _convertDisplay(String text) {
    return switch (text.toLowerCase()) {
      'flex' => '// Use Row or Column',
      'block' => '// Use Container or SizedBox',
      'inline' => '// Use Wrap or Row for inline layout',
      'none' => '// Use Visibility or if-condition to hide',
      'grid' => '// Use GridView or Table',
      'inline-flex' => '// Use Row with mainAxisSize: MainAxisSize.min',
      _ => null,
    };
  }

  String? _convertFlexDirection(String text) {
    return switch (text.toLowerCase()) {
      'row' => '// Use Row widget',
      'column' => '// Use Column widget',
      'row-reverse' =>
        '// Use Row with textDirection: TextDirection.rtl',
      'column-reverse' =>
        '// Use Column with verticalDirection: VerticalDirection.up',
      _ => null,
    };
  }

  String? _convertMainAxisAlignment(String text) {
    final alignment = switch (text.toLowerCase()) {
      'flex-start' || 'start' => 'MainAxisAlignment.start',
      'flex-end' || 'end' => 'MainAxisAlignment.end',
      'center' => 'MainAxisAlignment.center',
      'space-between' => 'MainAxisAlignment.spaceBetween',
      'space-around' => 'MainAxisAlignment.spaceAround',
      'space-evenly' => 'MainAxisAlignment.spaceEvenly',
      _ => null,
    };
    return alignment != null ? 'mainAxisAlignment: $alignment' : null;
  }

  String? _convertCrossAxisAlignment(String text) {
    final alignment = switch (text.toLowerCase()) {
      'flex-start' || 'start' => 'CrossAxisAlignment.start',
      'flex-end' || 'end' => 'CrossAxisAlignment.end',
      'center' => 'CrossAxisAlignment.center',
      'stretch' => 'CrossAxisAlignment.stretch',
      'baseline' => 'CrossAxisAlignment.baseline',
      _ => null,
    };
    return alignment != null ? 'crossAxisAlignment: $alignment' : null;
  }

  String? _convertFlexWrap(String text) {
    return switch (text.toLowerCase()) {
      'wrap' => '// Use Wrap widget instead of Row/Column',
      'nowrap' => '// Default Row/Column behavior (no wrapping)',
      'wrap-reverse' => '// Use Wrap with direction and reversed',
      _ => null,
    };
  }

  String? _convertGap(String text) {
    final parts = text.split(RegExp(r'\s+'));
    final values = parts.map((p) => double.tryParse(p.replaceAll('px', ''))).toList();
    if (values.isEmpty || values.first == null) return null;
    if (values.length == 1) {
      return 'spacing: ${values[0]}';
    }
    return 'runSpacing: ${values[0]}, spacing: ${values[1]}';
  }

  String? _convertRowGap(String text) {
    final value = double.tryParse(text.replaceAll('px', ''));
    if (value == null) return null;
    return 'runSpacing: $value';
  }

  String? _convertColumnGap(String text) {
    final value = double.tryParse(text.replaceAll('px', ''));
    if (value == null) return null;
    return 'spacing: $value';
  }

  String? _convertOverflow(String text) {
    return switch (text.toLowerCase()) {
      'hidden' => 'clipBehavior: Clip.hardEdge',
      'scroll' || 'auto' => '// Wrap with SingleChildScrollView',
      'visible' => 'clipBehavior: Clip.none',
      _ => null,
    };
  }

  String? _convertPosition(String text) {
    return switch (text.toLowerCase()) {
      'relative' => '// Default Flutter behavior (relative positioning)',
      'absolute' => '// Use Positioned inside a Stack',
      'fixed' => '// Use Positioned inside a Stack at the root level',
      'sticky' => '// Use SliverAppBar with floating/pinned for sticky behavior',
      _ => null,
    };
  }
}
