import 'package:flutter/material.dart';
import 'package:my_caller/features/call_tracking/presentation/screens/main_dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  _navigateToHome() async {
    // الانتظار لمدة 5 ثواني
    await Future.delayed(const Duration(seconds: 5));

    if (mounted) {
      Navigator.pushReplacement(
        context,
        // 2. <-- تغيير الشاشة التي ننتقل إليها
        MaterialPageRoute(builder: (context) => const MainDashboardScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface, // استخدام لون الخلفية من السمة
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // عرض اللوجو الخاص بك
            Image.asset(
              'assets/my_caller_logo2.png', // <-- تأكد أن المسار صحيح
              width: 150,
              height: 150,
            ),
            const SizedBox(height: 24),
            Text(
              'My Caller',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary, // لون النص من السمة
              ),
            ),
            const SizedBox(height: 48),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
            ),
          ],
        ),
      ),
    );
  }
}
