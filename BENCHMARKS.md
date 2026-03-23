# RDF Codec Performance Benchmark

Generated: 2026-03-23T07:02:18.051763

## Versions

| Package | Version |
| :------ | :------ |
| locorda_rdf_core | 0.11.11 |
| locorda_rdf_jelly | 0.11.11 |
| locorda_rdf_xml | 0.11.11 |
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
| Turtle        | 324 B                  | 50 µs      | 33 µs      | 100%     | 100%    | 100%    |
| N-Triples     | 350 B                  | **8 µs**   | **16 µs**  | 108%     | **17%** | **50%** |
| JSON-LD       | 440 B                  | 43 µs      | 52 µs      | 136%     | 86%     | 159%    |
| RDF/XML       | 760 B                  | 50 µs      | 5.5 ms     | 235%     | 100%    | 17009%  |
| Jelly         | **210 B**              | 20 µs      | 17 µs      | **65%**  | 39%     | 53%     |

> Baseline: **Turtle** — enc 50 µs, dec 33 µs. Enc/Dec % < 100% = faster, > 100% = slower.

## Graph Codecs — Small (acl.ttl)

Source: acl.ttl · 93 triples · 7 KB source

| Format        | Out size (bytes)       | Enc time   | Dec time   | Size %   | Enc %   | Dec %   |
| :------------ | :--------------------- | :--------- | :--------- | :------- | :------ | :------ |
| Turtle        | 7 KB (7 107 B)         | 173 µs     | 475 µs     | 100%     | 100%    | 100%    |
| N-Triples     | 15 KB (14 916 B)       | 110 µs     | 376 µs     | 210%     | 63%     | 79%     |
| JSON-LD       | 9 KB (9 644 B)         | 138 µs     | 272 µs     | 136%     | 80%     | 57%     |
| RDF/XML       | 10 KB (10 033 B)       | 186 µs     | 5.6 ms     | 141%     | 107%    | 1181%   |
| Jelly         | **6 KB (6 326 B)**     | **85 µs**  | **35 µs**  | **89%**  | **49%** | **7%**  |

> Baseline: **Turtle** — enc 173 µs, dec 475 µs. Enc/Dec % < 100% = faster, > 100% = slower.

## Graph Codecs — Large (schema.org.ttl)

Source: schema.org.ttl · 17.2k triples · 1.0 MB source

| Format        | Out size (bytes)       | Enc time   | Dec time   | Size %   | Enc %   | Dec %   |
| :------------ | :--------------------- | :--------- | :--------- | :------- | :------ | :------ |
| Turtle        | 1001 KB (1 024 861 B)  | 19 ms      | 78 ms      | 100%     | 100%    | 100%    |
| N-Triples     | 2.1 MB (2 247 393 B)   | 20 ms      | 85 ms      | 219%     | 106%    | 109%    |
| JSON-LD       | 1.4 MB (1 435 345 B)   | 20 ms      | 56 ms      | 140%     | 108%    | 71%     |
| RDF/XML       | 1.4 MB (1 480 044 B)   | 37 ms      | 75 ms      | 144%     | 200%    | 95%     |
| Jelly         | **755 KB (773 314 B)** | **15 ms**  | **5.6 ms** | **75%**  | **82%** | **7%**  |

> Baseline: **Turtle** — enc 19 ms, dec 78 ms. Enc/Dec % < 100% = faster, > 100% = slower.

## Dataset Codecs — Tiny (5 quads, synthetic)

Source: 5 synthetic quads (default graph)

| Format        | Out size (bytes)       | Enc time   | Dec time   | Size %   | Enc %   | Dec %   |
| :------------ | :--------------------- | :--------- | :--------- | :------- | :------ | :------ |
| TriG          | 324 B                  | 20 µs      | 25 µs      | 100%     | 100%    | 100%    |
| N-Quads       | 350 B                  | **4 µs**   | 13 µs      | 108%     | **20%** | 51%     |
| JSON-LD       | 440 B                  | 18 µs      | 18 µs      | 136%     | 90%     | 71%     |
| Jelly         | **212 B**              | 9 µs       | **7 µs**   | **65%**  | 46%     | **27%** |

> Baseline: **TriG** — enc 20 µs, dec 25 µs. Enc/Dec % < 100% = faster, > 100% = slower.

## Dataset Codecs — Small

Source: acl.ttl (wrapped in default graph) · 93 quads

| Format        | Out size (bytes)       | Enc time   | Dec time   | Size %   | Enc %   | Dec %   |
| :------------ | :--------------------- | :--------- | :--------- | :------- | :------ | :------ |
| TriG          | 7 KB (7 107 B)         | 133 µs     | 456 µs     | 100%     | 100%    | 100%    |
| N-Quads       | 15 KB (14 916 B)       | 99 µs      | 512 µs     | 210%     | 74%     | 112%    |
| JSON-LD       | 9 KB (9 644 B)         | 135 µs     | 254 µs     | 136%     | 102%    | 56%     |
| Jelly         | **6 KB (6 328 B)**     | **84 µs**  | **34 µs**  | **89%**  | **63%** | **8%**  |

> Baseline: **TriG** — enc 133 µs, dec 456 µs. Enc/Dec % < 100% = faster, > 100% = slower.

## Dataset Codecs — Large (shard.trig)

Source: shard-mod-md5.trig · 34.3k quads · 2.3 MB source

| Format        | Out size (bytes)       | Enc time   | Dec time   | Size %   | Enc %   | Dec %   |
| :------------ | :--------------------- | :--------- | :--------- | :------- | :------ | :------ |
| TriG          | 2.3 MB (2 463 952 B)   | 73 ms      | 160 ms     | 100%     | 100%    | 100%    |
| N-Quads       | 12.8 MB (13 401 021 B) | 68 ms      | 406 ms     | 544%     | 93%     | 253%    |
| JSON-LD       | 3.9 MB (4 072 259 B)   | 118 ms     | 157 ms     | 165%     | 161%    | 98%     |
| Jelly         | **1.8 MB (1 853 608 B)** | **40 ms**  | **18 ms**  | **75%**  | **55%** | **11%** |

> Baseline: **TriG** — enc 73 ms, dec 160 ms. Enc/Dec % < 100% = faster, > 100% = slower.

## Per-Triple Encode Cost (µs/triple)

Shows how encode cost per triple changes with dataset size. Constant = linear scaling, increasing = super-linear overhead.

| Format        | Tiny (5)     | Small (93)   | Large (17.2k) | Ratio (Large/Small) |
| :------------ | :----------- | :----------- | :----------- | :----------------- |
| Turtle        | 10.050 µs    | 1.864 µs     | 1.082 µs     | 0.58×              |
| N-Triples     | 1.662 µs     | 1.183 µs     | 1.142 µs     | 0.97×              |
| JSON-LD       | 8.593 µs     | 1.485 µs     | 1.167 µs     | 0.79×              |
| RDF/XML       | 10.008 µs    | 1.997 µs     | 2.163 µs     | 1.08×              |
| Jelly         | 3.970 µs     | 0.917 µs     | 0.891 µs     | 0.97×              |

> A ratio of ~1.0× means linear scaling. >1× indicates super-linear overhead at larger sizes.

## Per-Triple Decode Cost (µs/triple)

Shows how decode cost per triple changes with dataset size.

| Format        | Tiny (5)     | Small (93)   | Large (17.2k) | Ratio (Large/Small) |
| :------------ | :----------- | :----------- | :----------- | :----------------- |
| Turtle        | 6.511 µs     | 5.106 µs     | 4.542 µs     | 0.89×              |
| N-Triples     | 3.253 µs     | 4.046 µs     | 4.936 µs     | 1.22×              |
| JSON-LD       | 10.354 µs    | 2.925 µs     | 3.238 µs     | 1.11×              |
| RDF/XML       | 1107.436 µs  | 60.306 µs    | 4.332 µs     | 0.07×              |
| Jelly         | 3.482 µs     | 0.379 µs     | 0.324 µs     | 0.85×              |

> A ratio of ~1.0× means linear scaling. >1× indicates super-linear overhead at larger sizes.

## Per-Quad Encode Cost (µs/quad)

Shows how encode cost per quad changes with dataset size.

| Format        | Tiny (5)     | Small (93)   | Large (34.3k) | Ratio (Large/Small) |
| :------------ | :----------- | :----------- | :----------- | :----------------- |
| TriG          | 3.996 µs     | 1.432 µs     | 2.131 µs     | 1.49×              |
| N-Quads       | 0.782 µs     | 1.060 µs     | 1.975 µs     | 1.86×              |
| JSON-LD       | 3.581 µs     | 1.456 µs     | 3.438 µs     | 2.36×              |
| Jelly         | 1.829 µs     | 0.905 µs     | 1.168 µs     | 1.29×              |

> A ratio of ~1.0× means linear scaling. >1× indicates super-linear overhead at larger sizes.

## Per-Quad Decode Cost (µs/quad)

Shows how decode cost per quad changes with dataset size.

| Format        | Tiny (5)     | Small (93)   | Large (34.3k) | Ratio (Large/Small) |
| :------------ | :----------- | :----------- | :----------- | :----------------- |
| TriG          | 4.964 µs     | 4.905 µs     | 4.678 µs     | 0.95×              |
| N-Quads       | 2.514 µs     | 5.501 µs     | 11.854 µs    | 2.15×              |
| JSON-LD       | 3.540 µs     | 2.728 µs     | 4.567 µs     | 1.67×              |
| Jelly         | 1.352 µs     | 0.369 µs     | 0.534 µs     | 1.45×              |

> A ratio of ~1.0× means linear scaling. >1× indicates super-linear overhead at larger sizes.

---

*Benchmark run in JIT (dart run). Results reflect warm JIT throughput, not AOT-compiled production performance.*
