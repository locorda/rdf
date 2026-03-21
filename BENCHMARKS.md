# RDF Codec Performance Benchmark

Generated: 2026-03-21T10:46:23.682710

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
| Turtle        | 324 B                  | 51 µs      | 34 µs      | 100%     | 100%    | 100%    |
| N-Triples     | 350 B                  | **9 µs**   | **17 µs**  | 108%     | **17%** | **50%** |
| JSON-LD       | 440 B                  | 43 µs      | 29 µs      | 136%     | 84%     | 86%     |
| RDF/XML       | 760 B                  | 50 µs      | 5.6 ms     | 235%     | 99%     | 16475%  |
| Jelly         | **210 B**              | 20 µs      | 35 µs      | **65%**  | 40%     | 102%    |

> Baseline: **Turtle** — enc 51 µs, dec 34 µs. Enc/Dec % < 100% = faster, > 100% = slower.

## Graph Codecs — Small (acl.ttl)

Source: acl.ttl · 93 triples · 7 KB source

| Format        | Out size (bytes)       | Enc time   | Dec time   | Size %   | Enc %   | Dec %   |
| :------------ | :--------------------- | :--------- | :--------- | :------- | :------ | :------ |
| Turtle        | 7 KB (7 107 B)         | 156 µs     | 462 µs     | 100%     | 100%    | 100%    |
| N-Triples     | 15 KB (14 916 B)       | 103 µs     | 376 µs     | 210%     | 66%     | 81%     |
| JSON-LD       | 9 KB (9 644 B)         | 135 µs     | 155 µs     | 136%     | 87%     | 33%     |
| RDF/XML       | 10 KB (10 033 B)       | 187 µs     | 5.7 ms     | 141%     | 120%    | 1227%   |
| Jelly         | **6 KB (6 326 B)**     | **83 µs**  | **110 µs** | **89%**  | **53%** | **24%** |

> Baseline: **Turtle** — enc 156 µs, dec 462 µs. Enc/Dec % < 100% = faster, > 100% = slower.

## Graph Codecs — Large (schema.org.ttl)

Source: schema.org.ttl · 17.2k triples · 1.0 MB source

| Format        | Out size (bytes)       | Enc time   | Dec time   | Size %   | Enc %   | Dec %   |
| :------------ | :--------------------- | :--------- | :--------- | :------- | :------ | :------ |
| Turtle        | 1001 KB (1 024 861 B)  | 19 ms      | 79 ms      | 100%     | 100%    | 100%    |
| N-Triples     | 2.1 MB (2 247 393 B)   | 19 ms      | 84 ms      | 219%     | 103%    | 107%    |
| JSON-LD       | 1.4 MB (1 435 345 B)   | 20 ms      | 31 ms      | 140%     | 109%    | 39%     |
| RDF/XML       | 1.4 MB (1 480 044 B)   | 40 ms      | 79 ms      | 144%     | 213%    | 100%    |
| Jelly         | **755 KB (773 314 B)** | **15 ms**  | **27 ms**  | **75%**  | **80%** | **34%** |

> Baseline: **Turtle** — enc 19 ms, dec 79 ms. Enc/Dec % < 100% = faster, > 100% = slower.

## Dataset Codecs — Tiny (5 quads, synthetic)

Source: 5 synthetic quads (default graph)

| Format        | Out size (bytes)       | Enc time   | Dec time   | Size %   | Enc %   | Dec %   |
| :------------ | :--------------------- | :--------- | :--------- | :------- | :------ | :------ |
| TriG          | 324 B                  | 20 µs      | 24 µs      | 100%     | 100%    | 100%    |
| N-Quads       | 350 B                  | **4 µs**   | 13 µs      | 108%     | **19%** | 52%     |
| JSON-LD       | 440 B                  | 17 µs      | **9 µs**   | 136%     | 84%     | **39%** |
| Jelly         | **212 B**              | 9 µs       | 19 µs      | **65%**  | 44%     | 78%     |

> Baseline: **TriG** — enc 20 µs, dec 24 µs. Enc/Dec % < 100% = faster, > 100% = slower.

## Dataset Codecs — Small

Source: acl.ttl (wrapped in default graph) · 93 quads

| Format        | Out size (bytes)       | Enc time   | Dec time   | Size %   | Enc %   | Dec %   |
| :------------ | :--------------------- | :--------- | :--------- | :------- | :------ | :------ |
| TriG          | 7 KB (7 107 B)         | 130 µs     | 466 µs     | 100%     | 100%    | 100%    |
| N-Quads       | 15 KB (14 916 B)       | 100 µs     | 516 µs     | 210%     | 77%     | 111%    |
| JSON-LD       | 9 KB (9 644 B)         | 136 µs     | 148 µs     | 136%     | 104%    | 32%     |
| Jelly         | **6 KB (6 328 B)**     | **86 µs**  | **117 µs** | **89%**  | **66%** | **25%** |

> Baseline: **TriG** — enc 130 µs, dec 466 µs. Enc/Dec % < 100% = faster, > 100% = slower.

## Dataset Codecs — Large (shard.trig)

Source: shard-mod-md5.trig · 34.3k quads · 2.3 MB source

| Format        | Out size (bytes)       | Enc time   | Dec time   | Size %   | Enc %   | Dec %   |
| :------------ | :--------------------- | :--------- | :--------- | :------- | :------ | :------ |
| TriG          | 2.3 MB (2 463 952 B)   | 71 ms      | 162 ms     | 100%     | 100%    | 100%    |
| N-Quads       | 12.8 MB (13 401 021 B) | 70 ms      | 404 ms     | 544%     | 98%     | 250%    |
| JSON-LD       | 3.9 MB (4 072 259 B)   | 118 ms     | 808 ms     | 165%     | 166%    | 499%    |
| Jelly         | **1.8 MB (1 853 608 B)** | **40 ms**  | **65 ms**  | **75%**  | **56%** | **40%** |

> Baseline: **TriG** — enc 71 ms, dec 162 ms. Enc/Dec % < 100% = faster, > 100% = slower.

## Per-Triple Encode Cost (µs/triple)

Shows how encode cost per triple changes with dataset size. Constant = linear scaling, increasing = super-linear overhead.

| Format        | Tiny (5)     | Small (93)   | Large (17.2k) | Ratio (Large/Small) |
| :------------ | :----------- | :----------- | :----------- | :----------------- |
| Turtle        | 10.129 µs    | 1.673 µs     | 1.081 µs     | 0.65×              |
| N-Triples     | 1.724 µs     | 1.109 µs     | 1.118 µs     | 1.01×              |
| JSON-LD       | 8.501 µs     | 1.449 µs     | 1.174 µs     | 0.81×              |
| RDF/XML       | 10.016 µs    | 2.008 µs     | 2.308 µs     | 1.15×              |
| Jelly         | 4.037 µs     | 0.891 µs     | 0.868 µs     | 0.97×              |

> A ratio of ~1.0× means linear scaling. >1× indicates super-linear overhead at larger sizes.

## Per-Triple Decode Cost (µs/triple)

Shows how decode cost per triple changes with dataset size.

| Format        | Tiny (5)     | Small (93)   | Large (17.2k) | Ratio (Large/Small) |
| :------------ | :----------- | :----------- | :----------- | :----------------- |
| Turtle        | 6.759 µs     | 4.973 µs     | 4.584 µs     | 0.92×              |
| N-Triples     | 3.361 µs     | 4.045 µs     | 4.903 µs     | 1.21×              |
| JSON-LD       | 5.822 µs     | 1.663 µs     | 1.802 µs     | 1.08×              |
| RDF/XML       | 1113.571 µs  | 61.006 µs    | 4.591 µs     | 0.08×              |
| Jelly         | 6.907 µs     | 1.179 µs     | 1.556 µs     | 1.32×              |

> A ratio of ~1.0× means linear scaling. >1× indicates super-linear overhead at larger sizes.

## Per-Quad Encode Cost (µs/quad)

Shows how encode cost per quad changes with dataset size.

| Format        | Tiny (5)     | Small (93)   | Large (34.3k) | Ratio (Large/Small) |
| :------------ | :----------- | :----------- | :----------- | :----------------- |
| TriG          | 4.090 µs     | 1.401 µs     | 2.065 µs     | 1.47×              |
| N-Quads       | 0.767 µs     | 1.079 µs     | 2.034 µs     | 1.88×              |
| JSON-LD       | 3.441 µs     | 1.463 µs     | 3.434 µs     | 2.35×              |
| Jelly         | 1.779 µs     | 0.929 µs     | 1.154 µs     | 1.24×              |

> A ratio of ~1.0× means linear scaling. >1× indicates super-linear overhead at larger sizes.

## Per-Quad Decode Cost (µs/quad)

Shows how decode cost per quad changes with dataset size.

| Format        | Tiny (5)     | Small (93)   | Large (34.3k) | Ratio (Large/Small) |
| :------------ | :----------- | :----------- | :----------- | :----------------- |
| TriG          | 4.800 µs     | 5.010 µs     | 4.725 µs     | 0.94×              |
| N-Quads       | 2.509 µs     | 5.548 µs     | 11.793 µs    | 2.13×              |
| JSON-LD       | 1.861 µs     | 1.587 µs     | 23.577 µs    | 14.86×             |
| Jelly         | 3.762 µs     | 1.256 µs     | 1.884 µs     | 1.50×              |

> A ratio of ~1.0× means linear scaling. >1× indicates super-linear overhead at larger sizes.

---

*Benchmark run in JIT (dart run). Results reflect warm JIT throughput, not AOT-compiled production performance.*
