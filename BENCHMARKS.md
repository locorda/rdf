# RDF Codec Performance Benchmark

Generated: 2026-03-20T23:50:05.850712

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
| Turtle        | 324 B                  | 50 µs      | 36 µs      | 100%     | 100%    | 100%    |
| N-Triples     | 350 B                  | **9 µs**   | **17 µs**  | 108%     | **18%** | **47%** |
| JSON-LD       | 440 B                  | 43 µs      | 29 µs      | 136%     | 87%     | 81%     |
| RDF/XML       | 760 B                  | 61 µs      | 5.6 ms     | 235%     | 121%    | 15658%  |
| Jelly         | **210 B**              | 42 µs      | 37 µs      | **65%**  | 84%     | 103%    |

> Baseline: **Turtle** — enc 50 µs, dec 36 µs. Enc/Dec % < 100% = faster, > 100% = slower.

## Graph Codecs — Small (acl.ttl)

Source: acl.ttl · 93 triples · 7 KB source

| Format        | Out size (bytes)       | Enc time   | Dec time   | Size %   | Enc %   | Dec %   |
| :------------ | :--------------------- | :--------- | :--------- | :------- | :------ | :------ |
| Turtle        | 7 KB (7 107 B)         | 158 µs     | 467 µs     | 100%     | 100%    | 100%    |
| N-Triples     | 15 KB (14 916 B)       | **113 µs** | 379 µs     | 210%     | **71%** | 81%     |
| JSON-LD       | 9 KB (9 644 B)         | 138 µs     | 151 µs     | 136%     | 87%     | 32%     |
| RDF/XML       | 10 KB (9 807 B)        | 217 µs     | 5.8 ms     | 138%     | 138%    | 1234%   |
| Jelly         | **6 KB (6 326 B)**     | 144 µs     | **132 µs** | **89%**  | 91%     | **28%** |

> Baseline: **Turtle** — enc 158 µs, dec 467 µs. Enc/Dec % < 100% = faster, > 100% = slower.

## Graph Codecs — Large (schema.org.ttl)

Source: schema.org.ttl · 17.2k triples · 1.0 MB source

| Format        | Out size (bytes)       | Enc time   | Dec time   | Size %   | Enc %   | Dec %   |
| :------------ | :--------------------- | :--------- | :--------- | :------- | :------ | :------ |
| Turtle        | 1001 KB (1 024 861 B)  | **19 ms**  | 80 ms      | 100%     | **100%** | 100%    |
| N-Triples     | 2.1 MB (2 247 393 B)   | 21 ms      | 86 ms      | 219%     | 109%    | 107%    |
| JSON-LD       | 1.4 MB (1 435 345 B)   | 20 ms      | 32 ms      | 140%     | 105%    | 40%     |
| RDF/XML       | 1.4 MB (1 477 689 B)   | 43 ms      | 81 ms      | 144%     | 223%    | 101%    |
| Jelly         | **755 KB (773 314 B)** | 26 ms      | **27 ms**  | **75%**  | 134%    | **34%** |

> Baseline: **Turtle** — enc 19 ms, dec 80 ms. Enc/Dec % < 100% = faster, > 100% = slower.

## Dataset Codecs — Tiny (5 quads, synthetic)

Source: 5 synthetic quads (default graph)

| Format        | Out size (bytes)       | Enc time   | Dec time   | Size %   | Enc %   | Dec %   |
| :------------ | :--------------------- | :--------- | :--------- | :------- | :------ | :------ |
| TriG          | 324 B                  | 16 µs      | 24 µs      | 100%     | 100%    | 100%    |
| N-Quads       | 350 B                  | **4 µs**   | 12 µs      | 108%     | **27%** | 52%     |
| JSON-LD       | 440 B                  | 18 µs      | **9 µs**   | 136%     | 111%    | **38%** |
| Jelly         | **212 B**              | 19 µs      | 16 µs      | **65%**  | 115%    | 68%     |

> Baseline: **TriG** — enc 16 µs, dec 24 µs. Enc/Dec % < 100% = faster, > 100% = slower.

## Dataset Codecs — Small

Source: acl.ttl (wrapped in default graph) · 93 quads

| Format        | Out size (bytes)       | Enc time   | Dec time   | Size %   | Enc %   | Dec %   |
| :------------ | :--------------------- | :--------- | :--------- | :------- | :------ | :------ |
| TriG          | 7 KB (7 107 B)         | 131 µs     | 462 µs     | 100%     | 100%    | 100%    |
| N-Quads       | 15 KB (14 916 B)       | **101 µs** | 517 µs     | 210%     | **77%** | 112%    |
| JSON-LD       | 9 KB (9 644 B)         | 135 µs     | 142 µs     | 136%     | 103%    | 31%     |
| Jelly         | **6 KB (6 328 B)**     | 147 µs     | **115 µs** | **89%**  | 111%    | **25%** |

> Baseline: **TriG** — enc 131 µs, dec 462 µs. Enc/Dec % < 100% = faster, > 100% = slower.

## Dataset Codecs — Large (shard.trig)

Source: shard-mod-md5.trig · 34.3k quads · 2.3 MB source

| Format        | Out size (bytes)       | Enc time   | Dec time   | Size %   | Enc %   | Dec %   |
| :------------ | :--------------------- | :--------- | :--------- | :------- | :------ | :------ |
| TriG          | 2.3 MB (2 463 952 B)   | 69 ms      | 160 ms     | 100%     | 100%    | 100%    |
| N-Quads       | 12.8 MB (13 401 021 B) | 67 ms      | 387 ms     | 544%     | 97%     | 242%    |
| JSON-LD       | 3.9 MB (4 072 259 B)   | 116 ms     | 798 ms     | 165%     | 169%    | 499%    |
| Jelly         | **1.8 MB (1 853 608 B)** | **60 ms**  | **66 ms**  | **75%**  | **88%** | **41%** |

> Baseline: **TriG** — enc 69 ms, dec 160 ms. Enc/Dec % < 100% = faster, > 100% = slower.

## Per-Triple Encode Cost (µs/triple)

Shows how encode cost per triple changes with dataset size. Constant = linear scaling, increasing = super-linear overhead.

| Format        | Tiny (5)     | Small (93)   | Large (17.2k) | Ratio (Large/Small) |
| :------------ | :----------- | :----------- | :----------- | :----------------- |
| Turtle        | 10.013 µs    | 1.700 µs     | 1.113 µs     | 0.65×              |
| N-Triples     | 1.838 µs     | 1.215 µs     | 1.207 µs     | 0.99×              |
| JSON-LD       | 8.683 µs     | 1.483 µs     | 1.169 µs     | 0.79×              |
| RDF/XML       | 12.151 µs    | 2.338 µs     | 2.479 µs     | 1.06×              |
| Jelly         | 8.421 µs     | 1.545 µs     | 1.495 µs     | 0.97×              |

> A ratio of ~1.0× means linear scaling. >1× indicates super-linear overhead at larger sizes.

## Per-Triple Decode Cost (µs/triple)

Shows how decode cost per triple changes with dataset size.

| Format        | Tiny (5)     | Small (93)   | Large (17.2k) | Ratio (Large/Small) |
| :------------ | :----------- | :----------- | :----------- | :----------------- |
| Turtle        | 7.102 µs     | 5.025 µs     | 4.636 µs     | 0.92×              |
| N-Triples     | 3.349 µs     | 4.076 µs     | 4.983 µs     | 1.22×              |
| JSON-LD       | 5.743 µs     | 1.628 µs     | 1.839 µs     | 1.13×              |
| RDF/XML       | 1112.023 µs  | 61.998 µs    | 4.684 µs     | 0.08×              |
| Jelly         | 7.301 µs     | 1.418 µs     | 1.593 µs     | 1.12×              |

> A ratio of ~1.0× means linear scaling. >1× indicates super-linear overhead at larger sizes.

## Per-Quad Encode Cost (µs/quad)

Shows how encode cost per quad changes with dataset size.

| Format        | Tiny (5)     | Small (93)   | Large (34.3k) | Ratio (Large/Small) |
| :------------ | :----------- | :----------- | :----------- | :----------------- |
| TriG          | 3.260 µs     | 1.414 µs     | 1.999 µs     | 1.41×              |
| N-Quads       | 0.878 µs     | 1.090 µs     | 1.945 µs     | 1.78×              |
| JSON-LD       | 3.619 µs     | 1.452 µs     | 3.377 µs     | 2.33×              |
| Jelly         | 3.755 µs     | 1.575 µs     | 1.759 µs     | 1.12×              |

> A ratio of ~1.0× means linear scaling. >1× indicates super-linear overhead at larger sizes.

## Per-Quad Decode Cost (µs/quad)

Shows how decode cost per quad changes with dataset size.

| Format        | Tiny (5)     | Small (93)   | Large (34.3k) | Ratio (Large/Small) |
| :------------ | :----------- | :----------- | :----------- | :----------------- |
| TriG          | 4.844 µs     | 4.965 µs     | 4.666 µs     | 0.94×              |
| N-Quads       | 2.497 µs     | 5.560 µs     | 11.306 µs    | 2.03×              |
| JSON-LD       | 1.859 µs     | 1.529 µs     | 23.279 µs    | 15.23×             |
| Jelly         | 3.299 µs     | 1.239 µs     | 1.923 µs     | 1.55×              |

> A ratio of ~1.0× means linear scaling. >1× indicates super-linear overhead at larger sizes.

---

*Benchmark run in JIT (dart run). Results reflect warm JIT throughput, not AOT-compiled production performance.*
