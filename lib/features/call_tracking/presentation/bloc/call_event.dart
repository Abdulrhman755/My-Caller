part of 'call_bloc.dart';
 // <-- 1. استيراد

@immutable
abstract class CallEvent {}

class LoadCallHistory extends CallEvent {}
class ClearCallHistory extends CallEvent {}
class SaveContactName extends CallEvent {
  final String number;
  final String name;
  SaveContactName(this.number, this.name);
}

// --- (تعديل) ---
// 2. تغيير اسم الحدث ونوع البيانات
class CallStatusChanged extends CallEvent {
  final PhoneState phoneState;
  CallStatusChanged(this.phoneState);
}
// --- (نهاية التعديل) ---