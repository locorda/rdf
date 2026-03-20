# RDF Codec Performance Benchmark

Generated: 2026-03-20T11:50:29.141748

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
| Turtle        | 324 B                  | 53 µs      | 34 µs      | 5.8 MB/s     | 9.2 MB/s     | 100%     | 100%    |
| N-Triples     | 350 B                  | 8 µs       | 17 µs      | 39.4 MB/s    | 20.1 MB/s    | 108%     | 16%     |
| JSON-LD       | 440 B                  | 41 µs      | 28 µs      | 10.2 MB/s    | 14.8 MB/s    | 136%     | 77%     |
| RDF/XML       | 760 B                  | 62 µs      | 5.7 ms     | 11.7 MB/s    | 0.1 MB/s     | 235%     | 116%    |
| Jelly         | 210 B                  | 43 µs      | 36 µs      | 4.7 MB/s     | 5.5 MB/s     | 65%      | 81%     |

> Baseline: **Turtle** — enc 53 µs (5.8 MB/s), dec 34 µs (9.2 MB/s). Enc % < 100% = faster, > 100% = slower.

## Graph Codecs — Small (acl.ttl)

Source: acl.ttl · 93 triples · 7 KB source

| Format        | Out size (bytes)       | Enc time   | Dec time   | Enc MB/s     | Dec MB/s     | Size %   | Enc %   |
| :------------ | :--------------------- | :--------- | :--------- | :----------- | :----------- | :------- | :------ |
| Turtle        | 7 KB (7 107 B)         | 158 µs     | 485 µs     | 43.0 MB/s    | 14.0 MB/s    | 100%     | 100%    |
| N-Triples     | 15 KB (14 916 B)       | 112 µs     | 379 µs     | 127.1 MB/s   | 37.6 MB/s    | 210%     | 71%     |
| JSON-LD       | 9 KB (9 644 B)         | 137 µs     | 151 µs     | 66.9 MB/s    | 61.0 MB/s    | 136%     | 87%     |
| RDF/XML       | 10 KB (9 807 B)        | 215 µs     | 5.7 ms     | 43.5 MB/s    | 1.6 MB/s     | 138%     | 136%    |
| Jelly         | 6 KB (6 326 B)         | 213 µs     | 122 µs     | 28.3 MB/s    | 49.6 MB/s    | 89%      | 135%    |

> Baseline: **Turtle** — enc 158 µs (43.0 MB/s), dec 485 µs (14.0 MB/s). Enc % < 100% = faster, > 100% = slower.

## Graph Codecs — Large (schema.org.ttl)

Source: schema.org.ttl · 17.2k triples · 1.0 MB source

| Format        | Out size (bytes)       | Enc time   | Dec time   | Enc MB/s     | Dec MB/s     | Size %   | Enc %   |
| :------------ | :--------------------- | :--------- | :--------- | :----------- | :----------- | :------- | :------ |
| Turtle        | 1001 KB (1 024 861 B)  | 19 ms      | 81 ms      | 51.4 MB/s    | 12.1 MB/s    | 100%     | 100%    |
| N-Triples     | 2.1 MB (2 247 393 B)   | 21 ms      | 85 ms      | 103.2 MB/s   | 25.1 MB/s    | 219%     | 109%    |
| JSON-LD       | 1.4 MB (1 435 345 B)   | 20 ms      | 32 ms      | 67.0 MB/s    | 42.6 MB/s    | 140%     | 108%    |
| RDF/XML       | 1.4 MB (1 477 689 B)   | 44 ms      | 85 ms      | 32.3 MB/s    | 16.6 MB/s    | 144%     | 230%    |
| Jelly         | 755 KB (773 240 B)     | 71 ms      | 29 ms      | 10.4 MB/s    | 25.5 MB/s    | 75%      | 372%    |

> Baseline: **Turtle** — enc 19 ms (51.4 MB/s), dec 81 ms (12.1 MB/s). Enc % < 100% = faster, > 100% = slower.

## Dataset Codecs — Tiny (5 quads, synthetic)

Source: 5 synthetic quads (default graph)

| Format        | Out size (bytes)       | Enc time   | Dec time   | Enc MB/s     | Dec MB/s     | Size %   | Enc %   |
| :------------ | :--------------------- | :--------- | :--------- | :----------- | :----------- | :------- | :------ |
| TriG          | 324 B                  | 18 µs      | 25 µs      | 17.6 MB/s    | 12.2 MB/s    | 100%     | 100%    |
| N-Quads       | 350 B                  | 4 µs       | 13 µs      | 78.3 MB/s    | 26.3 MB/s    | 108%     | 24%     |
| JSON-LD       | 440 B                  | 18 µs      | 9 µs       | 23.8 MB/s    | 44.3 MB/s    | 136%     | 100%    |
| Jelly         | 212 B                  | 23 µs      | 18 µs      | 8.7 MB/s     | 11.5 MB/s    | 65%      | 132%    |

> Baseline: **TriG** — enc 18 µs (17.6 MB/s), dec 25 µs (12.2 MB/s). Enc % < 100% = faster, > 100% = slower.

## Dataset Codecs — Small

Source: acl.ttl (wrapped in default graph) · 93 quads

| Format        | Out size (bytes)       | Enc time   | Dec time   | Enc MB/s     | Dec MB/s     | Size %   | Enc %   |
| :------------ | :--------------------- | :--------- | :--------- | :----------- | :----------- | :------- | :------ |
| TriG          | 7 KB (7 107 B)         | 136 µs     | 469 µs     | 49.7 MB/s    | 14.5 MB/s    | 100%     | 100%    |
| N-Quads       | 15 KB (14 916 B)       | 104 µs     | 526 µs     | 136.3 MB/s   | 27.1 MB/s    | 210%     | 76%     |
| JSON-LD       | 9 KB (9 644 B)         | 139 µs     | 147 µs     | 66.0 MB/s    | 62.7 MB/s    | 136%     | 102%    |
| Jelly         | 6 KB (6 328 B)         | 226 µs     | 120 µs     | 26.7 MB/s    | 50.4 MB/s    | 89%      | 166%    |

> Baseline: **TriG** — enc 136 µs (49.7 MB/s), dec 469 µs (14.5 MB/s). Enc % < 100% = faster, > 100% = slower.

## Dataset Codecs — Large (shard.trig)

Source: shard-mod-md5.trig · 34.3k quads · 2.3 MB source

| Format        | Out size (bytes)       | Enc time   | Dec time   | Enc MB/s     | Dec MB/s     | Size %   | Enc %   |
| :------------ | :--------------------- | :--------- | :--------- | :----------- | :----------- | :------- | :------ |
| TriG          | 2.3 MB (2 463 952 B)   | 78 ms      | 169 ms     | 30.3 MB/s    | 13.9 MB/s    | 100%     | 100%    |
| N-Quads       | 12.8 MB (13 401 021 B) | 71 ms      | 405 ms     | 179.8 MB/s   | 31.6 MB/s    | 544%     | 92%     |
| JSON-LD       | 3.9 MB (4 072 259 B)   | 123 ms     | 833 ms     | 31.5 MB/s    | 4.7 MB/s     | 165%     | 159%    |
| Jelly         | 1.8 MB (1 853 608 B)   | 176 ms     | 73 ms      | 10.0 MB/s    | 24.2 MB/s    | 75%      | 227%    |

> Baseline: **TriG** — enc 78 ms (30.3 MB/s), dec 169 ms (13.9 MB/s). Enc % < 100% = faster, > 100% = slower.

---

*Benchmark run in JIT (dart run). Results reflect warm JIT throughput, not AOT-compiled production performance.*
