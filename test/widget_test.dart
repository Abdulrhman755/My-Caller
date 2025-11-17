import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// 1. استيراد الملفات المطلوبة للاختبار
import 'package:my_caller/main.dart'; // استيراد MyApp
import 'package:my_caller/features/call_tracking/presentation/bloc/call_bloc.dart';
import 'package:my_caller/features/call_tracking/domain/repositories/call_repository.dart';
import 'package:my_caller/features/call_tracking/domain/repositories/local_contacts_repository.dart';
import 'package:my_caller/features/call_tracking/domain/entities/call_log_entry.dart';

// 2. إنشاء "Repository وهمي" (Mock) لسجل المكالمات
class MockCallRepository implements CallRepository {
  @override
  Future<List<CallLogEntry>> getCallLogs() async {
    // إرجاع قائمة فارغة للاختبار
    return [];
  }

  @override
  Stream<String> listenToIncomingCalls() {
    // إرجاع Stream فارغ
    return Stream.empty();
  }
}

// 3. إنشاء "Repository وهمي" (Mock) لجهات الاتصال
class MockLocalContactsRepository implements LocalContactsRepository {
  @override
  Future<String?> getNameForNumber(String number) async {
    return null;
  }

  @override
  Future<void> saveContact(String number, String name) async {
    // لا تفعل شيئاً
  }
}

void main() {
  // 4. نقوم بإنشاء الـ Mocks والـ Bloc قبل الاختبار
  late MockCallRepository mockCallRepository;
  late MockLocalContactsRepository mockLocalContactsRepository;
  late CallBloc callBloc;

  // (setUp) يتم تشغيله قبل كل اختبار
  setUp(() {
    mockCallRepository = MockCallRepository();
    mockLocalContactsRepository = MockLocalContactsRepository();
    callBloc = CallBloc(
      callRepository: mockCallRepository,
      localContactsRepository: mockLocalContactsRepository,
    );
  });

  // (tearDown) يتم تشغيله بعد كل اختبار
  tearDown(() {
    callBloc.close(); // إغلاق الـ BLoC
  });

  testWidgets('App loads SplashScreen and navigates to MainDashboardScreen',
      (WidgetTester tester) async {
        
    // 5. تشغيل التطبيق وتمرير الـ BLoC الوهمي
    // (هذا سيحل أخطاء الـ compilation)
    await tester.pumpWidget(MyApp(callBloc: callBloc));

    // 6. في البداية، نتوقع رؤية شاشة البداية (SplashScreen)
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('My Caller'), findsOneWidget);

    // 7. ننتظر 5 ثواني (مدة الـ Splash) + ثانية احتياطية
    await tester.pumpAndSettle(const Duration(seconds: 6));

    // 8. الآن نتوقع رؤية الشاشة الرئيسية (MainDashboardScreen)
    expect(find.text('Welcome!'), findsOneWidget);
    expect(find.text('Call History'), findsOneWidget);
  });
}