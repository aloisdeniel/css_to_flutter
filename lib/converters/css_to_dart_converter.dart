import 'package:csslib/parser.dart' as css;
import 'package:csslib/visitor.dart';

import 'converter.dart';
import 'converter_registry.dart';

/// Main engine that parses CSS and converts it to Flutter/Dart code.
class CssToDartConverter {
  final ConverterRegistry _registry;

  CssToDartConverter({ConverterRegistry? registry})
      : _registry = registry ?? ConverterRegistry();

  /// Parse CSS input and return equivalent Dart code.
  String convert(String cssInput) {
    if (cssInput.trim().isEmpty) return '';

    try {
      final stylesheet = css.parse(cssInput);
      final buffer = StringBuffer();
      buffer.writeln("import 'package:flutter/material.dart';");
      buffer.writeln();
      _visitStyleSheet(stylesheet, buffer);
      return buffer.toString();
    } catch (e) {
      return '// Error parsing CSS:\n// $e';
    }
  }

  void _visitStyleSheet(StyleSheet stylesheet, StringBuffer buffer) {
    for (final node in stylesheet.topLevels) {
      if (node is RuleSet) {
        _visitRuleSet(node, buffer);
      } else if (node is MediaDirective) {
        _visitMediaDirective(node, buffer);
      } else if (node is FontFaceDirective) {
        _visitFontFaceDirective(node, buffer);
      } else if (node is KeyFrameDirective) {
        _visitKeyFrameDirective(node, buffer);
      }
    }
  }

  void _visitRuleSet(RuleSet ruleSet, StringBuffer buffer) {
    final selector = _selectorToString(ruleSet.selectorGroup);
    final declarations = ruleSet.declarationGroup.declarations
        .whereType<Declaration>()
        .toList();

    if (declarations.isEmpty) return;

    // Categorize declarations into groups
    final textStyleProps = <ConversionResult>[];
    final containerProps = <ConversionResult>[];
    final decorationProps = <ConversionResult>[];
    final layoutProps = <ConversionResult>[];
    final unsupported = <String>[];

    for (final decl in declarations) {
      String property;
      try {
        property = decl.property;
      } catch (_) {
        continue;
      }
      final converter = _registry.findConverter(property);

      if (converter == null) {
        unsupported.add(property);
        continue;
      }

      final result = converter.convert(decl);
      if (!result.supported) {
        unsupported.add(property);
        continue;
      }

      if (_isTextStyleProperty(property)) {
        textStyleProps.add(result);
      } else if (_isLayoutProperty(property)) {
        layoutProps.add(result);
      } else if (_isDecorationProperty(property)) {
        decorationProps.add(result);
      } else {
        containerProps.add(result);
      }
    }

    buffer.writeln('// --- $selector ---');
    buffer.writeln();

    if (textStyleProps.isNotEmpty) {
      buffer.writeln('// TextStyle');
      for (final prop in textStyleProps) {
        buffer.writeln('${prop.dartCode},');
      }
      buffer.writeln();
    }

    if (layoutProps.isNotEmpty) {
      buffer.writeln('// Layout');
      for (final prop in layoutProps) {
        buffer.writeln('${prop.dartCode},');
      }
      buffer.writeln();
    }

    if (containerProps.isNotEmpty) {
      buffer.writeln('// Container');
      for (final prop in containerProps) {
        buffer.writeln('${prop.dartCode},');
      }
      buffer.writeln();
    }

    if (decorationProps.isNotEmpty) {
      buffer.writeln('// BoxDecoration');
      for (final prop in decorationProps) {
        buffer.writeln('${prop.dartCode},');
      }
      buffer.writeln();
    }

    if (unsupported.isNotEmpty) {
      buffer.writeln('// Unsupported: ${unsupported.join(', ')}');
      buffer.writeln();
    }
  }

  void _visitMediaDirective(MediaDirective node, StringBuffer buffer) {
    buffer.writeln('// @media query - use MediaQuery or LayoutBuilder');
    for (final rule in node.rules) {
      if (rule is RuleSet) _visitRuleSet(rule, buffer);
    }
  }

  void _visitFontFaceDirective(FontFaceDirective node, StringBuffer buffer) {
    buffer.writeln('// @font-face - register fonts in pubspec.yaml instead');
    buffer.writeln();
  }

  void _visitKeyFrameDirective(KeyFrameDirective node, StringBuffer buffer) {
    buffer.writeln(
        '// @keyframes ${node.name?.name ?? ''} - use AnimationController + Tween');
    buffer.writeln();
  }

  String _selectorToString(SelectorGroup? group) {
    if (group == null) return '';
    return group.selectors.map((s) {
      return s.simpleSelectorSequences.map((seq) {
        final selector = seq.simpleSelector;
        if (selector is ClassSelector) return '.${selector.name}';
        if (selector is IdSelector) return '#${selector.name}';
        if (selector is ElementSelector) return selector.name;
        return selector.name.toString();
      }).join('');
    }).join(', ');
  }

  bool _isTextStyleProperty(String property) {
    return {
      'font-size',
      'font-weight',
      'font-style',
      'font-family',
      'text-decoration',
      'letter-spacing',
      'word-spacing',
      'line-height',
      'color',
    }.contains(property);
  }

  bool _isLayoutProperty(String property) {
    return {
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
      'position',
    }.contains(property);
  }

  bool _isDecorationProperty(String property) {
    return {
      'background-color',
      'border',
      'border-radius',
      'border-color',
      'border-width',
      'border-style',
      'border-top-left-radius',
      'border-top-right-radius',
      'border-bottom-left-radius',
      'border-bottom-right-radius',
      'box-shadow',
      'background',
      'background-image',
    }.contains(property);
  }
}
