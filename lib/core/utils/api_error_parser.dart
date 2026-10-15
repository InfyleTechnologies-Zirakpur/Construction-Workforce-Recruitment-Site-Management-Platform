import 'dart:io';
import 'package:dio/dio.dart';

class ApiErrorParser {
  ApiErrorParser._();

  /// Checks if an error is network/connectivity related
  static bool isNetworkError(dynamic error) {
    if (error == null) return false;
    if (error is SocketException) return true;
    if (error is DioException) {
      if (error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        return true;
      }
      if (error.error is SocketException) return true;
    }
    final s = error.toString().toLowerCase();
    return s.contains('socketexception') ||
        s.contains('failed host lookup') ||
        s.contains('network is unreachable') ||
        s.contains('no internet') ||
        s.contains('connection refused') ||
        s.contains('connection timed out') ||
        s.contains('xmlhttprequest error') ||
        s.contains('handshakeexception');
  }

  /// Extracts user-friendly real error message from any error or exception.
  static String extractMessage(
    dynamic error, {
    String? fallback,
    String? fallbackMessage,
  }) {
    final effectiveFallback = fallback ??
        fallbackMessage ??
        'An unexpected error occurred. Please try again.';
    if (error == null) return effectiveFallback;

    // 1. Direct SocketException check
    if (error is SocketException) {
      return 'No internet connection. Please check your Wi-Fi or mobile data.';
    }

    // 2. DioException check
    if (error is DioException) {
      // Check inner error first
      if (error.error is SocketException) {
        return 'No internet connection. Please check your Wi-Fi or mobile data.';
      }

      final res = error.response;
      if (res != null && res.data != null) {
        final data = res.data;
        if (data is Map) {
          // A. Direct 'message' key
          final message = data['message'];
          if (message is String && message.trim().isNotEmpty) {
            return _formatMessage(message.trim());
          } else if (message is List && message.isNotEmpty) {
            final first = message.first;
            if (first is String && first.trim().isNotEmpty) {
              return _formatMessage(first.trim());
            }
          }

          // B. Direct 'error' key
          final err = data['error'];
          if (err is String && err.trim().isNotEmpty) {
            return _formatMessage(err.trim());
          }

          // C. 'errors' map (validation errors)
          final errors = data['errors'];
          if (errors is Map && errors.isNotEmpty) {
            final firstVal = errors.values.first;
            if (firstVal is String && firstVal.trim().isNotEmpty) {
              return _formatMessage(firstVal.trim());
            } else if (firstVal is List && firstVal.isNotEmpty) {
              return _formatMessage(firstVal.first.toString());
            }
          }
        } else if (data is String &&
            data.trim().isNotEmpty &&
            !data.contains('<!DOCTYPE html>')) {
          return _formatMessage(data.trim());
        }

        // Status code fallbacks
        switch (res.statusCode) {
          case 400:
            return 'Invalid details submitted. Please check your inputs and try again.';
          case 401:
            return 'Invalid email or password. Please verify your credentials.';
          case 403:
            return 'Access denied. You do not have permission to perform this action.';
          case 404:
            return 'Account or resource not found. Please verify and try again.';
          case 409:
            return 'An account with these details already exists. Please log in.';
          case 422:
            return 'Validation failed. Please verify all required fields.';
          case 429:
            return 'Too many requests. Please wait a minute before trying again.';
          case 500:
            return 'Server error. Our engineers have been alerted. Please try again shortly.';
          case 502:
          case 504:
            return 'Server took too long to respond (Gateway Timeout). Please try again.';
          case 503:
            return 'Server is temporarily unavailable or under maintenance. Please try again in a few moments.';
        }
      }

  
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        return 'Connection timed out. Server took too long to respond. Please try again.';
      }
      if (error.type == DioExceptionType.connectionError) {
        return 'No internet connection or server unreachable. Please check your Wi-Fi or mobile data.';
      }
      if (error.type == DioExceptionType.badCertificate) {
        return 'Secure connection failed. Please check your system date, time, and network security.';
      }
      if (error.type == DioExceptionType.cancel) {
        return 'Request was cancelled.';
      }
    }

    final raw = error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '').trim();
    if (raw.isNotEmpty && !raw.contains('DioException [') && !raw.contains('Instance of')) {
      return _formatMessage(raw);
    }

    return effectiveFallback;
  }

  static String _formatMessage(String msg) {
    if (msg.isEmpty) return msg;
    final lower = msg.toLowerCase();

    // Network / Socket errors
    if (lower.contains('socketexception') ||
        lower.contains('failed host lookup') ||
        lower.contains('network is unreachable') ||
        lower.contains('no address associated with hostname') ||
        lower.contains('no internet')) {
      return 'No internet connection. Please check your Wi-Fi or mobile data.';
    }
    if (lower.contains('connection refused') ||
        lower.contains('connection reset') ||
        lower.contains('software caused connection abort')) {
      return 'Unable to reach the server. Please check your connection or try again later.';
    }
    if (lower.contains('timeout') || lower.contains('timed out')) {
      return 'Connection timed out. Server took too long to respond. Please try again.';
    }
    if (lower.contains('handshakeexception') || lower.contains('certpathvalidator')) {
      return 'Secure connection failed. Please check your device date, time, and security settings.';
    }

    // Credentials & Auth
    if (lower.contains('invalid credentials') ||
        lower.contains('wrong password') ||
        lower.contains('incorrect password') ||
        lower.contains('bad credentials') ||
        lower.contains('unauthorized') ||
        (lower.contains('user not found') && lower.contains('password'))) {
      return 'Invalid email or password. Please check your credentials.';
    }
    if (lower.contains('invalid email') ||
        lower.contains('email format is invalid') ||
        lower.contains('must be a valid email')) {
      return 'Invalid email address. Please enter a valid email (e.g. name@company.com).';
    }
    if (lower.contains('invalid phone') ||
        lower.contains('phone number is invalid') ||
        lower.contains('invalid mobile')) {
      return 'Invalid mobile number. Please enter a valid 10-digit number.';
    }
    if (lower.contains('invalid password') ||
        lower.contains('password must be') ||
        lower.contains('password too short')) {
      return 'Invalid password. Password must be at least 6 characters long.';
    }
    if (lower.contains('mismatch') || lower.contains('passwords do not match')) {
      return 'Passwords do not match. Please verify your password.';
    }

    // OTP
    if (lower.contains('invalid otp') ||
        lower.contains('otp invalid') ||
        lower.contains('wrong otp') ||
        lower.contains('incorrect otp') ||
        lower.contains('otp mismatch')) {
      return 'Invalid OTP code. Please enter the correct 6-digit code.';
    }
    if (lower.contains('otp expired') ||
        lower.contains('expired otp') ||
        lower.contains('code expired')) {
      return 'OTP has expired. Please request a new verification code.';
    }

    // Duplicates & Registration
    if (lower.contains('user already exists') ||
        lower.contains('email already') ||
        lower.contains('email is already registered') ||
        lower.contains('duplicate email')) {
      return 'An account with this email already exists. Please log in.';
    }
    if (lower.contains('phone already') ||
        lower.contains('mobile already') ||
        lower.contains('phone number already')) {
      return 'An account with this mobile number already exists. Please log in.';
    }

    // Session & Permissions
    if (lower.contains('token expired') ||
        lower.contains('jwt expired') ||
        lower.contains('session expired')) {
      return 'Your session has expired. Please log in again.';
    }
    if (lower.contains('too many requests') || lower.contains('rate limit')) {
      return 'Too many attempts. Please wait a minute and try again.';
    }
    if (lower.contains('account disabled') ||
        lower.contains('account suspended') ||
        lower.contains('account inactive')) {
      return 'Your account is inactive or suspended. Please contact support.';
    }

    // Capitalize first letter if lowercased
    return msg[0].toUpperCase() + msg.substring(1);
  }
}
