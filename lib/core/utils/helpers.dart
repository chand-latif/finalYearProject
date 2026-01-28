/// Common utility functions and helpers.

import 'package:flutter/material.dart';

/// Extension on DateTime for formatting
extension DateTimeExtension on DateTime {
  /// Format date as "Jan 15, 2024"
  String toFormattedDate() {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[month - 1]} $day, $year';
  }

  /// Format date as "Jan 15, 2024 at 10:30 AM"
  String toFormattedDateTime() {
    final hour = this.hour > 12 ? this.hour - 12 : (this.hour == 0 ? 12 : this.hour);
    final period = this.hour >= 12 ? 'PM' : 'AM';
    final minute = this.minute.toString().padLeft(2, '0');
    return '${toFormattedDate()} at $hour:$minute $period';
  }

  /// Format as relative time (e.g., "2 hours ago")
  String toRelativeTime() {
    final now = DateTime.now();
    final difference = now.difference(this);

    if (difference.inDays > 30) {
      return toFormattedDate();
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }
}

/// Extension on String for validation
extension StringExtension on String {
  /// Check if string is a valid email
  bool get isValidEmail {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(this);
  }

  /// Check if string is a valid phone number (Pakistan format)
  bool get isValidPhone {
    final phoneRegex = RegExp(r'^(\+92|0)?3[0-9]{9}$');
    return phoneRegex.hasMatch(replaceAll(' ', '').replaceAll('-', ''));
  }

  /// Capitalize first letter
  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Check if string is a valid password (min 8 chars, 1 uppercase, 1 number)
  bool get isValidPassword {
    if (length < 8) return false;
    final hasUppercase = contains(RegExp(r'[A-Z]'));
    final hasNumber = contains(RegExp(r'[0-9]'));
    return hasUppercase && hasNumber;
  }
}

/// Show a snackbar with the given message
void showSnackBar(
  BuildContext context,
  String message, {
  bool isError = false,
  Duration duration = const Duration(seconds: 3),
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.red : Colors.green,
      duration: duration,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  );
}

/// Build image URL with base path
String buildImageUrl(String? path) {
  if (path == null || path.isEmpty) return '';
  if (path.startsWith('http')) return path;
  return 'https://fixease.pk$path';
}

/// Get status color based on booking status
Color getStatusColor(String status) {
  switch (status.toLowerCase()) {
    case 'pending':
      return Colors.orange;
    case 'accepted':
      return Colors.blue;
    case 'inprogress':
    case 'in progress':
      return Colors.purple;
    case 'completed':
    case 'finished':
      return Colors.green;
    case 'cancelled':
    case 'rejected':
      return Colors.red;
    default:
      return Colors.grey;
  }
}

/// Get status icon based on booking status
IconData getStatusIcon(String status) {
  switch (status.toLowerCase()) {
    case 'pending':
      return Icons.schedule;
    case 'accepted':
      return Icons.check_circle_outline;
    case 'inprogress':
    case 'in progress':
      return Icons.engineering;
    case 'completed':
    case 'finished':
      return Icons.task_alt;
    case 'cancelled':
    case 'rejected':
      return Icons.cancel_outlined;
    default:
      return Icons.info_outline;
  }
}
