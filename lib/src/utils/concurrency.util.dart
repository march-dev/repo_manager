/// Runs [tasks] with at most [concurrency] running at once, rather than
/// firing them all in parallel (e.g. via `Future.wait`) or one at a time.
/// Each of [concurrency] workers pulls the next task off the shared queue
/// as soon as it finishes its current one, so slower tasks don't hold up
/// starting the rest.
Future<void> runWithConcurrency(
  List<Future<void> Function()> tasks, {
  required int concurrency,
}) async {
  if (tasks.isEmpty) return;
  final queue = tasks.iterator;

  Future<void> worker() async {
    while (queue.moveNext()) {
      await queue.current();
    }
  }

  final workerCount = concurrency.clamp(1, tasks.length);
  await Future.wait(List.generate(workerCount, (_) => worker()));
}
