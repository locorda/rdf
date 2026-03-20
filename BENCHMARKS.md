# RDF Codec Performance Benchmark

Generated: 2026-03-20T15:14:54.679396

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
| Turtle        | 324 B                  | 49 µs      | 35 µs      | 100%     | 100%    | 100%    |
| N-Triples     | 350 B                  | **9 µs**   | **17 µs**  | 108%     | **17%** | **48%** |
| JSON-LD       | 440 B                  | 42 µs      | 28 µs      | 136%     | 85%     | 78%     |
| RDF/XML       | 760 B                  | 63 µs      | 5.5 ms     | 235%     | 128%    | 15672%  |
| Jelly         | **210 B**              | 41 µs      | 36 µs      | **65%**  | 83%     | 103%    |

> Baseline: **Turtle** — enc 49 µs, dec 35 µs. Enc/Dec % < 100% = faster, > 100% = slower.

## Graph Codecs — Small (acl.ttl)

Source: acl.ttl · 93 triples · 7 KB source

| Format        | Out size (bytes)       | Enc time   | Dec time   | Size %   | Enc %   | Dec %   |
| :------------ | :--------------------- | :--------- | :--------- | :------- | :------ | :------ |
| Turtle        | 7 KB (7 107 B)         | 158 µs     | 471 µs     | 100%     | 100%    | 100%    |
| N-Triples     | 15 KB (14 916 B)       | **113 µs** | 383 µs     | 210%     | **72%** | 81%     |
| JSON-LD       | 9 KB (9 644 B)         | 140 µs     | 151 µs     | 136%     | 89%     | 32%     |
| RDF/XML       | 10 KB (9 807 B)        | 217 µs     | 5.7 ms     | 138%     | 138%    | 1212%   |
| Jelly         | **6 KB (6 326 B)**     | 151 µs     | **121 µs** | **89%**  | 96%     | **26%** |

> Baseline: **Turtle** — enc 158 µs, dec 471 µs. Enc/Dec % < 100% = faster, > 100% = slower.

## Graph Codecs — Large (schema.org.ttl)

Source: schema.org.ttl · 17.2k triples · 1.0 MB source

| Format        | Out size (bytes)       | Enc time   | Dec time   | Size %   | Enc %   | Dec %   |
| :------------ | :--------------------- | :--------- | :--------- | :------- | :------ | :------ |
| Turtle        | 1001 KB (1 024 861 B)  | **19 ms**  | 80 ms      | 100%     | **100%** | 100%    |
| N-Triples     | 2.1 MB (2 247 393 B)   | 21 ms      | 86 ms      | 219%     | 109%    | 107%    |
| JSON-LD       | 1.4 MB (1 435 345 B)   | 21 ms      | 32 ms      | 140%     | 108%    | 40%     |
| RDF/XML       | 1.4 MB (1 477 689 B)   | 44 ms      | 83 ms      | 144%     | 231%    | 104%    |
| Jelly         | **755 KB (773 314 B)** | 41 ms      | **29 ms**  | **75%**  | 214%    | **36%** |

> Baseline: **Turtle** — enc 19 ms, dec 80 ms. Enc/Dec % < 100% = faster, > 100% = slower.

## Dataset Codecs — Tiny (5 quads, synthetic)

Source: 5 synthetic quads (default graph)

| Format        | Out size (bytes)       | Enc time   | Dec time   | Size %   | Enc %   | Dec %   |
| :------------ | :--------------------- | :--------- | :--------- | :------- | :------ | :------ |
| TriG          | 324 B                  | 24 µs      | 25 µs      | 100%     | 100%    | 100%    |
| N-Quads       | 350 B                  | **4 µs**   | 13 µs      | 108%     | **17%** | 52%     |
| JSON-LD       | 440 B                  | 18 µs      | **9 µs**   | 136%     | 75%     | **38%** |
| Jelly         | **212 B**              | 20 µs      | 17 µs      | **65%**  | 82%     | 69%     |

> Baseline: **TriG** — enc 24 µs, dec 25 µs. Enc/Dec % < 100% = faster, > 100% = slower.

## Dataset Codecs — Small

Source: acl.ttl (wrapped in default graph) · 93 quads

| Format        | Out size (bytes)       | Enc time   | Dec time   | Size %   | Enc %   | Dec %   |
| :------------ | :--------------------- | :--------- | :--------- | :------- | :------ | :------ |
| TriG          | 7 KB (7 107 B)         | 134 µs     | 464 µs     | 100%     | 100%    | 100%    |
| N-Quads       | 15 KB (14 916 B)       | **103 µs** | 518 µs     | 210%     | **77%** | 112%    |
| JSON-LD       | 9 KB (9 644 B)         | 137 µs     | 144 µs     | 136%     | 102%    | 31%     |
| Jelly         | **6 KB (6 328 B)**     | 151 µs     | **117 µs** | **89%**  | 112%    | **25%** |

> Baseline: **TriG** — enc 134 µs, dec 464 µs. Enc/Dec % < 100% = faster, > 100% = slower.

## Dataset Codecs — Large (shard.trig)

Source: shard-mod-md5.trig · 34.3k quads · 2.3 MB source

| Format        | Out size (bytes)       | Enc time   | Dec time   | Size %   | Enc %   | Dec %   |
| :------------ | :--------------------- | :--------- | :--------- | :------- | :------ | :------ |
| TriG          | 2.3 MB (2 463 952 B)   | 72 ms      | 166 ms     | 100%     | 100%    | 100%    |
| N-Quads       | 12.8 MB (13 401 021 B) | **72 ms**  | 402 ms     | 544%     | **100%** | 243%    |
| JSON-LD       | 3.9 MB (4 072 259 B)   | 123 ms     | 811 ms     | 165%     | 171%    | 490%    |
| Jelly         | **1.8 MB (1 853 608 B)** | 93 ms      | **69 ms**  | **75%**  | 130%    | **42%** |

> Baseline: **TriG** — enc 72 ms, dec 166 ms. Enc/Dec % < 100% = faster, > 100% = slower.

## Per-Triple Encode Cost (µs/triple)

Shows how encode cost per triple changes with dataset size. Constant = linear scaling, increasing = super-linear overhead.

| Format        | Tiny (5)     | Small (93)   | Large (17.2k) | Ratio (Large/Small) |
| :------------ | :----------- | :----------- | :----------- | :----------------- |
| Turtle        | 9.802 µs     | 1.695 µs     | 1.107 µs     | 0.65×              |
| N-Triples     | 1.713 µs     | 1.217 µs     | 1.210 µs     | 0.99×              |
| JSON-LD       | 8.318 µs     | 1.509 µs     | 1.199 µs     | 0.79×              |
| RDF/XML       | 12.574 µs    | 2.333 µs     | 2.561 µs     | 1.10×              |
| Jelly         | 8.106 µs     | 1.625 µs     | 2.364 µs     | 1.45×              |

> A ratio of ~1.0× means linear scaling. >1× indicates super-linear overhead at larger sizes.

## Per-Triple Decode Cost (µs/triple)

Shows how decode cost per triple changes with dataset size.

| Format        | Tiny (5)     | Small (93)   | Large (17.2k) | Ratio (Large/Small) |
| :------------ | :----------- | :----------- | :----------- | :----------------- |
| Turtle        | 7.080 µs     | 5.062 µs     | 4.656 µs     | 0.92×              |
| N-Triples     | 3.393 µs     | 4.116 µs     | 5.000 µs     | 1.21×              |
| JSON-LD       | 5.539 µs     | 1.627 µs     | 1.858 µs     | 1.14×              |
| RDF/XML       | 1109.583 µs  | 61.356 µs    | 4.848 µs     | 0.08×              |
| Jelly         | 7.274 µs     | 1.306 µs     | 1.664 µs     | 1.27×              |

> A ratio of ~1.0× means linear scaling. >1× indicates super-linear overhead at larger sizes.

## Per-Quad Encode Cost (µs/quad)

Shows how encode cost per quad changes with dataset size.

| Format        | Tiny (5)     | Small (93)   | Large (34.3k) | Ratio (Large/Small) |
| :------------ | :----------- | :----------- | :----------- | :----------------- |
| TriG          | 4.816 µs     | 1.440 µs     | 2.097 µs     | 1.46×              |
| N-Quads       | 0.841 µs     | 1.109 µs     | 2.089 µs     | 1.88×              |
| JSON-LD       | 3.621 µs     | 1.473 µs     | 3.593 µs     | 2.44×              |
| Jelly         | 3.973 µs     | 1.619 µs     | 2.726 µs     | 1.68×              |

> A ratio of ~1.0× means linear scaling. >1× indicates super-linear overhead at larger sizes.

## Per-Quad Decode Cost (µs/quad)

Shows how decode cost per quad changes with dataset size.

| Format        | Tiny (5)     | Small (93)   | Large (34.3k) | Ratio (Large/Small) |
| :------------ | :----------- | :----------- | :----------- | :----------------- |
| TriG          | 4.934 µs     | 4.993 µs     | 4.830 µs     | 0.97×              |
| N-Quads       | 2.552 µs     | 5.569 µs     | 11.723 µs    | 2.10×              |
| JSON-LD       | 1.895 µs     | 1.552 µs     | 23.664 µs    | 15.25×             |
| Jelly         | 3.427 µs     | 1.263 µs     | 2.026 µs     | 1.60×              |

> A ratio of ~1.0× means linear scaling. >1× indicates super-linear overhead at larger sizes.

---

*Benchmark run in JIT (dart run). Results reflect warm JIT throughput, not AOT-compiled production performance.*
