/// A minimal cooperative-cancellation flag: long-running work checks
/// [isCancelled] periodically and bails out early once [cancel] is called,
/// instead of running to completion for a result nobody will use.
class CancellationToken {
  bool _cancelled = false;

  bool get isCancelled => _cancelled;

  void cancel() {
    _cancelled = true;
  }
}
