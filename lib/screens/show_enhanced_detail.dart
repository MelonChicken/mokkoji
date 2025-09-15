import 'package:flutter/material.dart';
import 'enhanced_detail_screen.dart';

/// Show the enhanced detail screen with in-place editing capability
/// This replaces the bottom sheet approach with a full-screen experience
Future<void> showEnhancedDetail(BuildContext context, String eventId) {
  return Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => EnhancedDetailScreen(eventId: eventId),
    ),
  );
}

/// Alternative function name for backward compatibility
Future<void> showDetailScreen(BuildContext context, String eventId) {
  return showEnhancedDetail(context, eventId);
}