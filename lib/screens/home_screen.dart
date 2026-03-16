import 'dart:async';

import 'package:code_forge_web/code_forge_web.dart';
import 'package:flutter/material.dart';
import 'package:re_highlight/re_highlight.dart';
import 'package:re_highlight/languages/css.dart';
import 'package:re_highlight/languages/dart.dart';
import 'package:re_highlight/styles/tokyo-night-dark.dart';

import '../converters/css_to_dart_converter.dart';

const _defaultCss = '''.container {
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  width: 300px;
  height: 200px;
  padding: 16px 24px;
  margin: 8px;
  background: linear-gradient(135deg, #1E1E2E, #313244);
  color: white;
  font-size: 16px;
  font-weight: bold;
  border-radius: 12px;
  box-shadow: 2px 4px 8px 0px;
  opacity: 0.95;
}

.title {
  font-size: 24px;
  font-weight: 700;
  color: #CDD6F4;
  text-align: center;
  letter-spacing: 1.5px;
  text-decoration: underline;
}

.hero {
  background: radial-gradient(circle, #CBA6F7, #89B4FA, #1E1E2E);
  width: 400px;
  height: 300px;
  border-radius: 16px;
}
''';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _converter = CssToDartConverter();
  late final CodeForgeWebController _cssController;
  late final CodeForgeWebController _dartController;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _cssController = CodeForgeWebController();
    _dartController = CodeForgeWebController();
    _cssController.text = _defaultCss;
    _cssController.addListener(_onCssChanged);

    // Initial conversion
    WidgetsBinding.instance.addPostFrameCallback((_) => _convertCss());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _cssController.removeListener(_onCssChanged);
    _cssController.dispose();
    _dartController.dispose();
    super.dispose();
  }

  void _onCssChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), _convertCss);
  }

  void _convertCss() {
    final result = _converter.convert(_cssController.text);
    _dartController.text = result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1B26),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16161E),
        title: const Row(
          children: [
            Icon(Icons.transform, color: Color(0xFFBB9AF7)),
            SizedBox(width: 8),
            Text(
              'CSS to Flutter',
              style: TextStyle(
                color: Color(0xFFC0CAF5),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(child: _buildPanel('CSS Input', _cssController, langCss, false)),
            const SizedBox(width: 12),
            Expanded(child: _buildPanel('Flutter / Dart Output', _dartController, langDart, true)),
          ],
        ),
      ),
    );
  }

  Widget _buildPanel(
    String title,
    CodeForgeWebController controller,
    Mode language,
    bool readOnly,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1B26),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF414868)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF16161E),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Icon(
                  readOnly ? Icons.output : Icons.edit,
                  size: 16,
                  color: readOnly
                      ? const Color(0xFF9ECE6A)
                      : const Color(0xFF7AA2F7),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFFC0CAF5),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: CodeForgeWeb(
              controller: controller,
              language: language,
              editorTheme: tokyoNightDarkTheme,
              readOnly: readOnly,
              textStyle: const TextStyle(
                fontFamily: 'JetBrains Mono, Fira Code, monospace',
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
