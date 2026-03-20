# locorda_rdf_benchmark

Performance benchmarks for all RDF codecs in the [locorda_rdf](https://github.com/locorda/rdf) suite.

This is an internal development tool — it is **not published to pub.dev**.

## What it measures

Each codec is benchmarked across three dataset sizes:

| Size  | Graph source          | Dataset source              |
| :---- | :-------------------- | :-------------------------- |
| tiny  | 5 synthetic triples   | 5 synthetic quads           |
| small | `acl.ttl` (~93 triples) | `acl.ttl` wrapped (~93 quads) |
| large | `schema.org.ttl` (~17 k triples) | `shard-mod-md5.trig` (~34 k quads) |

Metrics reported per codec:

- **Out size** — encoded output: human-readable size + exact byte count
- **Enc / Dec time** — average per-operation latency
- **Enc / Dec MB/s** — throughput (`encoded_bytes / wall_time`)
- **Size %** — output size relative to the baseline codec (Turtle / TriG)
- **Enc %** — encode latency relative to baseline (< 100 % = faster)

The baseline for graph codecs is **Turtle**; for dataset codecs it is **TriG**.

## Running

From the workspace root or from this package directory:

```sh
dart run packages/locorda_rdf_benchmark/bin/codec_benchmark.dart
```

Or from inside the package:

```sh
cd packages/locorda_rdf_benchmark
dart run bin/codec_benchmark.dart
```

### Saving results to BENCHMARKS.md

Pass `--save` to write the full Markdown output (including a version table) to
`BENCHMARKS.md` in the workspace root:

```sh
dart run bin/codec_benchmark.dart --save
```

The saved file is checked into the repository so results can be compared across
commits without running the benchmark locally.

## Benchmark methodology

- **Warm-up**: 3 iterations discarded before measurement.
- **Adaptive iteration count**: a probe run estimates the per-iteration cost;
  the harness then clamps iterations to `[3, 1000]` targeting ~3 s of total
  wall time per scenario. This balances accuracy for fast codecs and patience
  for slow ones.
- **Throughput** is calculated as `encoded_bytes × iterations / total_wall_time`,
  so it reflects the output size of the specific format, not the input size.
- **JIT only** — benchmarks run under `dart run` (JIT). AOT-compiled throughput
  will differ.

## Test assets

Source files are loaded from
`packages/locorda_rdf_core/test/assets/realworld/` at runtime. The benchmark
resolves this path relative to its own script location, so it works from any
working directory.
