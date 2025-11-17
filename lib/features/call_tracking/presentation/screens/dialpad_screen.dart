import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class DialpadScreen extends StatefulWidget {
  const DialpadScreen({super.key});

  @override
  State<DialpadScreen> createState() => _DialpadScreenState();
}

class _DialpadScreenState extends State<DialpadScreen> {
  String _enteredNumber = "";
  final TextEditingController _controller = TextEditingController();

  void _onKeyPressed(String value) {
    setState(() {
      _enteredNumber += value;
      _controller.text = _enteredNumber;
    });
  }

  void _onBackspacePressed() {
    if (_enteredNumber.isNotEmpty) {
      setState(() {
        _enteredNumber = _enteredNumber.substring(0, _enteredNumber.length - 1);
        _controller.text = _enteredNumber;
      });
    }
  }

  Future<void> _onCallPressed() async {
    if (_enteredNumber.isEmpty) return;

    final Uri url = Uri(scheme: 'tel', path: _enteredNumber);

    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      // (الإصلاح) تحقق من أن الشاشة ما زالت موجودة
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            // --- (هنا هو الإصلاح) ---
            content: Text(
              'Could not make call to $_enteredNumber',
              // 1. تم نقل الـ Style هنا
              style: TextStyle(
                color: Theme.of(context).colorScheme.onErrorContainer,
                fontWeight: FontWeight.w600, // (إضافة لتمييز الخط)
              ),
            ),
            // 2. تم حذف (contentTextStyle)
            backgroundColor: Theme.of(context).colorScheme.errorContainer,
            // --- (نهاية الإصلاح) ---
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dialer'),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        centerTitle: true,
      ),
      backgroundColor: colorScheme.surface,
      body: Column(
        children: [
          // شاشة عرض الرقم
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              alignment: Alignment.center,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      readOnly: true,
                      textAlign: TextAlign.center,
                      style: Theme.of(
                        context,
                      ).textTheme.headlineLarge?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  // زر المسح (Backspace)
                  IconButton(
                    icon: Icon(
                      Icons.backspace_outlined,
                      color: colorScheme.onSurfaceVariant,
                      size: 28,
                    ),
                    onPressed: _onBackspacePressed,
                    onLongPress: () {
                      setState(() {
                        _enteredNumber = "";
                        _controller.text = "";
                      });
                    },
                  ),
                ],
              ),
            ),
          ),

          // لوحة المفاتيح
          Expanded(
            flex: 5,
            child: GridView.count(
              crossAxisCount: 3,
              childAspectRatio: 1.2,
              padding: const EdgeInsets.all(16),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                _buildKeypadButton('1', ''),
                _buildKeypadButton('2', 'ABC'),
                _buildKeypadButton('3', 'DEF'),
                _buildKeypadButton('4', 'GHI'),
                _buildKeypadButton('5', 'JKL'),
                _buildKeypadButton('6', 'MNO'),
                _buildKeypadButton('7', 'PQRS'),
                _buildKeypadButton('8', 'TUV'),
                _buildKeypadButton('9', 'WXYZ'),
                _buildKeypadButton('*', ''),
                _buildKeypadButton('0', '+'),
                _buildKeypadButton('#', ''),
              ],
            ),
          ),

          // زر الاتصال
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: FloatingActionButton.large(
              onPressed: _onCallPressed,
              backgroundColor: Colors.green.shade700,
              child: const Icon(Icons.call, color: Colors.white, size: 36),
            ),
          ),
        ],
      ),
    );
  }

  // ودجت بناء زر لوحة المفاتيح
  Widget _buildKeypadButton(String number, String? letters) {
    return InkWell(
      onTap: () => _onKeyPressed(number),
      borderRadius: BorderRadius.circular(100), // لجعل التأثير دائري
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              number,
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
            if (letters != null && letters.isNotEmpty)
              Text(
                letters,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
