import 'package:flutter/foundation.dart';

/// Logs a caught error/exception in a consistent, readable shape — used
/// wherever an operation fails, alongside showing the user a short
/// SnackbarManager message, so there's always a full error (and stack
/// trace, if given) in the console even though the user only ever sees a
/// one-line summary.
void logError(String action, Object error, [StackTrace? stackTrace]) {
  debugPrint('┌─ Error: $action');
  debugPrint('│  $error');
  if (stackTrace != null) {
    for (final line in stackTrace.toString().trimRight().split('\n')) {
      debugPrint('│  $line');
    }
  }
  debugPrint('└─');
}
