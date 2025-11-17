import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_caller/features/call_tracking/presentation/bloc/call_bloc.dart';
import 'package:my_caller/features/call_tracking/presentation/screens/call_history_screen.dart';
import 'package:my_caller/features/call_tracking/presentation/screens/dialpad_screen.dart';
import 'package:phone_state/phone_state.dart';
import 'package:url_launcher/url_launcher.dart';

class MainDashboardScreen extends StatelessWidget {
  const MainDashboardScreen({super.key});

  // --- (دالة فتح واتساب المعدلة) ---
  void _launchWhatsApp(BuildContext context, ActiveCallInfo callInfo) {
    final colorScheme = Theme.of(context).colorScheme;

    // الرقم الثابت الذي طلبت إرسال الرسالة إليه (يجب إضافة كود الدولة +2)
    const String targetNumber = "+201091532698";

    // بيانات المتصل
    final String callerNumber = callInfo.phoneState.number ?? "Unknown Number";
    final String callerName = callInfo.contactName ?? "No Name Saved";

    // تجهيز الرسالة
    final String message =
        "Incoming call detected:\nName: $callerName\nNumber: $callerNumber";
    // تحويل الرسالة لـ URL-safe
    final String encodedMessage = Uri.encodeComponent(message);

    final Uri whatsappUrl = Uri.parse(
      "https://wa.me/$targetNumber?text=$encodedMessage",
    );

    // (الإصلاح) لا نستخدم (await canLaunchUrl)
    // نحن نطلق الرابط ونثق أنه سيعمل، ونعالج الخطأ إذا حدث
    launchUrl(whatsappUrl, mode: LaunchMode.externalApplication).catchError((
      e,
    ) {
      // إذا فشل، أظهر خطأ
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not open WhatsApp. Make sure it is installed.',
            style: TextStyle(color: colorScheme.onErrorContainer),
          ),
          backgroundColor: colorScheme.errorContainer,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    });
  }
  // --- (نهاية الإصلاح) ---

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/my_caller_logo.png', height: 28, width: 28),
            const SizedBox(width: 8),
            const Text('My Caller'),
          ],
        ),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        surfaceTintColor: colorScheme.surface,
        centerTitle: true,
        automaticallyImplyLeading:
            false, // (إضافة): منع زر الرجوع في الشاشة الرئيسية
      ),
      backgroundColor: colorScheme.surface,

      body: BlocBuilder<CallBloc, CallState>(
        builder: (context, state) {
          ActiveCallInfo? activeCall;
          if (state is CallHistoryLoaded &&
              state.activeCallInfo?.phoneState.status ==
                  PhoneStateStatus.CALL_INCOMING) {
            activeCall = state.activeCallInfo;
          }

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // (بطاقة الترحيب - كما هي)
              Card(
                color: colorScheme.primaryContainer,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.shield_moon_outlined,
                        size: 40,
                        color: colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome!',
                              style: Theme.of(
                                context,
                              ).textTheme.titleLarge?.copyWith(
                                color: colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Your personal call assistant.',
                              style: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onPrimaryContainer
                                    .withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Quick Actions',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),

              // (بطاقة سجل المكالمات - كما هي)
              _buildDashboardCard(
                context: context,
                icon: Icons.history,
                iconColor: colorScheme.primary,
                label: 'Call History',
                subtitle: 'View your recent calls',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CallHistoryScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // (بطاقة لوحة الاتصال - كما هي)
              _buildDashboardCard(
                context: context,
                icon: Icons.phone_outlined,
                iconColor: Colors.green.shade700,
                label: 'Dialer',
                subtitle: 'Open the phone dialer',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DialpadScreen(),
                    ),
                  );
                },
              ),

              // (زر الواتساب المتحرك)
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child:
                    activeCall != null
                        ? _buildWhatsAppButton(
                          context,
                          activeCall,
                        ) // (إظهار الزر)
                        : const SizedBox.shrink(), // (إخفاء الزر)
              ),
            ],
          );
        },
      ),
    );
  }

  // (ودجت بناء زر الواتساب)
  Widget _buildWhatsAppButton(BuildContext context, ActiveCallInfo callInfo) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0),
      child: ElevatedButton.icon(
        icon: const Icon(Icons.send_to_mobile_rounded),
        label: const Text('Forward Call to WhatsApp'),
        onPressed: () => _launchWhatsApp(context, callInfo),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.teal.shade700, // لون شبيه بالواتساب
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  // (دالة بناء البطاقة كما هي)
  Widget _buildDashboardCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: iconColor.withOpacity(0.1),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
