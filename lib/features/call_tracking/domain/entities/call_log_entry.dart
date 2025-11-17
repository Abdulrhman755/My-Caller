// هذا الكلاس يمثل "مدخل" واحد في سجل المكالمات
class CallLogEntry {
  final String number;      // رقم المتصل
  final String callType;    // نوع المكالمة (واردة، صادرة، فائتة)
  final int duration;       // مدة المكالمة بالثواني
  final int timestamp;      // تاريخ المكالمة (timestamp)
  
  // --- (جديد) ---
  final String? name;       // الاسم المحفوظ (اختياري)
  // --- (نهاية الجديد) ---

  CallLogEntry({
    required this.number,
    required this.callType,
    required this.duration,
    required this.timestamp,
    this.name, // <-- إضافة الاسم إلى الـ constructor
  });

  // دالة مساعدة لتحويل التاريخ إلى صيغة مقروءة
  DateTime get dateTime => DateTime.fromMillisecondsSinceEpoch(timestamp);

  // --- (جديد) ---
  // دالة copyWith لتسهيل تعديل الكائن
  CallLogEntry copyWith({
    String? number,
    String? callType,
    int? duration,
    int? timestamp,
    String? name,
  }) {
    return CallLogEntry(
      number: number ?? this.number,
      callType: callType ?? this.callType,
      duration: duration ?? this.duration,
      timestamp: timestamp ?? this.timestamp,
      name: name ?? this.name, // <-- إضافة الاسم هنا
    );
  }
  // --- (نهاية الجديد) ---
}