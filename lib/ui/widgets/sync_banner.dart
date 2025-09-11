// Sync banner widget showing synchronization status and last sync time
// Displays different states: synced, syncing, error, offline
// Provides visual feedback for database synchronization with external services

import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/time/kst.dart';

class SyncBanner extends StatefulWidget {
  const SyncBanner({super.key});

  @override
  State<SyncBanner> createState() => _SyncBannerState();
}

class _SyncBannerState extends State<SyncBanner> {
  SyncStatus _syncStatus = SyncStatus.synced;
  DateTime _lastSyncTime = DateTime.now().subtract(const Duration(minutes: 5));
  bool _isVisible = true;

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: _getBannerColor(colorScheme),
      child: Row(
        children: [
          _buildStatusIcon(colorScheme),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getStatusTitle(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _getTextColor(colorScheme),
                  ),
                ),
                if (_getStatusSubtitle().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    _getStatusSubtitle(),
                    style: TextStyle(
                      fontSize: 12,
                      color: _getTextColor(colorScheme).withOpacity(0.8),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (_syncStatus == SyncStatus.error) ...[
            TextButton(
              onPressed: _retrySync,
              child: Text(
                '다시 시도',
                style: TextStyle(
                  color: _getTextColor(colorScheme),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          IconButton(
            icon: Icon(
              Icons.close,
              size: 18,
              color: _getTextColor(colorScheme),
            ),
            onPressed: () => setState(() => _isVisible = false),
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIcon(ColorScheme colorScheme) {
    switch (_syncStatus) {
      case SyncStatus.syncing:
        return SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(_getTextColor(colorScheme)),
          ),
        );
      case SyncStatus.synced:
        return Icon(
          Icons.check_circle,
          size: 18,
          color: _getTextColor(colorScheme),
        );
      case SyncStatus.error:
        return Icon(
          Icons.error_outline,
          size: 18,
          color: _getTextColor(colorScheme),
        );
      case SyncStatus.offline:
        return Icon(
          Icons.wifi_off,
          size: 18,
          color: _getTextColor(colorScheme),
        );
    }
  }

  Color _getBannerColor(ColorScheme colorScheme) {
    switch (_syncStatus) {
      case SyncStatus.syncing:
        return Colors.blue.shade100;
      case SyncStatus.synced:
        return Colors.green.shade100;
      case SyncStatus.error:
        return Colors.red.shade100;
      case SyncStatus.offline:
        return Colors.grey.shade200;
    }
  }

  Color _getTextColor(ColorScheme colorScheme) {
    switch (_syncStatus) {
      case SyncStatus.syncing:
        return Colors.blue.shade800;
      case SyncStatus.synced:
        return Colors.green.shade800;
      case SyncStatus.error:
        return Colors.red.shade800;
      case SyncStatus.offline:
        return Colors.grey.shade700;
    }
  }

  String _getStatusTitle() {
    switch (_syncStatus) {
      case SyncStatus.syncing:
        return '동기화 중';
      case SyncStatus.synced:
        return '동기화 완료';
      case SyncStatus.error:
        return '동기화 실패';
      case SyncStatus.offline:
        return '오프라인';
    }
  }

  String _getStatusSubtitle() {
    switch (_syncStatus) {
      case SyncStatus.syncing:
        return '캘린더 데이터를 동기화하고 있습니다';
      case SyncStatus.synced:
        final timeAgo = _formatTimeAgo(_lastSyncTime);
        return '마지막 동기화: $timeAgo';
      case SyncStatus.error:
        return '캘린더 데이터를 동기화하지 못했습니다';
      case SyncStatus.offline:
        final timeAgo = _formatTimeAgo(_lastSyncTime);
        return '캐시된 데이터를 표시 중 (마지막 동기화: $timeAgo)';
    }
  }

  String _formatTimeAgo(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return '방금 전';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}분 전';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}시간 전';
    } else {
      return KST.dayTime(time.millisecondsSinceEpoch);
    }
  }

  void _retrySync() {
    setState(() {
      _syncStatus = SyncStatus.syncing;
    });

    // Simulate sync retry
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _syncStatus = SyncStatus.synced;
          _lastSyncTime = DateTime.now();
        });
      }
    });
  }
}

enum SyncStatus {
  syncing,
  synced,
  error,
  offline,
}

// Simple stateless version for cases where you don't need state management
class SimpleSyncBanner extends StatelessWidget {
  final SyncStatus status;
  final DateTime? lastSyncTime;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;

  const SimpleSyncBanner({
    super.key,
    required this.status,
    this.lastSyncTime,
    this.onRetry,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: _getBannerColor(colorScheme),
      child: Row(
        children: [
          _buildStatusIcon(colorScheme),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getStatusTitle(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _getTextColor(colorScheme),
                  ),
                ),
                if (_getStatusSubtitle().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    _getStatusSubtitle(),
                    style: TextStyle(
                      fontSize: 12,
                      color: _getTextColor(colorScheme).withOpacity(0.8),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (status == SyncStatus.error && onRetry != null) ...[
            TextButton(
              onPressed: onRetry,
              child: Text(
                '다시 시도',
                style: TextStyle(
                  color: _getTextColor(colorScheme),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          if (onDismiss != null) ...[
            IconButton(
              icon: Icon(
                Icons.close,
                size: 18,
                color: _getTextColor(colorScheme),
              ),
              onPressed: onDismiss,
              constraints: const BoxConstraints(
                minWidth: 32,
                minHeight: 32,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusIcon(ColorScheme colorScheme) {
    switch (status) {
      case SyncStatus.syncing:
        return SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(_getTextColor(colorScheme)),
          ),
        );
      case SyncStatus.synced:
        return Icon(Icons.check_circle, size: 18, color: _getTextColor(colorScheme));
      case SyncStatus.error:
        return Icon(Icons.error_outline, size: 18, color: _getTextColor(colorScheme));
      case SyncStatus.offline:
        return Icon(Icons.wifi_off, size: 18, color: _getTextColor(colorScheme));
    }
  }

  Color _getBannerColor(ColorScheme colorScheme) {
    switch (status) {
      case SyncStatus.syncing:
        return Colors.blue.shade100;
      case SyncStatus.synced:
        return Colors.green.shade100;
      case SyncStatus.error:
        return Colors.red.shade100;
      case SyncStatus.offline:
        return Colors.grey.shade200;
    }
  }

  Color _getTextColor(ColorScheme colorScheme) {
    switch (status) {
      case SyncStatus.syncing:
        return Colors.blue.shade800;
      case SyncStatus.synced:
        return Colors.green.shade800;
      case SyncStatus.error:
        return Colors.red.shade800;
      case SyncStatus.offline:
        return Colors.grey.shade700;
    }
  }

  String _getStatusTitle() {
    switch (status) {
      case SyncStatus.syncing:
        return '동기화 중';
      case SyncStatus.synced:
        return '동기화 완료';
      case SyncStatus.error:
        return '동기화 실패';
      case SyncStatus.offline:
        return '오프라인';
    }
  }

  String _getStatusSubtitle() {
    switch (status) {
      case SyncStatus.syncing:
        return '캘린더 데이터를 동기화하고 있습니다';
      case SyncStatus.synced:
        if (lastSyncTime != null) {
          final timeAgo = _formatTimeAgo(lastSyncTime!);
          return '마지막 동기화: $timeAgo';
        }
        return '동기화 완료';
      case SyncStatus.error:
        return '캘린더 데이터를 동기화하지 못했습니다';
      case SyncStatus.offline:
        if (lastSyncTime != null) {
          final timeAgo = _formatTimeAgo(lastSyncTime!);
          return '캐시된 데이터를 표시 중 (마지막 동기화: $timeAgo)';
        }
        return '오프라인 상태입니다';
    }
  }

  String _formatTimeAgo(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return '방금 전';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}분 전';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}시간 전';
    } else {
      return KST.dayTime(time.millisecondsSinceEpoch);
    }
  }
}

// Test acceptance criteria:
// 1. Banner displays different visual states for sync status appropriately
// 2. Time formatting shows relative time (minutes ago, hours ago) correctly
// 3. Retry functionality works for error states
// 4. Banner can be dismissed and hidden from view
// 5. Both stateful and stateless versions work correctly in different contexts