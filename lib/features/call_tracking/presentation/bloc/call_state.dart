part of 'call_bloc.dart'; 


// --- (جديد) ---
// 1. كلاس جديد لتغليف معلومات المكالمة النشطة
class ActiveCallInfo {
  final PhoneState phoneState; // حالة المكالمة (ترن، انتهت)
  final String? contactName;   // الاسم من قاعدة البيانات

  ActiveCallInfo({required this.phoneState, this.contactName});

  // (نضيف هذا لمقارنة الحالات في الـ BLoC)
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActiveCallInfo &&
          runtimeType == other.runtimeType &&
          phoneState == other.phoneState &&
          contactName == other.contactName;

  @override
  int get hashCode => phoneState.hashCode ^ contactName.hashCode;
}
// --- (نهاية الجديد) ---


@immutable
abstract class CallState {}

class CallInitial extends CallState {}
class CallHistoryLoading extends CallState {}

class CallHistoryLoaded extends CallState {
  final List<CallLogEntry> callLogs;
  
  // --- (تعديل) ---
  // 2. تغيير المتغير ليحمل الكلاس الجديد
  final ActiveCallInfo? activeCallInfo;
  // --- (نهاية التعديل) ---

  CallHistoryLoaded(this.callLogs, {this.activeCallInfo});

  CallHistoryLoaded copyWith({
    List<CallLogEntry>? callLogs,
    ActiveCallInfo? activeCallInfo,
    bool clearActiveCall = false, // خدعة لمسح المكالمة
  }) {
    return CallHistoryLoaded(
      callLogs ?? this.callLogs,
      // 3. تحديث الـ copyWith
      activeCallInfo: clearActiveCall ? null : activeCallInfo ?? this.activeCallInfo,
    );
  }
}

class CallError extends CallState {
  final String message;
  CallError(this.message);
}