part of hop_tasks;

const _defaultRunCount = 20;

// TODO: options for handling failed processes?
// TODO: move some of the stat-related code to NumebrEnumerable?
// TODO: tests?

Task createBenchTask() {
  return new Task.async((ctx) {

    final parser = _getBenchParser();
    final parseResult = _helpfulParseArgs(ctx, parser, ctx.arguments);

    final count = int.parse(parseResult['run_count'], onError: (s) => _defaultRunCount);

    if(parseResult.rest.isEmpty) {
      ctx.fail('No command provided.');
    }

    final processName = parseResult.rest.first;
    final args = parseResult.rest.getRange(1, parseResult.rest.length-1);

    return _runMany(ctx, count, processName, args)
        .then((list) {
          final values = list.map((brr) => brr.executionDuration.inMilliseconds);
          final stats = new _Stats(values);
          ctx.info(stats.toString());
          return true;
        });

  }, 'Run a benchmark against the provided task');
}

ArgParser _getBenchParser() =>
  new ArgParser()
    ..addOption('run_count', abbr: 'r', defaultsTo: _defaultRunCount.toString());

Future<List<_BenchRunResult>> _runMany(TaskLogger logger, int count, String processName, List<String> args) {

  assert(count > 1);
  final countStrLength = count.toString().length;

  final range = new Iterable.generate(count, (i) => i);
  final results = new List<_BenchRunResult>();

  return Future.forEach(range, (i) {
    return _runOnce(i+1, processName, args)
        .then((result) {
          final paddedNumber = Util.padLeft(result.runNumber.toString(), countStrLength);
          logger.fine("Test $paddedNumber of $count - ${result.executionDuration}");
          results.add(result);
        });
    })
    .then((_) {
      return results;
    });
}

Future<_BenchRunResult> _runOnce(int runNumber, String processName, List<String> args) {
  final preStart = new Date.now();
  Date postStart;

  return Process.start(processName, args)
      .then((process) {
        postStart = new Date.now();
        return pipeProcess(process);
      })
      .then((int exitCode) {
        return new _BenchRunResult(runNumber, exitCode == 0, preStart, postStart, new Date.now());
      });
}

class _BenchRunResult {
  final int runNumber;
  final Date preStart;
  final Date postStart;
  final Date postEnd;
  final bool completed;

  _BenchRunResult(this.runNumber, this.completed, this.preStart, this.postStart, this.postEnd);

  Duration get startupDelta => postStart.difference(preStart);

  Duration get executionDuration => postEnd.difference(postStart);

  String toString() => '''
$runNumber
${startupDelta.inMilliseconds}
${executionDuration.inMilliseconds}
$completed''';
}

class _Stats {
  final num mean;
  final num median;
  final num max;
  final num min;
  final num standardDeviation;

  _Stats.raw(this.mean, this.median, this.max, this.min, this.standardDeviation);

  factory _Stats(Iterable<num> source) {
    assert(source != null);
    assert(!source.isEmpty);

    final list = source.toList()
        ..sort();

    final max = list.last;
    final min = list.first;

    num sum = 0;

    list.forEach((num value) {
      sum += value;
    });

    final mean = sum / list.length;

    // variance
    // The average of the squared difference from the Mean

    num sumOfSquaredDiffFromMean = 0;
    list.forEach((num value) {
      final squareDiffFromMean = math.pow(value - mean, 2);
      sumOfSquaredDiffFromMean += squareDiffFromMean;
    });

    final variance = sumOfSquaredDiffFromMean / list.length;
    final standardDeviation = math.sqrt(variance);

    num median = null;
    // if length is odd, take middle value
    if(list.length % 2 == 1) {
      final middleIndex = (list.length / 2 - 0.5).toInt();
      median = list[middleIndex];
    } else {
      final secondMiddle = list.length ~/ 2;
      final firstMiddle = secondMiddle - 1;
      median = (list[firstMiddle] + list[secondMiddle]) / 2.0;
    }

    return new _Stats.raw(mean, median, max, min, standardDeviation);
  }

  String toString() => '''
Min:    $min
Max:    $max
Median: $median
Mean:   $mean
StdDev: $standardDeviation''';
}
