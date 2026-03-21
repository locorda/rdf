# RDF Codec Performance Benchmark

Generated: 2026-03-21T16:23:47.459765

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
| Turtle        | 324 B                  | 52 µs      | 34 µs      | 100%     | 100%    | 100%    |
| N-Triples     | 350 B                  | **9 µs**   | **17 µs**  | 108%     | **18%** | **50%** |
| JSON-LD       | 440 B                  | 42 µs      | 25 µs      | 136%     | 81%     | 72%     |
| RDF/XML       | 760 B                  | 52 µs      | 5.4 ms     | 235%     | 100%    | 15992%  |
| Jelly         | **210 B**              | 24 µs      | 18 µs      | **65%**  | 46%     | 53%     |

> Baseline: **Turtle** — enc 52 µs, dec 34 µs. Enc/Dec % < 100% = faster, > 100% = slower.

## Graph Codecs — Small (acl.ttl)

Source: acl.ttl · 93 triples · 7 KB source

| Format        | Out size (bytes)       | Enc time   | Dec time   | Size %   | Enc %   | Dec %   |
| :------------ | :--------------------- | :--------- | :--------- | :------- | :------ | :------ |
| Turtle        | 7 KB (7 107 B)         | 160 µs     | 462 µs     | 100%     | 100%    | 100%    |
| N-Triples     | 15 KB (14 916 B)       | 102 µs     | 377 µs     | 210%     | 64%     | 82%     |
| JSON-LD       | 9 KB (9 644 B)         | 135 µs     | 152 µs     | 136%     | 84%     | 33%     |
| RDF/XML       | 10 KB (10 033 B)       | 190 µs     | 5.6 ms     | 141%     | 118%    | 1211%   |
| Jelly         | **6 KB (6 326 B)**     | **83 µs**  | **34 µs**  | **89%**  | **52%** | **7%**  |

> Baseline: **Turtle** — enc 160 µs, dec 462 µs. Enc/Dec % < 100% = faster, > 100% = slower.

## Graph Codecs — Large (schema.org.ttl)

Source: schema.org.ttl · 17.2k triples · 1.0 MB source

| Format        | Out size (bytes)       | Enc time   | Dec time   | Size %   | Enc %   | Dec %   |
| :------------ | :--------------------- | :--------- | :--------- | :------- | :------ | :------ |
| Turtle        | 1001 KB (1 024 861 B)  | 19 ms      | 78 ms      | 100%     | 100%    | 100%    |
| N-Triples     | 2.1 MB (2 247 393 B)   | 19 ms      | 87 ms      | 219%     | 104%    | 111%    |
| JSON-LD       | 1.4 MB (1 435 345 B)   | 20 ms      | 32 ms      | 140%     | 108%    | 40%     |
| RDF/XML       | 1.4 MB (1 480 044 B)   | 38 ms      | 80 ms      | 144%     | 203%    | 102%    |
| Jelly         | **755 KB (773 314 B)** | **15 ms**  | **5.5 ms** | **75%**  | **81%** | **7%**  |

> Baseline: **Turtle** — enc 19 ms, dec 78 ms. Enc/Dec % < 100% = faster, > 100% = slower.

## Dataset Codecs — Tiny (5 quads, synthetic)

Source: 5 synthetic quads (default graph)

| Format        | Out size (bytes)       | Enc time   | Dec time   | Size %   | Enc %   | Dec %   |
| :------------ | :--------------------- | :--------- | :--------- | :------- | :------ | :------ |
| TriG          | 324 B                  | 19 µs      | 24 µs      | 100%     | 100%    | 100%    |
| N-Quads       | 350 B                  | **4 µs**   | 13 µs      | 108%     | **20%** | 52%     |
| JSON-LD       | 440 B                  | 18 µs      | 9 µs       | 136%     | 93%     | 38%     |
| Jelly         | **212 B**              | 9 µs       | **7 µs**   | **65%**  | 49%     | **29%** |

> Baseline: **TriG** — enc 19 µs, dec 24 µs. Enc/Dec % < 100% = faster, > 100% = slower.

## Dataset Codecs — Small

Source: acl.ttl (wrapped in default graph) · 93 quads

| Format        | Out size (bytes)       | Enc time   | Dec time   | Size %   | Enc %   | Dec %   |
| :------------ | :--------------------- | :--------- | :--------- | :------- | :------ | :------ |
| TriG          | 7 KB (7 107 B)         | 130 µs     | 465 µs     | 100%     | 100%    | 100%    |
| N-Quads       | 15 KB (14 916 B)       | 100 µs     | 518 µs     | 210%     | 77%     | 111%    |
| JSON-LD       | 9 KB (9 644 B)         | 136 µs     | 145 µs     | 136%     | 104%    | 31%     |
| Jelly         | **6 KB (6 328 B)**     | **85 µs**  | **37 µs**  | **89%**  | **65%** | **8%**  |

> Baseline: **TriG** — enc 130 µs, dec 465 µs. Enc/Dec % < 100% = faster, > 100% = slower.

## Dataset Codecs — Large (shard.trig)

Source: shard-mod-md5.trig · 34.3k quads · 2.3 MB source

| Format        | Out size (bytes)       | Enc time   | Dec time   | Size %   | Enc %   | Dec %   |
| :------------ | :--------------------- | :--------- | :--------- | :------- | :------ | :------ |
| TriG          | 2.3 MB (2 463 952 B)   | 74 ms      | 168 ms     | 100%     | 100%    | 100%    |
| N-Quads       | 12.8 MB (13 401 021 B) | 69 ms      | 415 ms     | 544%     | 94%     | 248%    |
| JSON-LD       | 3.9 MB (4 072 259 B)   | 117 ms     | 814 ms     | 165%     | 158%    | 486%    |
| Jelly         | **1.8 MB (1 853 608 B)** | **39 ms**  | **19 ms**  | **75%**  | **53%** | **11%** |

> Baseline: **TriG** — enc 74 ms, dec 168 ms. Enc/Dec % < 100% = faster, > 100% = slower.

## Per-Triple Encode Cost (µs/triple)

Shows how encode cost per triple changes with dataset size. Constant = linear scaling, increasing = super-linear overhead.

| Format        | Tiny (5)     | Small (93)   | Large (17.2k) | Ratio (Large/Small) |
| :------------ | :----------- | :----------- | :----------- | :----------------- |
| Turtle        | 10.364 µs    | 1.724 µs     | 1.081 µs     | 0.63×              |
| N-Triples     | 1.815 µs     | 1.102 µs     | 1.119 µs     | 1.02×              |
| JSON-LD       | 8.361 µs     | 1.448 µs     | 1.165 µs     | 0.80×              |
| RDF/XML       | 10.415 µs    | 2.040 µs     | 2.197 µs     | 1.08×              |
| Jelly         | 4.735 µs     | 0.889 µs     | 0.875 µs     | 0.98×              |

> A ratio of ~1.0× means linear scaling. >1× indicates super-linear overhead at larger sizes.

## Per-Triple Decode Cost (µs/triple)

Shows how decode cost per triple changes with dataset size.

| Format        | Tiny (5)     | Small (93)   | Large (17.2k) | Ratio (Large/Small) |
| :------------ | :----------- | :----------- | :----------- | :----------------- |
| Turtle        | 6.798 µs     | 4.964 µs     | 4.560 µs     | 0.92×              |
| N-Triples     | 3.380 µs     | 4.056 µs     | 5.059 µs     | 1.25×              |
| JSON-LD       | 4.903 µs     | 1.633 µs     | 1.844 µs     | 1.13×              |
| RDF/XML       | 1087.095 µs  | 60.104 µs    | 4.651 µs     | 0.08×              |
| Jelly         | 3.633 µs     | 0.370 µs     | 0.322 µs     | 0.87×              |

> A ratio of ~1.0× means linear scaling. >1× indicates super-linear overhead at larger sizes.

## Per-Quad Encode Cost (µs/quad)

Shows how encode cost per quad changes with dataset size.

| Format        | Tiny (5)     | Small (93)   | Large (34.3k) | Ratio (Large/Small) |
| :------------ | :----------- | :----------- | :----------- | :----------------- |
| TriG          | 3.753 µs     | 1.402 µs     | 2.156 µs     | 1.54×              |
| N-Quads       | 0.756 µs     | 1.078 µs     | 2.020 µs     | 1.87×              |
| JSON-LD       | 3.505 µs     | 1.462 µs     | 3.417 µs     | 2.34×              |
| Jelly         | 1.847 µs     | 0.910 µs     | 1.150 µs     | 1.26×              |

> A ratio of ~1.0× means linear scaling. >1× indicates super-linear overhead at larger sizes.

## Per-Quad Decode Cost (µs/quad)

Shows how decode cost per quad changes with dataset size.

| Format        | Tiny (5)     | Small (93)   | Large (34.3k) | Ratio (Large/Small) |
| :------------ | :----------- | :----------- | :----------- | :----------------- |
| TriG          | 4.877 µs     | 4.996 µs     | 4.893 µs     | 0.98×              |
| N-Quads       | 2.518 µs     | 5.565 µs     | 12.117 µs    | 2.18×              |
| JSON-LD       | 1.871 µs     | 1.559 µs     | 23.757 µs    | 15.24×             |
| Jelly         | 1.411 µs     | 0.400 µs     | 0.550 µs     | 1.37×              |

> A ratio of ~1.0× means linear scaling. >1× indicates super-linear overhead at larger sizes.

---

*Benchmark run in JIT (dart run). Results reflect warm JIT throughput, not AOT-compiled production performance.*
