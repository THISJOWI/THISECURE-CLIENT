import 'dart:async';
import 'package:flutter/material.dart';
import 'package:thisjowi/services/autofillService.dart';
import 'package:thisjowi/screens/password/SavePasswordDialog.dart';

/// Service to handle autofill save requests
/// This monitors for autofill save intents and shows the save dialog
class AutofillSaveHandler {
  static final AutofillSaveHandler _instance = AutofillSaveHandler._internal();

  factory AutofillSaveHandler() => _instance;

  AutofillSaveHandler._internal();

  final AutofillService _autofillService = AutofillService();
  Timer? _checkTimer;
  bool _isChecking = false;
  bool _hasProcessedRequest = false;

  /// Start monitoring for autofill save requests
  void startMonitoring(BuildContext context) {
    _checkForPendingRequest(context);

    _checkTimer?.cancel();
    _checkTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!_isChecking && !_hasProcessedRequest) {
        _checkForPendingRequest(context);
      }
    });
  }

  /// Stop monitoring for autofill save requests
  void stopMonitoring() {
    _checkTimer?.cancel();
    _checkTimer = null;
  }

  /// Check for pending autofill save request and show dialog if found
  Future<void> _checkForPendingRequest(BuildContext context) async {
    if (_isChecking) return;

    _isChecking = true;

    try {
      final request = await _autofillService.getPendingAutofillRequest();

      if (request != null && request.isSaveRequest) {
        _hasProcessedRequest = true;
        // We have a save request - show the dialog
        if (context.mounted) {
          _showSavePasswordDialog(
            context,
            username: request.username,
            password: request.password,
            packageName: request.targetPackage,
            url: request.targetUrl,
          );
        }
      }
    } catch (e) {
      debugPrint('Error checking for autofill request: $e');
    } finally {
      _isChecking = false;
    }
  }

  /// Show the save password dialog
  void _showSavePasswordDialog(
    BuildContext context, {
    String? username,
    String? password,
    String? packageName,
    String? url,
  }) {
    // Don't show if already showing a dialog
    if (ModalRoute.of(context)?.isCurrent != true) {
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SavePasswordDialog(
        username: username,
        password: password,
        packageName: packageName,
        url: url,
      ),
    );
  }

  /// Manually trigger a check for pending requests
  /// Useful when app comes to foreground
  Future<void> checkNow(BuildContext context) async {
    await _checkForPendingRequest(context);
  }
}
