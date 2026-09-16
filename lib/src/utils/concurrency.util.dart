import 'error_logging.util.dart';

/// Runs [tasks] with at most [concurrency] running at once, rather than
/// firing them all in parallel (e.g. via `Future.wait`) or one at a time.
/// Each of [concurrency] workers pulls the next task off the shared queue
/// as soon as it finishes its current one, so slower tasks don't hold up
/// starting the rest.
///
/// One task throwing doesn't abort the rest of the batch — this is
/// typically used to fan out over dozens/hundreds of independent
/// per-project operations (size calculation, cleanup, sub-package
/// loading, ...), where one project hitting a filesystem error shouldn't
/// also silently cancel every other project's own task that just hadn't
/// started yet.
Future<void> runWithConcurrency(
  List<Future<void> Function()> tasks, {
  required int concurrency,
}) async {
  if (tasks.isEmpty) return;
  final queue = tasks.iterator;

  Future<void> worker() async {
    while (queue.moveNext()) {
      try {
        await queue.current();
      } on Object catch (error, stackTrace) {
        logError('Concurrent task failed', error, stackTrace);
      }
    }
  }

  final workerCount = concurrency.clamp(1, tasks.length);
  await Future.wait(List.generate(workerCount, (_) => worker()));
}
