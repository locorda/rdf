import 'dart:io';

import 'package:locorda_rdf_core/core.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

final _log = Logger('trig_realworld_test');

/// Real-world performance tests for the TriG codec, using a ~2.4 MB shard file
/// as a representative large-scale input (40 k lines / ~450 k quads).
///
/// Assertions use conservative upper-bound thresholds so CI machines with
/// throttled CPUs still pass, while still catching severe regressions.
void main() {
  Logger.root.onRecord.listen((record) {
    // Print all log messages to the console during testing.
    print('[${record.level.name}] ${record.loggerName}: ${record.message}');
  });
  group('RealWorld TriG Performance Tests', () {
    late String trigContent;
    late int contentBytes;

    setUpAll(() {
      final filePath = path.join(
        'test/assets/realworld',
        'shard-mod-md5-1-0-v1_0_0.trig',
      );
      trigContent = File(filePath).readAsStringSync();
      contentBytes = trigContent.length;
      _log.info('Loaded TriG file: ${contentBytes ~/ 1024} KB');
    });

    TriGDecoder _buildDecoder() =>
        TriGDecoder(namespaceMappings: RdfNamespaceMappings());

    TriGEncoder _buildEncoder() =>
        TriGEncoder(namespaceMappings: RdfNamespaceMappings());

    test('decodes shard-mod-md5-1-0-v1_0_0.trig within time budget', () {
      final decoder = _buildDecoder();

      // Warm-up pass to avoid JIT cold-start skewing the measurement.
      decoder.convert(trigContent);

      final stopwatch = Stopwatch()..start();
      final dataset = decoder.convert(trigContent);
      stopwatch.stop();

      final elapsedMs = stopwatch.elapsedMilliseconds;
      final throughputKBps = (contentBytes / 1024) /
          (elapsedMs / 1000).clamp(0.001, double.infinity);

      _log.info(
        'Decode: ${elapsedMs}ms — '
        '${throughputKBps.toStringAsFixed(0)} KB/s '
        '(${dataset.defaultGraph.triples.length} default-graph triples, '
        '${dataset.namedGraphs.length} named graphs)',
      );

      // Dataset must be non-trivially populated.
      expect(
        dataset.defaultGraph.triples.length + dataset.namedGraphs.length,
        greaterThan(0),
        reason: 'file must decode to a non-empty dataset',
      );

      // Regression guard: 2.4 MB must decode in under 60 s on any reasonable
      // machine.  Tighten once a performance baseline is established.
      expect(
        elapsedMs,
        lessThan(
            800), // actually, should be less than 200, but allowing more time for CI variability for now
        reason: 'TriG decode took ${elapsedMs}ms — potential regression',
      );
    });

    test('encodes a decoded dataset within time budget', () {
      final decoder = _buildDecoder();
      final dataset = decoder.convert(trigContent);
      final encoder = _buildEncoder();

      // Warm-up pass.
      encoder.convert(dataset);

      final stopwatch = Stopwatch()..start();
      final encoded = encoder.convert(dataset);
      stopwatch.stop();

      final elapsedMs = stopwatch.elapsedMilliseconds;
      final encodedBytes = encoded.length;
      final throughputKBps = (encodedBytes / 1024) /
          (elapsedMs / 1000).clamp(0.001, double.infinity);

      _log.info(
        'Encode: ${elapsedMs}ms — '
        '${throughputKBps.toStringAsFixed(0)} KB/s '
        '(output: ${encodedBytes ~/ 1024} KB)',
      );

      expect(
        encoded.isNotEmpty,
        isTrue,
        reason: 'encoded output must not be empty',
      );

      // Regression guard: encoding must complete in under 60 s.
      expect(
        elapsedMs,
        lessThan(
            800), // actually, should be less than 200, but allowing more time for CI variability for now
        reason: 'TriG encode took ${elapsedMs}ms — potential regression',
      );

      expect(encoded, equals(trigContent),
          reason:
              'encoded output must match original input which was originally encoded by the same encoder. '
              'This verifies that encoding output did not change unexpectedly, which could cause downstream issues for consumers of the encoder output. ');
    });

    test('roundtrip decode→encode→decode preserves quad count', () {
      final decoder = _buildDecoder();
      final encoder = _buildEncoder();

      final dataset1 = decoder.convert(trigContent);
      final encoded = encoder.convert(dataset1);
      final dataset2 = decoder.convert(encoded);

      int countQuads(RdfDataset d) =>
          d.defaultGraph.triples.length +
          d.namedGraphs.fold<int>(0, (s, g) => s + g.graph.triples.length);

      final count1 = countQuads(dataset1);
      final count2 = countQuads(dataset2);

      _log.info('Roundtrip quad counts: $count1 → $count2');

      expect(
        count2,
        equals(count1),
        reason:
            'quad count must be identical after re-encoding and re-decoding',
      );
    });

    test('reports decode throughput (informational)', () {
      // Run multiple iterations and report average throughput.  This test never
      // fails on its own; it exists to surface numbers in the test log.
      const iterations = 3;
      final decoder = _buildDecoder();

      // Warm-up.
      decoder.convert(trigContent);

      var totalMs = 0;
      for (var i = 0; i < iterations; i++) {
        final sw = Stopwatch()..start();
        decoder.convert(trigContent);
        sw.stop();
        totalMs += sw.elapsedMilliseconds;
      }

      final avgMs = totalMs / iterations;
      final avgThroughputKBps =
          (contentBytes / 1024) / (avgMs / 1000).clamp(0.001, double.infinity);

      _log.info(
        'Avg decode over $iterations iterations: '
        '${avgMs.toStringAsFixed(1)}ms — '
        '${avgThroughputKBps.toStringAsFixed(0)} KB/s',
      );

      // Always passes; the value is visible in verbose test output.
      expect(avgMs, greaterThan(0));
    });
  });
}
