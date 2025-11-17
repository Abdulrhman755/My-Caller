import 'dart:async';
import 'package:call_log/call_log.dart' as cl;
import 'package:permission_handler/permission_handler.dart';
import 'package:phone_state/phone_state.dart'; // <-- 1. استيراد الحزمة كاملة
import '../../domain/entities/call_log_entry.dart';

abstract class NativeCallDataSource {
  Future<List<CallLogEntry>> getCallLogs();
  // 2. <-- تغيير نوع الـ Stream
  Stream<PhoneState> get incomingCallStream;
}

class NativeCallDataSourceImpl implements NativeCallDataSource {
  
  @override
  Future<List<CallLogEntry>> getCallLogs() async {
    // ... (هذا الكود كما هو) ...
    var status = await Permission.phone.status;
    if (!status.isGranted) {
      status = await Permission.phone.request();
      if (!status.isGranted) {
        throw Exception("User denied phone permission");
      }
    }
    
    final Iterable<cl.CallLogEntry> entries = await cl.CallLog.get();
    return entries.map((entry) {
      return CallLogEntry(
        number: entry.number ?? 'Unknown',
        callType: entry.callType?.name ?? 'unknown',
        duration: entry.duration ?? 0,
        timestamp: entry.timestamp ?? 0,
      );
    }).toList();
  }

  // 3. <-- تعديل تنفيذ الـ Stream
  @override
  Stream<PhoneState> get incomingCallStream {
    // إرجاع الـ Stream الأصلي من الحزمة
    return PhoneState.stream;
  }
}