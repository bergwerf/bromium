// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium;

/// Helper for measuring performance
class BromiumBenchmark {
  /// Stopwatch for mircosecond measurements.
  Stopwatch time = new Stopwatch();

  /// Number of elapsed microseconds at [start]
  Map<String, int> startMicro = new Map<String, int>();

  /// All measurements as Map<activity label, list of intervals (us)>
  Map<String, List<num>> measurements = new Map<String, List<num>>();

  /// Constuctor
  BromiumBenchmark() {
    time.start();
  }

  /// Start measuring an activity.
  void start(String label) {
    startMicro[label] = time.elapsedMicroseconds;
  }

  /// End measuring an activity.
  void end(String label) {
    measurements.putIfAbsent(label, () => new List<int>());
    measurements[label].add(time.elapsedMicroseconds - startMicro[label]);
  }

  /// Print measurements of all activities.
  void printAllMeasurements() {
    measurements.keys.forEach((String label) {
      printMeasurements(label);
    });
  }

  /// Print measurements of one activity.
  void printMeasurements(String label) {
    var m = measurements[label];

    // Compute average number of micro seconds.
    var avg = m.reduce((num prev, num elm) => prev + elm) / m.length;

    // Compute standard deviation in micro seconds.
    var stddev = 0.0;
    for (var i = 0; i < m.length; i++) {
      stddev += pow(m[i] - avg, 2);
    }
    stddev = sqrt(stddev / m.length);

    // Print measurement info.
    print('''
Measurements for '$label':
Average time (µs): $avg
Standard dev (µs): $stddev
''');

    // Print standard deviation in seconds.
  }
}
