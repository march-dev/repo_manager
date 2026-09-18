/// Runs an async action, coalescing repeat triggers that arrive while it's
/// already running rather than starting a second one alongside it.
///
/// A [CoalescingTrigger] can't just memoize/share the in-flight [Future]
/// between calls the way a simple cache would — a trigger arriving after
/// whatever changed the underlying state (e.g. a config change) would then
/// get handed a stale result from before that change. Instead, a trigger
/// that arrives mid-run marks one more run as pending, which starts only
/// once the current one finishes — so at most one run is ever in flight,
/// and the latest trigger is never lost, only deferred.
class CoalescingTrigger {
  CoalescingTrigger(this._run);

  final Future<void> Function() _run;

  bool _inFlight = false;
  bool _pending = false;

  Future<void> fire() async {
    if (_inFlight) {
      _pending = true;
      return;
    }
    _inFlight = true;
    do {
      _pending = false;
      await _run();
    } while (_pending);
    _inFlight = false;
  }
}
