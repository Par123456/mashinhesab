import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:math_expressions/math_expressions.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:window_manager/window_manager.dart';
import 'package:auto_size_text/auto_size_text.dart';

// --- تنظیمات گیت‌هاب خود را اینجا وارد کنید ---
const String githubOwner = "Par123456"; // نام کاربری گیت‌هاب شما
const String githubRepo = "mashinhesab";       // نام ریپازیتوری شما
// ---------------------------------------------

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // تنظیمات اولیه پنجره ویندوز
  await windowManager.ensureInitialized();

  // تنظیمات پنجره قبل از نمایش برنامه برای جلوگیری از پرش سایز (Flickering)
  const WindowOptions windowOptions = WindowOptions(
    size: Size(380, 620),
    minimumSize: Size(350, 550),
    title: "Advanced Calculator",
    center: true, // باز شدن پنجره وسط صفحه
  );

  // اعمال تنظیمات و نمایش پنجره
  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    // خط setFocus حذف شد تا خطای کامپایل در گیت‌هاب برطرف شود
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Advanced Calculator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.blueAccent,
        scaffoldBackgroundColor: const Color(0xFF1E1E1E),
        colorScheme: const ColorScheme.dark(
          primary: Colors.blueAccent,
          secondary: Colors.amber,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

// === صفحه چک کردن آپدیت اجباری ===
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String _message = "Checking for updates...";

  @override
  void initState() {
    super.initState();
    _checkVersion();
  }

  Future<void> _checkVersion() async {
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      String currentVersion = "v${packageInfo.version}"; // مثال: v1.0.1

      final response = await http.get(
        Uri.parse('https://api.github.com/repos/$githubOwner/$githubRepo/releases/latest'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String latestVersion = data['tag_name']; // مثال: v1.0.2
        
        String downloadUrl = data['html_url'];
        if (data['assets'] != null && data['assets'].isNotEmpty) {
          downloadUrl = data['assets'][0]['browser_download_url'];
        }

        // مقایسه عددی نسخه‌ها
        String cleanCurrent = currentVersion.replaceAll('v', '');
        String cleanLatest = latestVersion.replaceAll('v', '');

        List<int> currentParts = cleanCurrent.split('.').map((e) => int.tryParse(e) ?? 0).toList();
        List<int> latestParts = cleanLatest.split('.').map((e) => int.tryParse(e) ?? 0).toList();

        bool needsUpdate = false;
        for (int i = 0; i < 3; i++) {
          int c = i < currentParts.length ? currentParts[i] : 0;
          int l = i < latestParts.length ? latestParts[i] : 0;
          if (l > c) { needsUpdate = true; break; }
          if (l < c) break;
        }

        if (needsUpdate) {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => ForceUpdateScreen(
                  downloadUrl: downloadUrl,
                  latestVersion: latestVersion,
                ),
              ),
            );
          }
        } else {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const CalculatorScreen()),
            );
          }
        }
      } else {
        // در صورت عدم دسترسی به گیت‌هاب، برنامه باز شود (استفاده آفلاین)
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const CalculatorScreen()),
          );
        }
      }
    } catch (e) {
      setState(() => _message = "Connection error. Loading app offline...");
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const CalculatorScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.blueAccent),
            const SizedBox(height: 20),
            Text(_message, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}

// === صفحه آپدیت اجباری ===
class ForceUpdateScreen extends StatelessWidget {
  final String downloadUrl;
  final String latestVersion;

  const ForceUpdateScreen({
    super.key,
    required this.downloadUrl,
    required this.latestVersion,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.system_update_alt, size: 80, color: Colors.amber),
              const SizedBox(height: 24),
              const Text('Update Required', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Text(
                'A new version ($latestVersion) is available.\nYou must update to continue using the app.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                icon: const Icon(Icons.download),
                label: const Text('Download Now', style: TextStyle(fontSize: 18)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  backgroundColor: Colors.blueAccent,
                ),
                onPressed: () async {
                  final uri = Uri.parse(downloadUrl);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Could not open download link')),
                      );
                    }
                  }
                },
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => exit(0),
                child: const Text('Close App', style: TextStyle(color: Colors.white54)),
              )
            ],
          ),
        ),
      ),
    );
  }
}

// === صفحه اصلی ماشین حساب پیشرفته ===
class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String _expression = '';
  String _result = '0';
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _onButtonPressed(String value) {
    setState(() {
      if (value == 'C') {
        _expression = '';
        _result = '0';
      } else if (value == '⌫') {
        _expression = _expression.isNotEmpty ? _expression.substring(0, _expression.length - 1) : '';
      } else if (value == '=') {
        _calculateResult();
      } else {
        _expression += value;
      }
    });
  }

  void _calculateResult() {
    try {
      String exp = _expression
          .replaceAll('×', '*')
          .replaceAll('÷', '/')
          .replaceAll('π', '3.14159265359');

      // تبدیل توابع مثلثاتیتی از درجه به رادیان
      exp = exp.replaceAllMapped(RegExp(r'(sin|cos|tan)\(([^()]+)\)'), (match) {
        final func = match.group(1);
        final inner = match.group(2);
        return '$func(($inner) * 3.14159265359 / 180)';
      });

      // بستن پرانتزهای باز
      int openCount = '('.allMatches(exp).length;
      int closeCount = ')'.allMatches(exp).length;
      if (openCount > closeCount) {
        exp += ')' * (openCount - closeCount);
      }

      Parser p = Parser();
      Expression expression = p.parse(exp);
      ContextModel cm = ContextModel();
      double eval = expression.evaluate(EvaluationType.REAL, cm);

      if (eval.isFinite) {
        if ((eval - eval.roundToDouble()).abs() < 1e-10) {
          _result = eval.roundToDouble().toInt().toString();
        } else {
          _result = eval.toStringAsFixed(5);
        }
      } else {
        _result = 'Error';
      }
    } catch (e) {
      _result = 'Error';
    }
  }

  // پشتیبانی از کیبورد فیزیکی ویندوز
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      final key = event.logicalKey;
      String? buttonValue;

      if (key == LogicalKeyboardKey.digit0 || key == LogicalKeyboardKey.numpad0) buttonValue = '0';
      else if (key == LogicalKeyboardKey.digit1 || key == LogicalKeyboardKey.numpad1) buttonValue = '1';
      else if (key == LogicalKeyboardKey.digit2 || key == LogicalKeyboardKey.numpad2) buttonValue = '2';
      else if (key == LogicalKeyboardKey.digit3 || key == LogicalKeyboardKey.numpad3) buttonValue = '3';
      else if (key == LogicalKeyboardKey.digit4 || key == LogicalKeyboardKey.numpad4) buttonValue = '4';
      else if (key == LogicalKeyboardKey.digit5 || key == LogicalKeyboardKey.numpad5) buttonValue = '5';
      else if (key == LogicalKeyboardKey.digit6 || key == LogicalKeyboardKey.numpad6) buttonValue = '6';
      else if (key == LogicalKeyboardKey.digit7 || key == LogicalKeyboardKey.numpad7) buttonValue = '7';
      else if (key == LogicalKeyboardKey.digit8 || key == LogicalKeyboardKey.numpad8) buttonValue = '8';
      else if (key == LogicalKeyboardKey.digit9 || key == LogicalKeyboardKey.numpad9) buttonValue = '9';
      else if (key == LogicalKeyboardKey.numpadAdd) buttonValue = '+';
      else if (key == LogicalKeyboardKey.numpadSubtract || key == LogicalKeyboardKey.minus) buttonValue = '-';
      else if (key == LogicalKeyboardKey.numpadMultiply) buttonValue = '×';
      else if (key == LogicalKeyboardKey.numpadDivide || key == LogicalKeyboardKey.slash) buttonValue = '÷';
      else if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter) buttonValue = '=';
      else if (key == LogicalKeyboardKey.backspace) buttonValue = '⌫';
      else if (key == LogicalKeyboardKey.escape) buttonValue = 'C';
      else if (key == LogicalKeyboardKey.period || key == LogicalKeyboardKey.numpadDecimal) buttonValue = '.';
      
      if (buttonValue != null) {
        _onButtonPressed(buttonValue);
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  Widget _buildButton(String text, {Color color = Colors.grey, Color textColor = Colors.white, int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.all(6.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: textColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 22),
          ),
          onPressed: () => _onButtonPressed(text),
          child: Text(text, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w300)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Focus(
        focusNode: _focusNode,
        onKeyEvent: _handleKeyEvent,
        autofocus: true,
        child: Column(
          children: [
            // نمایشگر
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                alignment: Alignment.bottomRight,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    AutoSizeText(
                      _expression,
                      style: const TextStyle(fontSize: 28, color: Colors.white54),
                      maxLines: 1,
                      minFontSize: 12,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    AutoSizeText(
                      _result,
                      style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      minFontSize: 20,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            // کیبورد
            Container(
              padding: const EdgeInsets.only(bottom: 20, left: 10, right: 10),
              child: Column(
                children: [
                  Row(
                    children: [
                      _buildButton('sin(', color: Colors.blueGrey),
                      _buildButton('cos(', color: Colors.blueGrey),
                      _buildButton('tan(', color: Colors.blueGrey),
                      _buildButton('π', color: Colors.blueGrey),
                      _buildButton(')', color: Colors.blueGrey),
                    ],
                  ),
                  Row(
                    children: [
                      _buildButton('C', color: Colors.redAccent),
                      _buildButton('⌫', color: Colors.orangeAccent),
                      _buildButton('^', color: Colors.blueGrey),
                      _buildButton('÷', color: Colors.blueGrey),
                    ],
                  ),
                  Row(
                    children: [
                      _buildButton('7'),
                      _buildButton('8'),
                      _buildButton('9'),
                      _buildButton('×', color: Colors.blueGrey),
                    ],
                  ),
                  Row(
                    children: [
                      _buildButton('4'),
                      _buildButton('5'),
                      _buildButton('6'),
                      _buildButton('-', color: Colors.blueGrey),
                    ],
                  ),
                  Row(
                    children: [
                      _buildButton('1'),
                      _buildButton('2'),
                      _buildButton('3'),
                      _buildButton('+', color: Colors.blueGrey),
                    ],
                  ),
                  Row(
                    children: [
                      _buildButton('0', flex: 2),
                      _buildButton('.'),
                      _buildButton('=', color: Colors.blueAccent, textColor: Colors.white),
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
