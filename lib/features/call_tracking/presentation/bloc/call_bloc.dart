import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:flutter/widgets.dart'; // <-- 1. استيراد (WidgetsBinding)
import 'package:my_caller/core/services/notification_service.dart'; // <-- 2. استيراد خدمة الإشعارات
import '../../domain/entities/call_log_entry.dart';
import '../../domain/repositories/call_repository.dart';
import '../../domain/repositories/local_contacts_repository.dart';
import 'package:phone_state/phone_state.dart';

part 'call_event.dart';
part 'call_state.dart';

// 3. <-- إضافة (with WidgetsBindingObserver)
class CallBloc extends Bloc<CallEvent, CallState> with WidgetsBindingObserver {
  final CallRepository callRepository;
  final LocalContactsRepository localContactsRepository;
  final NotificationService notificationService; // <-- 4. إضافة الخدمة

  // 5. <-- متغير لتتبع حالة التطبيق
  AppLifecycleState _appLifecycleState = AppLifecycleState.resumed;

  late StreamSubscription<PhoneState> _callSubscription;

  CallBloc({
    required this.callRepository,
    required this.localContactsRepository,
    required this.notificationService, // <-- 6. استقبال الخدمة
  }) : super(CallInitial()) {
    // 7. <-- تسجيل الـ BLoC كمستمع لحالة التطبيق
    WidgetsBinding.instance.addObserver(this);

    _callSubscription = callRepository.listenToIncomingCalls().listen((
      phoneState,
    ) {
      add(CallStatusChanged(phoneState));
    });

    on<LoadCallHistory>(_onLoadCallHistory);
    on<ClearCallHistory>(_onClearCallHistory);
    on<SaveContactName>(_onSaveContactName);
    on<CallStatusChanged>(_onCallStatusChanged);
  }

  // 8. --- (جديد) دالة (override) الخاصة بـ WidgetsBindingObserver ---
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // تحديث المتغير عند تغير حالة التطبيق
    _appLifecycleState = state;
    debugPrint("App Lifecycle State: $_appLifecycleState"); // (للتجربة)
  }
  // --- (نهاية الجديد) ---

  Future<void> _onLoadCallHistory(
    LoadCallHistory event,
    Emitter<CallState> emit,
  ) async {
    // ... (الكود كما هو، لا يحتاج تعديل) ...
    ActiveCallInfo? activeCall;
    if (state is CallHistoryLoaded &&
        (state as CallHistoryLoaded).activeCallInfo?.phoneState.status ==
            PhoneStateStatus.CALL_INCOMING) {
      activeCall = (state as CallHistoryLoaded).activeCallInfo;
    } else {
      activeCall = null;
    }
    if (state is! CallHistoryLoaded) {
      emit(CallHistoryLoading());
    }
    try {
      final logs = await callRepository.getCallLogs();
      final List<CallLogEntry> logsWithNames = [];
      for (final log in logs) {
        final name = await localContactsRepository.getNameForNumber(log.number);
        logsWithNames.add(log.copyWith(name: name));
      }
      emit(CallHistoryLoaded(logsWithNames, activeCallInfo: activeCall));
    } catch (e) {
      emit(CallError("فشل في جلب سجل المكالمات: ${e.toString()}"));
    }
  }

  void _onClearCallHistory(ClearCallHistory event, Emitter<CallState> emit) {
    // ... (الكود كما هو) ...
    if (state is CallHistoryLoaded) {
      emit(
        CallHistoryLoaded(
          [],
          activeCallInfo: (state as CallHistoryLoaded).activeCallInfo,
        ),
      );
    }
  }

  Future<void> _onSaveContactName(
    SaveContactName event,
    Emitter<CallState> emit,
  ) async {
    // ... (الكود كما هو) ...
    try {
      await localContactsRepository.saveContact(event.number, event.name);
      add(LoadCallHistory());
    } catch (e) {
      debugPrint("Error saving contact: $e");
    }
  }

  // --- (هنا هو الإصلاح الرئيسي) ---
  Future<void> _onCallStatusChanged(
    CallStatusChanged event,
    Emitter<CallState> emit,
  ) async {
    final currentState = state;
    List<CallLogEntry> currentLogs = [];
    ActiveCallInfo? currentActiveCallInfo;

    if (currentState is CallHistoryLoaded) {
      currentLogs = currentState.callLogs;
      currentActiveCallInfo = currentState.activeCallInfo;
    }

    if (event.phoneState.status == PhoneStateStatus.CALL_INCOMING) {
      if (event.phoneState.number == null) return;

      if ((currentActiveCallInfo?.phoneState.status ==
                  PhoneStateStatus.CALL_ENDED ||
              currentActiveCallInfo?.phoneState.status ==
                  PhoneStateStatus.CALL_STARTED) &&
          currentActiveCallInfo?.phoneState.number == event.phoneState.number) {
        return;
      }

      if (currentActiveCallInfo?.phoneState.status ==
          PhoneStateStatus.CALL_INCOMING) {
        return;
      }

      final contactName = await localContactsRepository.getNameForNumber(
        event.phoneState.number!,
      );
      final callInfo = ActiveCallInfo(
        phoneState: event.phoneState,
        contactName: contactName,
      );

      // 9. --- (المنطق الجديد) ---
      // التحقق من حالة التطبيق
      if (_appLifecycleState == AppLifecycleState.resumed) {
        // التطبيق مفتوح: أظهر الـ SnackBar (عن طريق إصدار الحالة)
        emit(CallHistoryLoaded(currentLogs, activeCallInfo: callInfo));
      } else {
        // التطبيق في الخلفية: أظهر إشعار
        final number = event.phoneState.number ?? 'Unknown';
        final name = contactName ?? 'Incoming Call';
        await notificationService.showCallNotification(name, number);
        // (قم بإصدار الحالة أيضاً، بحيث إذا فتح المستخدم التطبيق، يجد الـ SnackBar)
        emit(CallHistoryLoaded(currentLogs, activeCallInfo: callInfo));
      }
      // --- (نهاية المنطق الجديد) ---
    } else if (event.phoneState.status == PhoneStateStatus.CALL_ENDED ||
        event.phoneState.status == PhoneStateStatus.CALL_STARTED) {
      // 10. --- (المنطق الجديد) ---
      // التحقق من حالة التطبيق
      if (_appLifecycleState == AppLifecycleState.resumed) {
        // التطبيق مفتوح: أخفِ الـ SnackBar
        emit(CallHistoryLoaded(currentLogs, activeCallInfo: null));
      } else {
        // التطبيق في الخلفية: ألغِ الإشعار
        await notificationService.cancelCallNotification();
        // (قم بإصدار الحالة أيضاً لتصفيرها)
        emit(CallHistoryLoaded(currentLogs, activeCallInfo: null));
      }
      // --- (نهاية المنطق الجديد) ---
    }
  }
  // --- (نهاية الإصلاح) ---

  @override
  Future<void> close() {
    _callSubscription.cancel();
    // 11. <-- إلغاء تسجيل المستمع عند إغلاق الـ BLoC
    WidgetsBinding.instance.removeObserver(this);
    return super.close();
  }
}
