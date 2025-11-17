import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_caller/core/services/notification_service.dart'; // <-- 1. استيراد خدمة الإشعارات
import 'package:my_caller/features/call_tracking/presentation/bloc/call_bloc.dart';
import 'package:my_caller/features/call_tracking/presentation/screens/splash_screen.dart';

// (imports...)
import 'features/call_tracking/data/datasources/native_call_datasource.dart';
import 'features/call_tracking/data/repositories/call_repository_impl.dart';
import 'features/call_tracking/domain/repositories/call_repository.dart';
import 'features/call_tracking/data/datasources/local_database_datasource.dart';
import 'features/call_tracking/data/repositories/local_contacts_repository_impl.dart';
import 'features/call_tracking/domain/repositories/local_contacts_repository.dart';
import 'package:phone_state/phone_state.dart';

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();


// 2. <-- جعل الدالة (async)
void main() async {
  // 3. <-- التأكد من تهيئة كل شيء (Flutter + Services)
  WidgetsFlutterBinding.ensureInitialized();
  // 4. <-- تهيئة خدمة الإشعارات قبل تشغيل التطبيق
  await NotificationService.instance.init();

  // (باقي الـ DI كما هو)
  final DatabaseService databaseService = DatabaseService.instance;
  final NativeCallDataSource nativeDataSource = NativeCallDataSourceImpl();
  final CallRepository callRepository =
      CallRepositoryImpl(dataSource: nativeDataSource);
  final LocalContactsRepository localContactsRepository =
      LocalContactsRepositoryImpl(databaseService: databaseService);
  
  // 5. <-- الحصول على الـ instance من الخدمة
  final NotificationService notificationService = NotificationService.instance;

  final CallBloc callBloc = CallBloc(
    callRepository: callRepository,
    localContactsRepository: localContactsRepository,
    notificationService: notificationService, // <-- 6. تمرير الخدمة للـ BLoC
  );

  callBloc.add(LoadCallHistory()); 

  runApp(MyApp(callBloc: callBloc));
}

class MyApp extends StatelessWidget {
  // ... (MyApp كما هي، لا تحتاج تعديل)
  final CallBloc callBloc;
  const MyApp({super.key, required this.callBloc});

  @override
  Widget build(BuildContext context) {
    // (الـ ColorScheme كما هو)
    final ColorScheme myColorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF2196F3),
      primary: const Color(0xFF2196F3),
      onPrimary: Colors.white,
      secondary: const Color(0xFF00BCD4),
      onSecondary: Colors.white,
      tertiary: const Color(0xFF8BC34A),
      onTertiary: Colors.black,
      surface: const Color(0xFFF0F5F9),
      onSurface: Colors.black87,
      surfaceContainerHighest: const Color(0xFFE0E5E9),
      brightness: Brightness.light,
      error: Colors.red.shade700,
      onError: Colors.white,
      errorContainer: Colors.red.shade100,
      onErrorContainer: Colors.red.shade900,
    );

    return BlocProvider.value(
      value: callBloc,
      child: MaterialApp(
        title: 'My Caller',
        debugShowCheckedModeBanner: false,
        
        navigatorKey: navigatorKey, 
        scaffoldMessengerKey: scaffoldMessengerKey, 

        theme: ThemeData(
          colorScheme: myColorScheme,
          // (باقي الـ Theme كما هو)
          useMaterial3: true,
          appBarTheme: AppBarTheme(
            backgroundColor: myColorScheme.surface,
            foregroundColor: myColorScheme.onSurface,
            elevation: 0,
            surfaceTintColor: myColorScheme.surface,
          ),
          cardTheme: CardTheme(
            elevation: 0,
            color: myColorScheme.surfaceContainerHighest,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: myColorScheme.surfaceContainerHighest,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: myColorScheme.primary, width: 2),
            ),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          ),
        ),
        home: const SplashScreen(),

        // (الـ builder والـ listener العالمي كما هو، لا يحتاج تعديل)
        builder: (context, child) {
          return BlocListener<CallBloc, CallState>(
            listenWhen: (previous, current) {
              if (previous is CallHistoryLoaded && current is CallHistoryLoaded) {
                return previous.activeCallInfo != current.activeCallInfo;
              }
              return current is CallError || (current is CallHistoryLoaded && current.activeCallInfo != null);
            },
            listener: (context, state) {
              if (state is CallHistoryLoaded) {
                
                if (state.activeCallInfo?.phoneState.status ==
                    PhoneStateStatus.CALL_INCOMING) {
                  final info = state.activeCallInfo!;
                  final number = info.phoneState.number ?? 'Unknown';
                  final name = info.contactName; 

                  scaffoldMessengerKey.currentState?.showSnackBar(
                    SnackBar(
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name ?? 'Incoming Call',
                            style: const TextStyle(
                                color: Colors.white, 
                                fontWeight: FontWeight.bold,
                                fontSize: 16), 
                          ),
                          const SizedBox(height: 4),
                          Text(
                            number, 
                            style: const TextStyle(
                                color: Colors.white70, 
                                fontSize: 14),
                          ),
                        ],
                      ),
                      backgroundColor: Colors.green.shade700,
                      duration: const Duration(days: 365), 
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      margin: const EdgeInsets.all(16),
                    ),
                  );
                } 
                else if (state.activeCallInfo == null || 
                           state.activeCallInfo?.phoneState.status == PhoneStateStatus.CALL_ENDED ||
                           state.activeCallInfo?.phoneState.status == PhoneStateStatus.CALL_STARTED) {
                  
                  scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
                }
              }
              else if (state is CallError) {
                scaffoldMessengerKey.currentState?.showSnackBar(
                  SnackBar(
                    content: Text(
                      state.message,
                      style: TextStyle(
                          color: myColorScheme.onErrorContainer,
                          fontWeight: FontWeight.w600),
                    ),
                    backgroundColor: myColorScheme.errorContainer,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    margin: const EdgeInsets.all(16),
                  ),
                );
              }
            },
            child: child!, 
          );
        },
      ),
    );
  }
}