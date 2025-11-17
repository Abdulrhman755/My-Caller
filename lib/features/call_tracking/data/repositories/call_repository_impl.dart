import 'package:flutter/foundation.dart';

import '../../domain/entities/call_log_entry.dart';
import '../../domain/repositories/call_repository.dart';
import '../datasources/native_call_datasource.dart';
import 'package:phone_state/phone_state.dart'; // استيراد حزمة حالة الهاتف

class CallRepositoryImpl implements CallRepository {
  
  final NativeCallDataSource dataSource;
  CallRepositoryImpl({required this.dataSource});

  @override
  Future<List<CallLogEntry>> getCallLogs() async {
    // --- (هذا هو الكود الذي كان ناقصاً) ---
    try {
      return await dataSource.getCallLogs();
    } catch (e) {
      debugPrint("Error in CallRepositoryImpl: $e");
      return []; // إرجاع قائمة فارغة في حالة حدوث خطأ
    }
    // --- (نهاية الإصلاح) ---
  }

  @override
  Stream<PhoneState> listenToIncomingCalls() {
    return dataSource.incomingCallStream;
  }
}