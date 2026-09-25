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
    if (!_isBenignHardwareKeyboardAssertion(details.exception)) {
      _showUnexpectedErrorSnackbar();
    }
  };

  PlatformDispatcher.instance.onError = (error, stackTrace) {
    logError('Uncaught async error', error, stackTrace);
    _showUnexpectedErrorSnackbar();
    return true;
  };
}

// A debug-only assert (stripped in release builds — see its own doc)
// inside Flutter's own HardwareKeyboard, not this app's code: macOS can
// swallow a key's KeyUp event (e.g. Cmd/Meta during a window/focus
// switch — this app juggles Focus across tabs for its own F5 bindings,
// see explorer.screen.dart's own doc), leaving Flutter's internal
// "pressed keys" registry stuck thinking that key is still down. The
// next KeyDown for the same physical key then fails this assertion —
// harmless key-tracking drift, not an actual app failure, so it's
// logged (for visibility) but doesn't alarm the user with a generic
// error snackbar the way a real uncaught error should.
// See https://github.com/flutter/flutter/issues/103656.
bool _isBenignHardwareKeyboardAssertion(Object exception) {
  return exception is AssertionError &&
      exception.message.toString().contains('physical key is already pressed');
}

void _showUnexpectedErrorSnackbar() {
  final context = SnackbarManager.navigatorKey.currentContext;
  if (context == null) return;
  SnackbarManager.show(AppLocalizations.of(context)!.errorUnexpected);
}
