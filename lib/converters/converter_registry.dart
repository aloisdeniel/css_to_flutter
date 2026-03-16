import 'converter.dart';
import 'color_converter.dart';
import 'sizing_converter.dart';
import 'spacing_converter.dart';
import 'text_converter.dart';
import 'border_converter.dart';
import 'layout_converter.dart';
import 'shadow_converter.dart';
import 'gradient_converter.dart';

/// Registry that holds all CSS property converters.
///
/// To add support for new CSS properties, create a new [CssPropertyConverter]
/// and register it here.
class ConverterRegistry {
  final List<CssPropertyConverter> _converters = [];

  ConverterRegistry() {
    _converters.addAll([
      ColorConverter(),
      SizingConverter(),
      SpacingConverter(),
      TextConverter(),
      BorderConverter(),
      LayoutConverter(),
      ShadowConverter(),
      GradientConverter(),
    ]);
  }

  /// Register an additional converter.
  void register(CssPropertyConverter converter) {
    _converters.add(converter);
  }

  /// Find a converter for the given CSS property name.
  CssPropertyConverter? findConverter(String property) {
    for (final converter in _converters) {
      if (converter.canConvert(property)) return converter;
    }
    return null;
  }

  /// All registered converters.
  List<CssPropertyConverter> get converters =>
      List.unmodifiable(_converters);
}
