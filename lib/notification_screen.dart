import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';
import 'notification_helper.dart';

class NotificationScreen extends StatefulWidget {
  final String userName;
  const NotificationScreen({super.key, required this.userName});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<Map<String, dynamic>> _notifs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final notifs = await NotificationHelper.getNotifications(widget.userName);
    await NotificationHelper.markAllRead();
    if (mounted) {
      setState(() {
        _notifs = notifs;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F2),
      body: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 20, 16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: AppColors.primary,
                        size: 18,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Text('Notifikasi', style: AppTextStyles.headingSmall),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary))
                : _notifs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('🔔', style: TextStyle(fontSize: 48)),
                            const SizedBox(height: 12),
                            Text('Belum ada notifikasi',
                                style: AppTextStyles.bodyMedium
                                    .copyWith(color: const Color(0xFF9E9E9E))),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(20),
                        itemCount: _notifs.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => _buildItem(_notifs[i]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(Map<String, dynamic> notif) {
    final isNew = notif['isNew'] == true;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isNew ? AppColors.accent.withValues(alpha: 0.6) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isNew
              ? AppColors.primary.withValues(alpha: 0.15)
              : const Color(0xFFEEEEEE),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ikon emoji
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEEEEEE)),
            ),
            child: Center(
              child: Text(notif['icon'], style: const TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 12),

          // Konten
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        notif['title'],
                        style: AppTextStyles.labelLarge.copyWith(
                          fontSize: 13,
                          color: const Color(0xFF212121),
                        ),
                      ),
                    ),
                    if (isNew)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  notif['body'],
                  style: AppTextStyles.caption.copyWith(
                    color: const Color(0xFF757575),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  notif['time'],
                  style: AppTextStyles.caption.copyWith(
                    color: const Color(0xFFBDBDBD),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
