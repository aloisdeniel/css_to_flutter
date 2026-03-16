import 'package:csslib/visitor.dart';

import 'converter.dart';

/// Converts CSS gradient properties to Flutter LinearGradient/RadialGradient/SweepGradient.
///
/// Supports:
/// - `linear-gradient(direction, color-stop, ...)`
/// - `radial-gradient(shape, color-stop, ...)`
/// - `conic-gradient(from angle at x y, color-stop, ...)` -> SweepGradient
/// - `repeating-linear-gradient(...)` / `repeating-radial-gradient(...)`
/// - Multiple stacked gradients (outputs a list)
class GradientConverter extends CssPropertyConverter {
  @override
  Set<String> get supportedProperties => {
        'background',
        'background-image',
      };

  @override
  bool canConvert(String property) => supportedProperties.contains(property);

  @override
  ConversionResult convert(Declaration declaration) {
    final property = getPropertyName(declaration);
    final text = getCssValueText(declaration);

    if (!_isGradient(text)) {
      return ConversionResult.unsupported(property);
    }

    // Split multiple stacked gradients at top-level commas
    final gradientTexts = _splitTopLevelGradients(text);
    final converted = <String>[];

    for (final g in gradientTexts) {
      final result = _convertSingleGradient(g.trim());
      if (result != null) converted.add(result);
    }

    if (converted.isEmpty) return ConversionResult.unsupported(property);

    if (converted.length == 1) {
      return ConversionResult(
        property: property,
        dartCode: 'gradient: ${converted.first}',
      );
    }

    // Multiple gradients — output as a comment + list
    final buffer = StringBuffer('// Multiple stacked gradients (render with ShaderMask or Stack)\n');
    for (var i = 0; i < converted.length; i++) {
      buffer.write('// [${i + 1}] ${converted[i]}');
      if (i < converted.length - 1) buffer.write(',');
      buffer.writeln();
    }
    return ConversionResult(
      property: property,
      dartCode: buffer.toString().trimRight(),
    );
  }

  bool _isGradient(String text) {
    final lower = text.toLowerCase();
    return lower.contains('linear-gradient') ||
        lower.contains('radial-gradient') ||
        lower.contains('conic-gradient');
  }

  /// Split stacked gradients. Top-level commas separate gradients,
  /// but commas inside function calls (rgba, etc.) must be preserved.
  List<String> _splitTopLevelGradients(String text) {
    final results = <String>[];
    var depth = 0;
    var start = 0;

    for (var i = 0; i < text.length; i++) {
      if (text[i] == '(') depth++;
      if (text[i] == ')') depth--;
      if (text[i] == ',' && depth == 0) {
        final segment = text.substring(start, i).trim();
        // Only split if next segment starts a new gradient function
        final rest = text.substring(i + 1).trim().toLowerCase();
        if (_startsWithGradient(rest)) {
          results.add(segment);
          start = i + 1;
        }
      }
    }
    results.add(text.substring(start).trim());
    return results.where((s) => s.isNotEmpty).toList();
  }

  bool _startsWithGradient(String text) {
    return text.startsWith('linear-gradient') ||
        text.startsWith('radial-gradient') ||
        text.startsWith('conic-gradient') ||
        text.startsWith('repeating-linear-gradient') ||
        text.startsWith('repeating-radial-gradient') ||
        text.startsWith('repeating-conic-gradient');
  }

  String? _convertSingleGradient(String text) {
    final lower = text.toLowerCase().trim();

    if (lower.startsWith('repeating-linear-gradient')) {
      return _convertLinearGradient(text, repeating: true);
    }
    if (lower.startsWith('linear-gradient')) {
      return _convertLinearGradient(text);
    }
    if (lower.startsWith('repeating-radial-gradient')) {
      return _convertRadialGradient(text, repeating: true);
    }
    if (lower.startsWith('radial-gradient')) {
      return _convertRadialGradient(text);
    }
    if (lower.startsWith('repeating-conic-gradient') ||
        lower.startsWith('conic-gradient')) {
      return _convertConicGradient(text);
    }

    return null;
  }

  /// Parse the arguments inside the outermost parentheses of a gradient function.
  String _extractFunctionArgs(String text) {
    final openParen = text.indexOf('(');
    // Find the matching closing paren (not just the last one)
    var depth = 0;
    for (var i = openParen; i < text.length; i++) {
      if (text[i] == '(') depth++;
      if (text[i] == ')') {
        depth--;
        if (depth == 0) return text.substring(openParen + 1, i).trim();
      }
    }
    return '';
  }

  /// Split top-level comma-separated arguments, respecting nested parentheses.
  List<String> _splitArgs(String args) {
    final result = <String>[];
    var depth = 0;
    var start = 0;
    for (var i = 0; i < args.length; i++) {
      if (args[i] == '(') depth++;
      if (args[i] == ')') depth--;
      if (args[i] == ',' && depth == 0) {
        result.add(args.substring(start, i).trim());
        start = i + 1;
      }
    }
    result.add(args.substring(start).trim());
    return result.where((s) => s.isNotEmpty).toList();
  }

  String? _convertLinearGradient(String text, {bool repeating = false}) {
    final args = _splitArgs(_extractFunctionArgs(text));
    if (args.isEmpty) return null;

    String? beginAlign;
    String? endAlign;
    List<String> colorStopArgs;

    final direction = _parseDirection(args.first);
    if (direction != null) {
      beginAlign = direction.$1;
      endAlign = direction.$2;
      colorStopArgs = args.sublist(1);
    } else {
      beginAlign = 'Alignment.topCenter';
      endAlign = 'Alignment.bottomCenter';
      colorStopArgs = args;
    }

    final colorStops = _parseColorStops(colorStopArgs);
    if (colorStops.colors.isEmpty) return null;

    final parts = <String>[
      'begin: $beginAlign',
      'end: $endAlign',
      'colors: [${colorStops.colors.join(', ')}]',
      if (colorStops.stops.isNotEmpty)
        'stops: [${colorStops.stops.join(', ')}]',
      if (repeating) 'tileMode: TileMode.repeated',
    ];
    return 'LinearGradient(${parts.join(', ')})';
  }

  String? _convertRadialGradient(String text, {bool repeating = false}) {
    final args = _splitArgs(_extractFunctionArgs(text));
    if (args.isEmpty) return null;

    List<String> colorStopArgs;

    final first = args.first.toLowerCase().trim();
    if (_isRadialShapeKeyword(first)) {
      colorStopArgs = args.sublist(1);
    } else {
      colorStopArgs = args;
    }

    final colorStops = _parseColorStops(colorStopArgs);
    if (colorStops.colors.isEmpty) return null;

    final parts = <String>[
      'colors: [${colorStops.colors.join(', ')}]',
      if (colorStops.stops.isNotEmpty)
        'stops: [${colorStops.stops.join(', ')}]',
      if (repeating) 'tileMode: TileMode.repeated',
    ];
    return 'RadialGradient(${parts.join(', ')})';
  }

  String? _convertConicGradient(String text) {
    final args = _splitArgs(_extractFunctionArgs(text));
    if (args.isEmpty) return null;

    List<String> colorStopArgs;
    String? startAngle;
    String? centerX;
    String? centerY;

    // Parse "from <angle> at <x> <y>" prefix
    final first = args.first.toLowerCase().trim();
    if (first.startsWith('from ')) {
      final config = first.replaceFirst('from ', '').trim();
      final atIndex = config.indexOf(' at ');
      if (atIndex != -1) {
        final anglePart = config.substring(0, atIndex).trim();
        final positionPart = config.substring(atIndex + 4).trim();
        startAngle = _parseAngle(anglePart);
        final posParts = positionPart.split(RegExp(r'\s+'));
        if (posParts.length >= 2) {
          centerX = _parsePercentToAlignment(posParts[0]);
          centerY = _parsePercentToAlignment(posParts[1]);
        }
      } else {
        startAngle = _parseAngle(config);
      }
      colorStopArgs = args.sublist(1);
    } else {
      colorStopArgs = args;
    }

    final colorStops = _parseColorStops(colorStopArgs, allowDegStops: true);
    if (colorStops.colors.isEmpty) return null;

    final parts = <String>[
      if (startAngle != null) 'startAngle: $startAngle',
      if (centerX != null && centerY != null)
        'center: Alignment($centerX, $centerY)',
      'colors: [${colorStops.colors.join(', ')}]',
      if (colorStops.stops.isNotEmpty)
        'stops: [${colorStops.stops.join(', ')}]',
    ];
    return 'SweepGradient(${parts.join(', ')})';
  }

  /// Convert a percentage like "50.82%" to an Alignment value (-1 to 1).
  String? _parsePercentToAlignment(String text) {
    if (!text.endsWith('%')) return null;
    final value = double.tryParse(text.replaceAll('%', ''));
    if (value == null) return null;
    // 0% = -1.0, 50% = 0.0, 100% = 1.0
    return ((value / 50) - 1).toStringAsFixed(2);
  }

  /// Parse a CSS direction into Flutter Alignment begin/end.
  (String, String)? _parseDirection(String arg) {
    final lower = arg.toLowerCase().trim();

    if (lower.startsWith('to ')) {
      final target = lower.substring(3).trim();
      return switch (target) {
        'top' => ('Alignment.bottomCenter', 'Alignment.topCenter'),
        'bottom' => ('Alignment.topCenter', 'Alignment.bottomCenter'),
        'left' => ('Alignment.centerRight', 'Alignment.centerLeft'),
        'right' => ('Alignment.centerLeft', 'Alignment.centerRight'),
        'top left' => ('Alignment.bottomRight', 'Alignment.topLeft'),
        'top right' => ('Alignment.bottomLeft', 'Alignment.topRight'),
        'bottom left' => ('Alignment.topRight', 'Alignment.bottomLeft'),
        'bottom right' => ('Alignment.topLeft', 'Alignment.bottomRight'),
        _ => null,
      };
    }

    final angle = _parseAngleDeg(lower);
    if (angle != null) {
      return _angleToAlignments(angle);
    }

    return null;
  }

  double? _parseAngleDeg(String text) {
    final lower = text.trim().toLowerCase();
    if (lower.endsWith('deg')) {
      return double.tryParse(lower.replaceAll('deg', ''));
    }
    if (lower.endsWith('turn')) {
      final turns = double.tryParse(lower.replaceAll('turn', ''));
      return turns != null ? turns * 360 : null;
    }
    if (lower.endsWith('rad')) {
      final rad = double.tryParse(lower.replaceAll('rad', ''));
      return rad != null ? rad * 180 / 3.14159265 : null;
    }
    if (lower.endsWith('grad')) {
      final grad = double.tryParse(lower.replaceAll('grad', ''));
      return grad != null ? grad * 0.9 : null;
    }
    return null;
  }

  String? _parseAngle(String text) {
    final deg = _parseAngleDeg(text);
    if (deg == null) return null;
    final rad = deg * 3.14159265 / 180;
    return rad.toStringAsFixed(4);
  }

  (String, String) _angleToAlignments(double deg) {
    deg = deg % 360;
    if (deg < 0) deg += 360;

    return switch (deg) {
      0 => ('Alignment.bottomCenter', 'Alignment.topCenter'),
      45 => ('Alignment.bottomLeft', 'Alignment.topRight'),
      90 => ('Alignment.centerLeft', 'Alignment.centerRight'),
      135 => ('Alignment.topLeft', 'Alignment.bottomRight'),
      180 => ('Alignment.topCenter', 'Alignment.bottomCenter'),
      225 => ('Alignment.topRight', 'Alignment.bottomLeft'),
      270 => ('Alignment.centerRight', 'Alignment.centerLeft'),
      315 => ('Alignment.bottomRight', 'Alignment.topLeft'),
      _ => (
          'Alignment(${_cos(deg).toStringAsFixed(2)}, ${(-_sin(deg)).toStringAsFixed(2)})',
          'Alignment(${(-_cos(deg)).toStringAsFixed(2)}, ${_sin(deg).toStringAsFixed(2)})',
        ),
    };
  }

  double _sin(double deg) {
    const pi = 3.14159265;
    final rad = (deg - 90) * pi / 180;
    return _sinRad(rad);
  }

  double _cos(double deg) {
    const pi = 3.14159265;
    final rad = (deg - 90) * pi / 180;
    return _cosRad(rad);
  }

  double _sinRad(double x) {
    x = x % (2 * 3.14159265);
    double result = 0, term = x;
    for (int n = 1; n <= 10; n++) {
      result += term;
      term *= -x * x / ((2 * n) * (2 * n + 1));
    }
    return result;
  }

  double _cosRad(double x) => _sinRad(x + 3.14159265 / 2);

  bool _isRadialShapeKeyword(String text) {
    const keywords = {
      'circle', 'ellipse', 'closest-side',
      'closest-corner', 'farthest-side', 'farthest-corner',
    };
    return keywords.any((k) => text.contains(k));
  }

  /// Parse color stops from a list of comma-separated arguments.
  /// Each arg may be like "rgba(0, 0, 0, 0.5) 30.4%" or "#DF0747 180deg".
  _ColorStops _parseColorStops(List<String> args, {bool allowDegStops = false}) {
    final colors = <String>[];
    final stops = <String>[];
    var hasExplicitStops = false;

    for (final arg in args) {
      final parsed = _parseColorStop(arg.trim(), allowDegStops: allowDegStops);
      if (parsed == null) continue;

      colors.add(parsed.color);
      if (parsed.stop != null) {
        stops.add(parsed.stop!);
        hasExplicitStops = true;
      } else {
        stops.add('');
      }
    }

    if (hasExplicitStops && stops.length == colors.length) {
      final resolved = <String>[];
      for (var i = 0; i < stops.length; i++) {
        if (stops[i].isNotEmpty) {
          resolved.add(stops[i]);
        } else if (i == 0) {
          resolved.add('0.0');
        } else if (i == stops.length - 1) {
          resolved.add('1.0');
        } else {
          resolved.add((i / (stops.length - 1)).toStringAsFixed(2));
        }
      }
      return _ColorStops(colors, resolved);
    }

    return _ColorStops(colors, []);
  }

  /// Parse a single color stop like "rgba(0, 0, 0, 0.5) 30.4%" or "#FF0000 50%".
  _ColorStop? _parseColorStop(String text, {bool allowDegStops = false}) {
    // If it starts with a function like rgba(...), split after the closing paren
    if (text.contains('(')) {
      final closeParen = _findMatchingParen(text);
      if (closeParen == -1) return null;
      final colorPart = text.substring(0, closeParen + 1).trim();
      final rest = text.substring(closeParen + 1).trim();
      final dartColor = _colorToDart(colorPart);
      if (dartColor == null) return null;
      final stop = rest.isNotEmpty ? _parseStopPosition(rest, allowDeg: allowDegStops) : null;
      return _ColorStop(dartColor, stop);
    }

    // Simple value like "#FF0000 50%" or "red 30%"
    final parts = text.split(RegExp(r'\s+'));
    final dartColor = _colorToDart(parts.first);
    if (dartColor == null) return null;
    final stop = parts.length > 1
        ? _parseStopPosition(parts.last, allowDeg: allowDegStops)
        : null;
    return _ColorStop(dartColor, stop);
  }

  /// Find the index of the closing paren matching the first '(' in text.
  int _findMatchingParen(String text) {
    var depth = 0;
    for (var i = 0; i < text.length; i++) {
      if (text[i] == '(') depth++;
      if (text[i] == ')') {
        depth--;
        if (depth == 0) return i;
      }
    }
    return -1;
  }

  String? _parseStopPosition(String text, {bool allowDeg = false}) {
    final trimmed = text.trim();
    if (trimmed.endsWith('%')) {
      final value = double.tryParse(trimmed.replaceAll('%', ''));
      if (value != null) return (value / 100).toStringAsFixed(2);
    }
    if (allowDeg && trimmed.endsWith('deg')) {
      final value = double.tryParse(trimmed.replaceAll('deg', ''));
      if (value != null) return (value / 360).toStringAsFixed(4);
    }
    return null;
  }

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

  String? _colorToDart(String text) {
    final lower = text.toLowerCase().trim();

    // Hex color
    if (lower.startsWith('#')) {
      var hex = lower.substring(1);
      if (hex.length == 3) {
        hex = hex.split('').map((c) => '$c$c').join();
      }
      if (hex.length == 6) return 'Color(0xFF${hex.toUpperCase()})';
      if (hex.length == 8) return 'Color(0x${hex.toUpperCase()})';
    }

    // Named color
    final named = _namedColors[lower];
    if (named != null) return named;

    // rgb/rgba function
    if (lower.startsWith('rgb')) {
      final openParen = lower.indexOf('(');
      final closeParen = lower.lastIndexOf(')');
      if (openParen == -1 || closeParen == -1) return null;
      final inner = lower.substring(openParen + 1, closeParen);
      final values = inner
          .split(RegExp(r'[,/\s]+'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      if (values.length >= 3) {
        final r = values[0], g = values[1], b = values[2];
        if (values.length >= 4) {
          final a = double.tryParse(values[3]) ?? 1.0;
          final alpha = (a <= 1.0 ? a * 255 : a).round();
          return 'Color.fromARGB($alpha, $r, $g, $b)';
        }
        return 'Color.fromARGB(255, $r, $g, $b)';
      }
    }

    return null;
  }
}

class _ColorStop {
  final String color;
  final String? stop;

  _ColorStop(this.color, this.stop);
}

class _ColorStops {
  final List<String> colors;
  final List<String> stops;

  _ColorStops(this.colors, this.stops);
}
