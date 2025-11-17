import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._privateConstructor();
  static final NotificationService instance = NotificationService._privateConstructor();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    
    // --- (الإصلاح 1: أيقونة التهيئة) ---
    // (استخدام أيقونة Mipmap الافتراضية بدلاً من الملف المخصص)
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher'); 
    // --- (نهاية الإصلاح) ---

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  AndroidNotificationChannel _getCallChannel() {
    return const AndroidNotificationChannel(
      'incoming_call_channel', 
      'Incoming Calls', 
      description: 'Channel for incoming call notifications.', 
      importance: Importance.max, 
      playSound: true, 
      // (تم حذف 'sound' من هنا وهو صحيح)
    );
  }


  Future<void> showCallNotification(String nameOrNumber, String number) async {
    final channel = _getCallChannel();

    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      channel.id,
      channel.name,
      channelDescription: channel.description,
      importance: Importance.max,
      priority: Priority.high,
      
      // --- (الإصلاح 2: إعدادات استمرار الإشعار) ---
      ongoing: false,      // (كان true) للسماح للمستخدم بمسحه بالسحب
      autoCancel: true,   // (كان false) ليختفي الإشعار عند الضغط عليه
      // --- (نهاية الإصلاح) ---

      playSound: true,
      // (تم حذف 'sound' من هنا وهو صحيح)

      // --- (الإصلاح 3: أيقونة الإشعار) ---
      icon: '@mipmap/ic_launcher', // (كان 'notification_icon')
      // --- (نهاية الإصلاح) ---
    );
    
    final NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _flutterLocalNotificationsPlugin.show(
      0, 
      nameOrNumber, 
      number,       
      platformChannelSpecifics,
    );
  }

  Future<void> cancelCallNotification() async {
    await _flutterLocalNotificationsPlugin.cancel(0); 
  }
}