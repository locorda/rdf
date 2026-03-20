# RDF Codec Performance Benchmark

Generated: 2026-03-20T12:10:28.226317

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
| Turtle        | 324 B                  | 47 µs      | 37 µs      | 6.6 MB/s     | 8.3 MB/s     | 100%     | 100%    |
| N-Triples     | 350 B                  | 8 µs       | 17 µs      | 39.3 MB/s    | 19.9 MB/s    | 108%     | 18%     |
| JSON-LD       | 440 B                  | 42 µs      | 28 µs      | 10.0 MB/s    | 14.9 MB/s    | 136%     | 90%     |
| RDF/XML       | 760 B                  | 62 µs      | 5.7 ms     | 11.8 MB/s    | 0.1 MB/s     | 235%     | 133%    |
| Jelly         | 210 B                  | 45 µs      | 35 µs      | 4.4 MB/s     | 5.7 MB/s     | 65%      | 97%     |

> Baseline: **Turtle** — enc 47 µs (6.6 MB/s), dec 37 µs (8.3 MB/s). Enc % < 100% = faster, > 100% = slower.

## Graph Codecs — Small (acl.ttl)

Source: acl.ttl · 93 triples · 7 KB source

| Format        | Out size (bytes)       | Enc time   | Dec time   | Enc MB/s     | Dec MB/s     | Size %   | Enc %   |
| :------------ | :--------------------- | :--------- | :--------- | :----------- | :----------- | :------- | :------ |
| Turtle        | 7 KB (7 107 B)         | 156 µs     | 467 µs     | 43.4 MB/s    | 14.5 MB/s    | 100%     | 100%    |
| N-Triples     | 15 KB (14 916 B)       | 114 µs     | 381 µs     | 124.5 MB/s   | 37.3 MB/s    | 210%     | 73%     |
| JSON-LD       | 9 KB (9 644 B)         | 136 µs     | 151 µs     | 67.4 MB/s    | 60.8 MB/s    | 136%     | 87%     |
| RDF/XML       | 10 KB (9 807 B)        | 215 µs     | 5.8 ms     | 43.5 MB/s    | 1.6 MB/s     | 138%     | 138%    |
| Jelly         | 6 KB (6 326 B)         | 209 µs     | 127 µs     | 28.8 MB/s    | 47.7 MB/s    | 89%      | 134%    |

> Baseline: **Turtle** — enc 156 µs (43.4 MB/s), dec 467 µs (14.5 MB/s). Enc % < 100% = faster, > 100% = slower.

## Graph Codecs — Large (schema.org.ttl)

Source: schema.org.ttl · 17.2k triples · 1.0 MB source

| Format        | Out size (bytes)       | Enc time   | Dec time   | Enc MB/s     | Dec MB/s     | Size %   | Enc %   |
| :------------ | :--------------------- | :--------- | :--------- | :----------- | :----------- | :------- | :------ |
| Turtle        | 1001 KB (1 024 861 B)  | 20 ms      | 81 ms      | 50.0 MB/s    | 12.1 MB/s    | 100%     | 100%    |
| N-Triples     | 2.1 MB (2 247 393 B)   | 21 ms      | 86 ms      | 101.2 MB/s   | 25.0 MB/s    | 219%     | 108%    |
| JSON-LD       | 1.4 MB (1 435 345 B)   | 21 ms      | 32 ms      | 66.4 MB/s    | 42.5 MB/s    | 140%     | 105%    |
| RDF/XML       | 1.4 MB (1 477 689 B)   | 44 ms      | 85 ms      | 32.1 MB/s    | 16.5 MB/s    | 144%     | 225%    |
| Jelly         | 755 KB (773 240 B)     | 56 ms      | 30 ms      | 13.1 MB/s    | 24.6 MB/s    | 75%      | 288%    |

> Baseline: **Turtle** — enc 20 ms (50.0 MB/s), dec 81 ms (12.1 MB/s). Enc % < 100% = faster, > 100% = slower.

## Dataset Codecs — Tiny (5 quads, synthetic)

Source: 5 synthetic quads (default graph)

| Format        | Out size (bytes)       | Enc time   | Dec time   | Enc MB/s     | Dec MB/s     | Size %   | Enc %   |
| :------------ | :--------------------- | :--------- | :--------- | :----------- | :----------- | :------- | :------ |
| TriG          | 324 B                  | 18 µs      | 25 µs      | 17.1 MB/s    | 12.4 MB/s    | 100%     | 100%    |
| N-Quads       | 350 B                  | 4 µs       | 13 µs      | 76.8 MB/s    | 26.1 MB/s    | 108%     | 24%     |
| JSON-LD       | 440 B                  | 18 µs      | 10 µs      | 23.2 MB/s    | 43.3 MB/s    | 136%     | 100%    |
| Jelly         | 212 B                  | 24 µs      | 17 µs      | 8.5 MB/s     | 11.6 MB/s    | 65%      | 132%    |

> Baseline: **TriG** — enc 18 µs (17.1 MB/s), dec 25 µs (12.4 MB/s). Enc % < 100% = faster, > 100% = slower.

## Dataset Codecs — Small

Source: acl.ttl (wrapped in default graph) · 93 quads

| Format        | Out size (bytes)       | Enc time   | Dec time   | Enc MB/s     | Dec MB/s     | Size %   | Enc %   |
| :------------ | :--------------------- | :--------- | :--------- | :----------- | :----------- | :------- | :------ |
| TriG          | 7 KB (7 107 B)         | 134 µs     | 470 µs     | 50.5 MB/s    | 14.4 MB/s    | 100%     | 100%    |
| N-Quads       | 15 KB (14 916 B)       | 103 µs     | 517 µs     | 138.7 MB/s   | 27.5 MB/s    | 210%     | 76%     |
| JSON-LD       | 9 KB (9 644 B)         | 135 µs     | 188 µs     | 68.1 MB/s    | 49.0 MB/s    | 136%     | 101%    |
| Jelly         | 6 KB (6 328 B)         | 218 µs     | 123 µs     | 27.7 MB/s    | 49.2 MB/s    | 89%      | 163%    |

> Baseline: **TriG** — enc 134 µs (50.5 MB/s), dec 470 µs (14.4 MB/s). Enc % < 100% = faster, > 100% = slower.

## Dataset Codecs — Large (shard.trig)

Source: shard-mod-md5.trig · 34.3k quads · 2.3 MB source

| Format        | Out size (bytes)       | Enc time   | Dec time   | Enc MB/s     | Dec MB/s     | Size %   | Enc %   |
| :------------ | :--------------------- | :--------- | :--------- | :----------- | :----------- | :------- | :------ |
| TriG          | 2.3 MB (2 463 952 B)   | 73 ms      | 173 ms     | 32.1 MB/s    | 13.6 MB/s    | 100%     | 100%    |
| N-Quads       | 12.8 MB (13 401 021 B) | 73 ms      | 409 ms     | 174.5 MB/s   | 31.3 MB/s    | 544%     | 100%    |
| JSON-LD       | 3.9 MB (4 072 259 B)   | 126 ms     | 827 ms     | 30.8 MB/s    | 4.7 MB/s     | 165%     | 172%    |
| Jelly         | 1.8 MB (1 853 608 B)   | 159 ms     | 72 ms      | 11.1 MB/s    | 24.5 MB/s    | 75%      | 217%    |

> Baseline: **TriG** — enc 73 ms (32.1 MB/s), dec 173 ms (13.6 MB/s). Enc % < 100% = faster, > 100% = slower.

---

*Benchmark run in JIT (dart run). Results reflect warm JIT throughput, not AOT-compiled production performance.*
