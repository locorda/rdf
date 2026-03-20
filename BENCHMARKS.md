# RDF Codec Performance Benchmark

Generated: 2026-03-20T12:38:43.261051

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
- **Size %** — output size relative to baseline format (100% = same size)
- **Enc/Dec %** — encode/decode latency relative to baseline (< 100% = faster)


## Graph Codecs — Tiny (5 triples, synthetic)

Source: 5 synthetic triples (schema:name literals)

| Format        | Out size (bytes)       | Enc time   | Dec time   | Size %   | Enc %   | Dec %   |
| :------------ | :--------------------- | :--------- | :--------- | :------- | :------ | :------ |
| Turtle        | 324 B                  | 48 µs      | 35 µs      | 100%     | 100%    | 100%    |
| N-Triples     | 350 B                  | **12 µs**  | **17 µs**  | 108%     | **24%** | **48%** |
| JSON-LD       | 440 B                  | 43 µs      | 29 µs      | 136%     | 89%     | 83%     |
| RDF/XML       | 760 B                  | 58 µs      | 5.8 ms     | 235%     | 121%    | 16482%  |
| Jelly         | **210 B**              | 37 µs      | 40 µs      | **65%**  | 76%     | 115%    |

> Baseline: **Turtle** — enc 48 µs, dec 35 µs. Enc/Dec % < 100% = faster, > 100% = slower.

## Graph Codecs — Small (acl.ttl)

Source: acl.ttl · 93 triples · 7 KB source

| Format        | Out size (bytes)       | Enc time   | Dec time   | Size %   | Enc %   | Dec %   |
| :------------ | :--------------------- | :--------- | :--------- | :------- | :------ | :------ |
| Turtle        | 7 KB (7 107 B)         | 161 µs     | 474 µs     | 100%     | 100%    | 100%    |
| N-Triples     | 15 KB (14 916 B)       | **113 µs** | 385 µs     | 210%     | **70%** | 81%     |
| JSON-LD       | 9 KB (9 644 B)         | 140 µs     | 153 µs     | 136%     | 87%     | 32%     |
| RDF/XML       | 10 KB (9 807 B)        | 217 µs     | 5.8 ms     | 138%     | 135%    | 1224%   |
| Jelly         | **6 KB (6 326 B)**     | 151 µs     | **124 µs** | **89%**  | 94%     | **26%** |

> Baseline: **Turtle** — enc 161 µs, dec 474 µs. Enc/Dec % < 100% = faster, > 100% = slower.

## Graph Codecs — Large (schema.org.ttl)

Source: schema.org.ttl · 17.2k triples · 1.0 MB source

| Format        | Out size (bytes)       | Enc time   | Dec time   | Size %   | Enc %   | Dec %   |
| :------------ | :--------------------- | :--------- | :--------- | :------- | :------ | :------ |
| Turtle        | 1001 KB (1 024 861 B)  | **19 ms**  | 81 ms      | 100%     | **100%** | 100%    |
| N-Triples     | 2.1 MB (2 247 393 B)   | 21 ms      | 87 ms      | 219%     | 109%    | 107%    |
| JSON-LD       | 1.4 MB (1 435 345 B)   | 21 ms      | 32 ms      | 140%     | 108%    | 40%     |
| RDF/XML       | 1.4 MB (1 477 689 B)   | 44 ms      | 86 ms      | 144%     | 229%    | 107%    |
| Jelly         | **755 KB (773 240 B)** | 40 ms      | **29 ms**  | **75%**  | 206%    | **36%** |

> Baseline: **Turtle** — enc 19 ms, dec 81 ms. Enc/Dec % < 100% = faster, > 100% = slower.

## Dataset Codecs — Tiny (5 quads, synthetic)

Source: 5 synthetic quads (default graph)

| Format        | Out size (bytes)       | Enc time   | Dec time   | Size %   | Enc %   | Dec %   |
| :------------ | :--------------------- | :--------- | :--------- | :------- | :------ | :------ |
| TriG          | 324 B                  | 17 µs      | 25 µs      | 100%     | 100%    | 100%    |
| N-Quads       | 350 B                  | **4 µs**   | 13 µs      | 108%     | **24%** | 51%     |
| JSON-LD       | 440 B                  | 18 µs      | **9 µs**   | 136%     | 102%    | **38%** |
| Jelly         | **212 B**              | 21 µs      | 17 µs      | **65%**  | 121%    | 66%     |

> Baseline: **TriG** — enc 17 µs, dec 25 µs. Enc/Dec % < 100% = faster, > 100% = slower.

## Dataset Codecs — Small

Source: acl.ttl (wrapped in default graph) · 93 quads

| Format        | Out size (bytes)       | Enc time   | Dec time   | Size %   | Enc %   | Dec %   |
| :------------ | :--------------------- | :--------- | :--------- | :------- | :------ | :------ |
| TriG          | 7 KB (7 107 B)         | 134 µs     | 470 µs     | 100%     | 100%    | 100%    |
| N-Quads       | 15 KB (14 916 B)       | **102 µs** | 523 µs     | 210%     | **76%** | 111%    |
| JSON-LD       | 9 KB (9 644 B)         | 137 µs     | 146 µs     | 136%     | 102%    | 31%     |
| Jelly         | **6 KB (6 328 B)**     | 154 µs     | **119 µs** | **89%**  | 115%    | **25%** |

> Baseline: **TriG** — enc 134 µs, dec 470 µs. Enc/Dec % < 100% = faster, > 100% = slower.

## Dataset Codecs — Large (shard.trig)

Source: shard-mod-md5.trig · 34.3k quads · 2.3 MB source

| Format        | Out size (bytes)       | Enc time   | Dec time   | Size %   | Enc %   | Dec %   |
| :------------ | :--------------------- | :--------- | :--------- | :------- | :------ | :------ |
| TriG          | 2.3 MB (2 463 952 B)   | 72 ms      | 167 ms     | 100%     | 100%    | 100%    |
| N-Quads       | 12.8 MB (13 401 021 B) | **70 ms**  | 403 ms     | 544%     | **98%** | 241%    |
| JSON-LD       | 3.9 MB (4 072 259 B)   | 121 ms     | 819 ms     | 165%     | 168%    | 490%    |
| Jelly         | **1.8 MB (1 853 608 B)** | 95 ms      | **72 ms**  | **75%**  | 132%    | **43%** |

> Baseline: **TriG** — enc 72 ms, dec 167 ms. Enc/Dec % < 100% = faster, > 100% = slower.

---

*Benchmark run in JIT (dart run). Results reflect warm JIT throughput, not AOT-compiled production performance.*
