import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../widgets/ui_kit/notifications/snackbar_manager.dart';
import 'error_logging.util.dart';

/// Wires Flutter's two global error channels — [FlutterError.onError] for
/// failures during build/layout/paint, [PlatformDispatcher.onError] for
/// anything thrown outside a caught try/catch (a stray Future, a timer
/// callback, ...) — to the same logError + [SnackbarManager] pattern every
/// caught use-case/repo failure already goes through (see
/// error_logging.util.dart), so an error that slips past that per-call-site
/// handling still gets logged and surfaces to the user with a generic
/// message instead of just vanishing into the console or crashing silently.
///
/// Call once, before [runApp] (see main.dart). Needs no [BuildContext] of
/// its own — like [SnackbarManager], it reaches for one lazily via
/// [SnackbarManager.navigatorKey] only once an error actually fires, by
/// which point the app is built and one exists.
void installGlobalErrorHandlers() {
  final presentFrameworkError = FlutterError.onError;
  FlutterError.onError = (details) {
    presentFrameworkError?.call(details);
    logError('Uncaught framework error', details.exception, details.stack);
    _showUnexpectedErrorSnackbar();
  };

  PlatformDispatcher.instance.onError = (error, stackTrace) {
    logError('Uncaught async error', error, stackTrace);
    _showUnexpectedErrorSnackbar();
    return true;
  };
}

void _showUnexpectedErrorSnackbar() {
  final context = SnackbarManager.navigatorKey.currentContext;
  if (context == null) return;
  SnackbarManager.show(AppLocalizations.of(context)!.errorUnexpected);
}
