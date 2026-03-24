import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/activity_model.dart';

class ActivityCard extends StatelessWidget {
  final ActivityModel activity;
  final int index;
  final AnimationController animationController;

  const ActivityCard({
    super.key,
    required this.activity,
    required this.index,
    required this.animationController,
  });

  @override
  Widget build(BuildContext context) {
    final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: animationController,
        curve: Interval(
          (index * 0.1).clamp(0.0, 0.9),
          ((index * 0.1) + 0.4).clamp(0.0, 1.0),
          curve: Curves.easeOut,
        ),
      ),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) => Opacity(
        opacity: animation.value,
        child: Transform.translate(
          offset: Offset(0, 30 * (1 - animation.value)),
          child: child,
        ),
      ),
      child: _buildCard(context),
    );
  }

  Widget _buildCard(BuildContext context) {
    final config = _ActivityConfig.from(activity.activityType);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: config.color.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Accent bar
              Container(
                width: 5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [config.color, config.color.withOpacity(0.5)],
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildIconBadge(config),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  config.label,
                                  style: AppTextStyle.bodySmall.copyWith(
                                    color: config.color,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  activity.metadata.displayTitle,
                                  style: AppTextStyle.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: Colors.grey[900],
                                    height: 1.3,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildStatusChip(),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildMetadataRow(config),
                      const SizedBox(height: 10),
                      _buildFooter(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconBadge(_ActivityConfig config) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            config.color.withOpacity(0.15),
            config.color.withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(config.icon, color: config.color, size: 22),
    );
  }

  Widget _buildStatusChip() {
    final status = activity.metadata.status ?? '';
    if (status.isEmpty) return const SizedBox.shrink();

    final (chipColor, textColor) = _statusColors(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _capitalize(status),
        style: AppTextStyle.bodySmall.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }

  (Color, Color) _statusColors(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
      case 'completed':
      case 'success':
        return (Colors.green.withOpacity(0.12), Colors.green[700]!);
      case 'rejected':
      case 'failed':
      case 'cancelled':
        return (Colors.red.withOpacity(0.12), Colors.red[700]!);
      case 'pending':
      default:
        return (Colors.orange.withOpacity(0.12), Colors.orange[800]!);
    }
  }

  Widget _buildMetadataRow(_ActivityConfig config) {
    final items = _buildMetadataItems(config);
    if (items.isEmpty) return const SizedBox.shrink();

    return Wrap(spacing: 16, runSpacing: 6, children: items);
  }

  List<Widget> _buildMetadataItems(_ActivityConfig config) {
    final items = <Widget>[];

    switch (activity.activityType) {
      case 'donation':
        final amount = activity.metadata.amount;
        if (amount != null) {
          items.add(
            _metaItem(
              Icons.attach_money_rounded,
              'NPR ${NumberFormat('#,##0').format(amount)}',
              Colors.green[700]!,
            ),
          );
        }
        final method = activity.metadata.paymentMethod;
        if (method != null) {
          items.add(
            _metaItem(
              Icons.credit_card_rounded,
              _capitalize(method),
              Colors.grey[600]!,
            ),
          );
        }
        final anon = activity.metadata.isAnonymous;
        if (anon != null) {
          items.add(
            _metaItem(
              anon ? Icons.visibility_off_rounded : Icons.visibility_rounded,
              anon ? 'Anonymous' : 'Public',
              Colors.grey[600]!,
            ),
          );
        }
        break;

      case 'event_registration':
        items.add(
          _metaItem(Icons.event_rounded, 'Event Registration', config.color),
        );
        break;

      case 'volunteer_job_enrollment':
        items.add(
          _metaItem(
            Icons.volunteer_activism_rounded,
            'Volunteer Application',
            config.color,
          ),
        );
        break;
    }

    return items;
  }

  Widget _metaItem(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTextStyle.bodySmall.copyWith(
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Row(
      children: [
        Icon(Icons.schedule_rounded, size: 13, color: Colors.grey[400]),
        const SizedBox(width: 4),
        Text(
          _formatDate(activity.createdAt),
          style: AppTextStyle.bodySmall.copyWith(
            color: Colors.grey[400],
            fontSize: 11,
          ),
        ),
        const Spacer(),
        Icon(Icons.chevron_right_rounded, size: 16, color: Colors.grey[300]),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      if (diff.inHours == 0) return '${diff.inMinutes}m ago';
      return '${diff.inHours}h ago';
    }
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d, yyyy').format(date);
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}

// ---------------------------------------------------------------------------
// Activity visual config
// ---------------------------------------------------------------------------

class _ActivityConfig {
  final Color color;
  final IconData icon;
  final String label;

  const _ActivityConfig({
    required this.color,
    required this.icon,
    required this.label,
  });

  factory _ActivityConfig.from(String activityType) {
    switch (activityType) {
      case 'donation':
        return _ActivityConfig(
          color: const Color(0xFF16A34A),
          icon: Icons.favorite_rounded,
          label: 'DONATION',
        );
      case 'event_registration':
        return _ActivityConfig(
          color: const Color(0xFF7C3AED),
          icon: Icons.event_available_rounded,
          label: 'EVENT REGISTRATION',
        );
      case 'volunteer_job_enrollment':
        return _ActivityConfig(
          color: const Color(0xFFEA580C),
          icon: Icons.volunteer_activism_rounded,
          label: 'VOLUNTEER JOB',
        );
      default:
        return _ActivityConfig(
          color: AppColorToken.primary.color,
          icon: Icons.notifications_rounded,
          label: activityType.replaceAll('_', ' ').toUpperCase(),
        );
    }
  }
}
