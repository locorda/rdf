# RDF Codec Performance Benchmark

Generated: 2026-03-20T12:28:20.649019

## Versions

| Package | Version |
| :------ | :------ |
| locorda_rdf_core | 0.11.10 |
| locorda_rdf_jelly | 0.11.10 |
| locorda_rdf_xml | 0.11.10 |
| Dart SDK | 3.10.8 |
| Platform | macos (Version 26.3.1) |

## Column guide

- **Out size (bytes)** — encoded output size: human-readable + exact byte count (UTF-8 bytes for text formats, raw bytes for Jelly binary)
- **Enc/Dec time** — average per-operation latency
- **Enc/Dec MB/s** — throughput: `encoded_bytes / wall_time`
- **Size %** — output size relative to baseline format (100% = same size)
- **Enc %** — encode latency relative to baseline (< 100% = faster)


## Graph Codecs — Tiny (5 triples, synthetic)

Source: 5 synthetic triples (schema:name literals)

| Format        | Out size (bytes)       | Enc time   | Dec time   | Enc MB/s     | Dec MB/s     | Size %   | Enc %   |
| :------------ | :--------------------- | :--------- | :--------- | :----------- | :----------- | :------- | :------ |
| Turtle        | 324 B                  | 50 µs      | 35 µs      | 6.1 MB/s     | 8.9 MB/s     | 100%     | 100%    |
| N-Triples     | 350 B                  | 12 µs      | 17 µs      | 28.6 MB/s    | 19.1 MB/s    | 108%     | 23%     |
| JSON-LD       | 440 B                  | 44 µs      | 29 µs      | 9.5 MB/s     | 14.5 MB/s    | 136%     | 88%     |
| RDF/XML       | 760 B                  | 60 µs      | 5.6 ms     | 12.2 MB/s    | 0.1 MB/s     | 235%     | 118%    |
| Jelly         | 210 B                  | 37 µs      | 40 µs      | 5.4 MB/s     | 5.0 MB/s     | 65%      | 74%     |

> Baseline: **Turtle** — enc 50 µs (6.1 MB/s), dec 35 µs (8.9 MB/s). Enc % < 100% = faster, > 100% = slower.

## Graph Codecs — Small (acl.ttl)

Source: acl.ttl · 93 triples · 7 KB source

| Format        | Out size (bytes)       | Enc time   | Dec time   | Enc MB/s     | Dec MB/s     | Size %   | Enc %   |
| :------------ | :--------------------- | :--------- | :--------- | :----------- | :----------- | :------- | :------ |
| Turtle        | 7 KB (7 107 B)         | 162 µs     | 474 µs     | 41.9 MB/s    | 14.3 MB/s    | 100%     | 100%    |
| N-Triples     | 15 KB (14 916 B)       | 115 µs     | 390 µs     | 123.2 MB/s   | 36.4 MB/s    | 210%     | 71%     |
| JSON-LD       | 9 KB (9 644 B)         | 140 µs     | 154 µs     | 65.5 MB/s    | 59.9 MB/s    | 136%     | 87%     |
| RDF/XML       | 10 KB (9 807 B)        | 219 µs     | 5.8 ms     | 42.7 MB/s    | 1.6 MB/s     | 138%     | 135%    |
| Jelly         | 6 KB (6 326 B)         | 151 µs     | 123 µs     | 40.1 MB/s    | 49.2 MB/s    | 89%      | 93%     |

> Baseline: **Turtle** — enc 162 µs (41.9 MB/s), dec 474 µs (14.3 MB/s). Enc % < 100% = faster, > 100% = slower.

## Graph Codecs — Large (schema.org.ttl)

Source: schema.org.ttl · 17.2k triples · 1.0 MB source

| Format        | Out size (bytes)       | Enc time   | Dec time   | Enc MB/s     | Dec MB/s     | Size %   | Enc %   |
| :------------ | :--------------------- | :--------- | :--------- | :----------- | :----------- | :------- | :------ |
| Turtle        | 1001 KB (1 024 861 B)  | 19 ms      | 82 ms      | 51.1 MB/s    | 12.0 MB/s    | 100%     | 100%    |
| N-Triples     | 2.1 MB (2 247 393 B)   | 21 ms      | 87 ms      | 101.0 MB/s   | 24.7 MB/s    | 219%     | 111%    |
| JSON-LD       | 1.4 MB (1 435 345 B)   | 21 ms      | 33 ms      | 66.1 MB/s    | 41.4 MB/s    | 140%     | 108%    |
| RDF/XML       | 1.4 MB (1 477 689 B)   | 45 ms      | 85 ms      | 31.6 MB/s    | 16.6 MB/s    | 144%     | 233%    |
| Jelly         | 755 KB (773 240 B)     | 41 ms      | 29 ms      | 18.0 MB/s    | 25.3 MB/s    | 75%      | 214%    |

> Baseline: **Turtle** — enc 19 ms (51.1 MB/s), dec 82 ms (12.0 MB/s). Enc % < 100% = faster, > 100% = slower.

## Dataset Codecs — Tiny (5 quads, synthetic)

Source: 5 synthetic quads (default graph)

| Format        | Out size (bytes)       | Enc time   | Dec time   | Enc MB/s     | Dec MB/s     | Size %   | Enc %   |
| :------------ | :--------------------- | :--------- | :--------- | :----------- | :----------- | :------- | :------ |
| TriG          | 324 B                  | 16 µs      | 25 µs      | 18.7 MB/s    | 12.4 MB/s    | 100%     | 100%    |
| N-Quads       | 350 B                  | 4 µs       | 13 µs      | 76.0 MB/s    | 25.5 MB/s    | 108%     | 27%     |
| JSON-LD       | 440 B                  | 18 µs      | 10 µs      | 23.0 MB/s    | 43.9 MB/s    | 136%     | 111%    |
| Jelly         | 212 B                  | 21 µs      | 17 µs      | 9.7 MB/s     | 11.8 MB/s    | 65%      | 126%    |

> Baseline: **TriG** — enc 16 µs (18.7 MB/s), dec 25 µs (12.4 MB/s). Enc % < 100% = faster, > 100% = slower.

## Dataset Codecs — Small

Source: acl.ttl (wrapped in default graph) · 93 quads

| Format        | Out size (bytes)       | Enc time   | Dec time   | Enc MB/s     | Dec MB/s     | Size %   | Enc %   |
| :------------ | :--------------------- | :--------- | :--------- | :----------- | :----------- | :------- | :------ |
| TriG          | 7 KB (7 107 B)         | 134 µs     | 471 µs     | 50.5 MB/s    | 14.4 MB/s    | 100%     | 100%    |
| N-Quads       | 15 KB (14 916 B)       | 105 µs     | 524 µs     | 135.9 MB/s   | 27.1 MB/s    | 210%     | 78%     |
| JSON-LD       | 9 KB (9 644 B)         | 139 µs     | 146 µs     | 66.2 MB/s    | 63.0 MB/s    | 136%     | 104%    |
| Jelly         | 6 KB (6 328 B)         | 154 µs     | 119 µs     | 39.3 MB/s    | 50.9 MB/s    | 89%      | 114%    |

> Baseline: **TriG** — enc 134 µs (50.5 MB/s), dec 471 µs (14.4 MB/s). Enc % < 100% = faster, > 100% = slower.

## Dataset Codecs — Large (shard.trig)

Source: shard-mod-md5.trig · 34.3k quads · 2.3 MB source

| Format        | Out size (bytes)       | Enc time   | Dec time   | Enc MB/s     | Dec MB/s     | Size %   | Enc %   |
| :------------ | :--------------------- | :--------- | :--------- | :----------- | :----------- | :------- | :------ |
| TriG          | 2.3 MB (2 463 952 B)   | 73 ms      | 168 ms     | 32.3 MB/s    | 13.9 MB/s    | 100%     | 100%    |
| N-Quads       | 12.8 MB (13 401 021 B) | 71 ms      | 408 ms     | 180.3 MB/s   | 31.3 MB/s    | 544%     | 97%     |
| JSON-LD       | 3.9 MB (4 072 259 B)   | 123 ms     | 822 ms     | 31.7 MB/s    | 4.7 MB/s     | 165%     | 168%    |
| Jelly         | 1.8 MB (1 853 608 B)   | 99 ms      | 75 ms      | 17.9 MB/s    | 23.5 MB/s    | 75%      | 135%    |

> Baseline: **TriG** — enc 73 ms (32.3 MB/s), dec 168 ms (13.9 MB/s). Enc % < 100% = faster, > 100% = slower.

---

*Benchmark run in JIT (dart run). Results reflect warm JIT throughput, not AOT-compiled production performance.*
