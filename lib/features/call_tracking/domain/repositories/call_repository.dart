import '../entities/call_log_entry.dart';
import 'package:phone_state/phone_state.dart'; // <-- 1. استيراد

abstract class CallRepository {
  
  Future<List<CallLogEntry>> getCallLogs();

  // 2. <-- تغيير نوع الـ Stream
  Stream<PhoneState> listenToIncomingCalls();
}