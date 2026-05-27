import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../core/di/injection_container.dart';
import '../../../profile/presentation/bloc/profile_bloc.dart';
import '../../../profile/presentation/bloc/profile_state.dart';
import '../bloc/notifications_bloc.dart';
import '../bloc/notifications_event.dart';
import '../bloc/notifications_state.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late final NotificationsBloc _notificationsBloc;

  @override
  void initState() {
    super.initState();
    _notificationsBloc = sl<NotificationsBloc>();

    // Dispatch immediately if profile is already loaded
    final profileState = sl<ProfileBloc>().state;
    if (profileState is ProfileLoaded) {
      _notificationsBloc.add(FetchNotificationsEvent(profileState.profile.id));
    }
    // Otherwise the BlocListener below will fire when profile loads
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _notificationsBloc,
      // Listen to ProfileBloc in case it loads *after* this sheet opens
      child: BlocListener<ProfileBloc, ProfileState>(
        bloc: sl<ProfileBloc>(),
        listenWhen: (prev, curr) => curr is ProfileLoaded && prev is! ProfileLoaded,
        listener: (context, profileState) {
          if (profileState is ProfileLoaded) {
            _notificationsBloc.add(FetchNotificationsEvent(profileState.profile.id));
          }
        },
        child: const _NotificationsView(),
      ),
    );
  }
}

class _NotificationsView extends StatelessWidget {
  const _NotificationsView();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2)),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 48), // Balance for trailing button
                const Text(
                  'Notifications',
                  style: TextStyle(color: AppColors.textDark, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                BlocBuilder<NotificationsBloc, NotificationsState>(
                  builder: (context, state) {
                    final profileState = sl<ProfileBloc>().state;
                    final userId = profileState is ProfileLoaded ? profileState.profile.id : null;

                    bool isEnabled = false;
                    if (state is NotificationsLoaded && !state.areAllRead && userId != null) {
                      isEnabled = true;
                    }

                    return TextButton(
                      onPressed: isEnabled
                          ? () {
                              context.read<NotificationsBloc>().add(MarkAllNotificationsReadEvent(userId!));
                            }
                          : null,
                      child: Text(
                        'Mark all read',
                        style: TextStyle(
                          color: isEnabled ? AppColors.primary : AppColors.textGrey.withOpacity(0.5),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          
          // Body
          Expanded(
            child: BlocBuilder<NotificationsBloc, NotificationsState>(
              builder: (context, state) {
                if (state is NotificationsLoading || state is NotificationsInitial) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                } else if (state is NotificationsEmpty) {
                  return _buildEmptyState();
                } else if (state is NotificationsError) {
                  return _buildErrorState(context, state.message);
                } else if (state is NotificationsLoaded) {
                  if (state.notifications.isEmpty) return _buildEmptyState();
                  return RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: () async {
                      final profileState = sl<ProfileBloc>().state;
                      if (profileState is ProfileLoaded) {
                        context.read<NotificationsBloc>().add(FetchNotificationsEvent(profileState.profile.id));
                      }
                    },
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      itemCount: state.notifications.length,
                      separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.divider),
                      itemBuilder: (context, index) {
                        final notification = state.notifications[index];
                        return _NotificationTile(
                          title: notification.title,
                          message: notification.message,
                          createdAt: notification.createdAt,
                          isRead: notification.isRead,
                          type: notification.type,
                        );
                      },
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_off_outlined, size: 48, color: AppColors.textGrey),
          ),
          const SizedBox(height: 16),
          const Text(
            'You\'re all caught up!',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
          ),
          const SizedBox(height: 8),
          const Text(
            'No new notifications right now.',
            style: TextStyle(fontSize: 14, color: AppColors.textGrey),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            const Text(
              'Oops! Something went wrong.',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AppColors.textGrey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                final profileState = sl<ProfileBloc>().state;
                if (profileState is ProfileLoaded) {
                  context.read<NotificationsBloc>().add(FetchNotificationsEvent(profileState.profile.id));
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Try Again', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isRead;
  final int type;

  const _NotificationTile({
    required this.title,
    required this.message,
    required this.createdAt,
    required this.isRead,
    required this.type,
  });

  String _formatTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 365) return '${(diff.inDays / 365).floor()}y ago';
    if (diff.inDays > 30) return '${(diff.inDays / 30).floor()}mo ago';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  IconData _getIcon() {
    final t = title.toLowerCase();
    final m = message.toLowerCase();
    
    if (t.contains('approve') || m.contains('approved')) {
      return Icons.check_circle_rounded;
    }
    if (t.contains('reject') || m.contains('rejected')) {
      return Icons.cancel_rounded;
    }
    if (t.contains('resolve') || m.contains('resolved')) {
      return Icons.gavel_rounded;
    }
    if (t.contains('cancel') || m.contains('cancelled')) {
      return Icons.block_rounded;
    }
    if (type == 4) {
      return Icons.cancel_rounded;
    }
    
    return Icons.notifications_rounded;
  }

  Color _getIconColor(bool isRead) {
    if (isRead) return AppColors.textGrey;
    
    final t = title.toLowerCase();
    final m = message.toLowerCase();
    
    if (t.contains('approve') || m.contains('approved') || t.contains('resolve') || m.contains('resolved')) {
      return AppColors.successGreen;
    }
    if (t.contains('reject') || m.contains('rejected')) {
      return AppColors.error;
    }
    if (t.contains('cancel') || m.contains('cancelled')) {
      return AppColors.warningOrange;
    }
    
    return AppColors.primary;
  }

  Color _getBgColor(bool isRead) {
    if (isRead) return Colors.transparent;
    
    final t = title.toLowerCase();
    final m = message.toLowerCase();
    
    if (t.contains('reject') || m.contains('rejected')) {
      return AppColors.error.withOpacity(0.06);
    }
    if (t.contains('approve') || m.contains('approved') || t.contains('resolve') || m.contains('resolved')) {
      return AppColors.successGreen.withOpacity(0.06);
    }
    
    return AppColors.primaryLight.withOpacity(0.3);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _getBgColor(isRead),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isRead
                  ? AppColors.surface
                  : _getIconColor(isRead).withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getIcon(),
              color: _getIconColor(isRead),
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatTimeAgo(createdAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: isRead ? AppColors.textGrey : AppColors.primary,
                        fontWeight: isRead ? FontWeight.normal : FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 13,
                    color: isRead ? AppColors.textGrey : AppColors.textDark.withOpacity(0.8),
                    height: 1.4,
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
