import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
// (تم حذف استيراد phone_state)
import '../../domain/entities/call_log_entry.dart';
import '../bloc/call_bloc.dart';

class CallHistoryScreen extends StatefulWidget {
  const CallHistoryScreen({super.key});

  @override
  State<CallHistoryScreen> createState() => _CallHistoryScreenState();
}

class _CallHistoryScreenState extends State<CallHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  // (تم حذف _allLogs و _filteredLogs)
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    // (التحميل سيحدث من main.dart، لكن هذا لضمان التحديث عند الدخول)
    context.read<CallBloc>().add(LoadCallHistory());
    // (تعديل) سنقوم فقط بتشغيل setState لإعادة بناء الفلتر
    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // (تم حذف دالة _filterLogs)

  // (كل الدوال المساعدة الأخرى كما هي)
  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final secs = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      final hours = twoDigits(duration.inHours);
      return '$hours:$minutes:$secs';
    }
    return '$minutes:$secs';
  }

  String _formatDateTime(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final dateOnly = DateTime(dt.year, dt.month, dt.day);

    if (dateOnly == today) {
      return 'Today, ${DateFormat.jm().format(dt)}';
    } else if (dateOnly == yesterday) {
      return 'Yesterday, ${DateFormat.jm().format(dt)}';
    } else {
      return DateFormat('MMM d, h:mm a').format(dt);
    }
  }

  void _showClearHistoryDialog(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: colorScheme.surfaceContainerHighest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Clear History?'),
          content: Text(
            'This will clear the call history from the app view. \n\nIt will not delete them from your phone. The list will reload if you pull to refresh.',
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
          actions: [
            TextButton(
              child: Text(
                'Cancel',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: Text('Clear', style: TextStyle(color: colorScheme.error)),
              onPressed: () {
                context.read<CallBloc>().add(ClearCallHistory());
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showCallActionsBottomSheet(BuildContext context, CallLogEntry log) {
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surfaceContainerHighest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Text(
                    log.name ?? log.number,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Divider(thickness: 0.5),
                ListTile(
                  leading: Icon(
                    Icons.call_outlined,
                    color: colorScheme.primary,
                  ),
                  title: const Text('Call Back'),
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    final Uri url = Uri(scheme: 'tel', path: log.number);
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url);
                    } else {
                      _showErrorSnackBar(context, 'Could not make call');
                    }
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.sms_outlined,
                    color: Colors.green.shade700,
                  ),
                  title: const Text('Send SMS'),
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    final Uri url = Uri(scheme: 'sms', path: log.number);
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url);
                    } else {
                      _showErrorSnackBar(
                        context,
                        'Could not open messaging app',
                      );
                    }
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.copy_outlined,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  title: const Text('Copy Number'),
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: log.number));
                    Navigator.of(sheetContext).pop();
                    _showInfoSnackBar(context, 'Number copied to clipboard');
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.person_add_alt_1_outlined,
                    color: colorScheme.tertiary,
                  ),
                  title: Text(log.name != null ? 'Edit Name' : 'Save Name'),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _showSaveNameDialog(context, log.number, log.name);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSaveNameDialog(
    BuildContext context,
    String number,
    String? currentName,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final nameController = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: colorScheme.surfaceContainerHighest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(currentName != null ? 'Edit Name' : 'Save Name'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                number,
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text(
                'Cancel',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: Text(
                'Save',
                style: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                final newName = nameController.text;
                if (newName.isNotEmpty) {
                  context.read<CallBloc>().add(
                    SaveContactName(number, newName),
                  );
                  Navigator.of(dialogContext).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    if (!mounted) return;
    // (الـ SnackBar العالمي في main.dart سيتعامل مع هذا)
    debugPrint("Error SnackBar requested: $message");
  }

  void _showInfoSnackBar(BuildContext context, String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onInverseSurface,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.inverseSurface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        // (الـ AppBar كما هو)
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/my_caller_logo.png', height: 28, width: 28),
            const SizedBox(width: 8),
            _isSearching
                ? Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16.0),
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Search number or name...',
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        fillColor: Colors.transparent,
                        hintStyle: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      style: TextStyle(color: colorScheme.onSurface),
                    ),
                  ),
                )
                : const Text('Call History'),
          ],
        ),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        surfaceTintColor: colorScheme.surface,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                }
              });
            },
          ),
          if (!_isSearching)
            IconButton(
              icon: Icon(
                Icons.delete_sweep_outlined,
                color: colorScheme.onSurfaceVariant,
              ),
              tooltip: 'Clear History',
              onPressed: () {
                _showClearHistoryDialog(context);
              },
            ),
        ],
      ),
      backgroundColor: colorScheme.surface,

      // --- (هنا الإصلاح) ---
      // 1. استخدام BlocBuilder (لأنه لا يحتاج لـ listener محلي)
      body: BlocBuilder<CallBloc, CallState>(
        builder: (context, state) {
          List<CallLogEntry> allLogs = []; // قائمة فارغة افتراضية

          if (state is CallHistoryLoading && allLogs.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is CallError && allLogs.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async {
                context.read<CallBloc>().add(LoadCallHistory());
              },
              child: _buildEmptyOrErrorState(
                context,
                icon: Icons.error_outline,
                title: 'Something went wrong',
                message: state.message,
              ),
            );
          }

          if (state is CallHistoryLoaded) {
            // 2. تحديث القائمة المحلية مباشرة من الحالة
            allLogs = state.callLogs;
          }

          // 3. تطبيق الفلترة "لحظياً" داخل الـ builder
          final searchTerm = _searchController.text.toLowerCase();
          final filteredLogs =
              allLogs.where((log) {
                final numberMatch = log.number.contains(searchTerm);
                final nameMatch =
                    log.name?.toLowerCase().contains(searchTerm) ?? false;
                return numberMatch || nameMatch;
              }).toList();

          return RefreshIndicator(
            onRefresh: () async {
              context.read<CallBloc>().add(LoadCallHistory());
            },
            // 4. بناء الـ UI بناءً على القائمة المفلترة
            child:
                filteredLogs.isEmpty
                    ? _buildEmptyOrErrorState(
                      context,
                      icon:
                          _isSearching
                              ? Icons.search_off
                              : Icons.call_end_outlined,
                      title: _isSearching ? 'No Results' : 'No Call History',
                      message:
                          _isSearching
                              ? 'No calls found matching "${_searchController.text}"'
                              : 'Your call log is empty. Pull down to refresh.',
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: filteredLogs.length,
                      itemBuilder: (context, index) {
                        final logEntry = filteredLogs[index];
                        return _buildCallLogItem(
                          context,
                          logEntry,
                          onTap: () {
                            _showCallActionsBottomSheet(context, logEntry);
                          },
                        );
                      },
                    ),
          );
        },
      ),
      // --- (نهاية الإصلاح) ---
    );
  }

  // (دالة بناء البطاقة كما هي)
  Widget _buildCallLogItem(
    BuildContext context,
    CallLogEntry log, {
    required VoidCallback onTap,
  }) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    IconData icon;
    Color iconColor;
    Color avatarColor;
    String callTypeString;

    switch (log.callType) {
      case 'incoming':
        icon = Icons.call_received;
        iconColor = colors.primary;
        avatarColor = colors.primaryContainer;
        callTypeString = "Incoming";
        break;
      case 'outgoing':
        icon = Icons.call_made;
        iconColor = Colors.green.shade700;
        avatarColor = Colors.green.shade100;
        callTypeString = "Outgoing";
        break;
      case 'missed':
        icon = Icons.call_missed;
        iconColor = colors.error;
        avatarColor = colors.errorContainer;
        callTypeString = "Missed";
        break;
      case 'rejected':
        icon = Icons.call_end;
        iconColor = colors.error;
        avatarColor = colors.errorContainer;
        callTypeString = "Declined";
        break;
      default:
        icon = Icons.call;
        iconColor = colors.onSurfaceVariant;
        avatarColor = colors.surfaceContainerHighest;
        callTypeString = "Unknown";
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: avatarColor,
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      log.name ?? log.number,
                      style: text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (log.name != null)
                      Text(
                        log.number,
                        style: text.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant.withAlpha(
                            178,
                          ), // (70% opacity)
                        ),
                      ),
                    if (log.name != null) const SizedBox(height: 2),
                    Text(
                      _formatDateTime(log.dateTime),
                      style: text.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatDuration(log.duration),
                    style: text.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    callTypeString,
                    style: text.bodySmall?.copyWith(
                      color: iconColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // (دالة بناء الشاشة الفارغة كما هي)
  Widget _buildEmptyOrErrorState(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String message,
  }) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.7,
          alignment: Alignment.center,
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 64,
                color: colors.onSurfaceVariant.withAlpha(128),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: text.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: text.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
