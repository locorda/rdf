# RDF Codec Performance Benchmark

Generated: 2026-03-21T16:10:13.481626

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

Loading test assets from: /Users/klaskalass/privat/locorda/rdf2/packages/locorda_rdf_core/test/assets/realworld

Decoding source assets…
  tiny  graph  : 5 triples (synthetic)
  small graph  : 93 triples (7 KB source)
  large graph  : 17.2k triples (1.0 MB source)
  tiny  dataset: 5 quads (synthetic)
  small dataset: 93 quads
  large dataset: 34.3k quads (2.3 MB source)

Benchmarking graph codecs (tiny: 5 triples)…
Benchmarking graph codecs (small: acl.ttl)…
Benchmarking graph codecs (large: schema.org.ttl)…
Benchmarking dataset codecs (tiny: 5 quads)…
Benchmarking dataset codecs (small: acl.ttl wrapped)…
Benchmarking dataset codecs (large: shard.trig)…


## Graph Codecs — Tiny (5 triples, synthetic)

Source: 5 synthetic triples (schema:name literals)

| Format        | Out size (bytes)       | Enc time   | Dec time   | Size %   | Enc %   | Dec %   |
| :------------ | :--------------------- | :--------- | :--------- | :------- | :------ | :------ |
| Turtle        | 324 B                  | 48 µs      | 30 µs      | 100%     | 100%    | 100%    |
| N-Triples     | 350 B                  | **9 µs**   | **17 µs**  | 108%     | **19%** | **56%** |
| JSON-LD       | 440 B                  | 43 µs      | 25 µs      | 136%     | 90%     | 84%     |
| RDF/XML       | 760 B                  | 51 µs      | 5.7 ms     | 235%     | 106%    | 19179%  |
| Jelly         | **210 B**              | 20 µs      | 18 µs      | **65%**  | 42%     | 62%     |

> Baseline: **Turtle** — enc 48 µs, dec 30 µs. Enc/Dec % < 100% = faster, > 100% = slower.

## Graph Codecs — Small (acl.ttl)

Source: acl.ttl · 93 triples · 7 KB source

| Format        | Out size (bytes)       | Enc time   | Dec time   | Size %   | Enc %   | Dec %   |
| :------------ | :--------------------- | :--------- | :--------- | :------- | :------ | :------ |
| Turtle        | 7 KB (7 107 B)         | 171 µs     | 460 µs     | 100%     | 100%    | 100%    |
| N-Triples     | 15 KB (14 916 B)       | 104 µs     | 383 µs     | 210%     | 61%     | 83%     |
| JSON-LD       | 9 KB (9 644 B)         | 139 µs     | 149 µs     | 136%     | 81%     | 32%     |
| RDF/XML       | 10 KB (10 033 B)       | 190 µs     | 5.9 ms     | 141%     | 111%    | 1292%   |
| Jelly         | **6 KB (6 326 B)**     | **82 µs**  | **35 µs**  | **89%**  | **48%** | **8%**  |

> Baseline: **Turtle** — enc 171 µs, dec 460 µs. Enc/Dec % < 100% = faster, > 100% = slower.

## Graph Codecs — Large (schema.org.ttl)

Source: schema.org.ttl · 17.2k triples · 1.0 MB source

| Format        | Out size (bytes)       | Enc time   | Dec time   | Size %   | Enc %   | Dec %   |
| :------------ | :--------------------- | :--------- | :--------- | :------- | :------ | :------ |
| Turtle        | 1001 KB (1 024 861 B)  | 19 ms      | 81 ms      | 100%     | 100%    | 100%    |
| N-Triples     | 2.1 MB (2 247 393 B)   | 20 ms      | 86 ms      | 219%     | 104%    | 107%    |
| JSON-LD       | 1.4 MB (1 435 345 B)   | 21 ms      | 34 ms      | 140%     | 107%    | 42%     |
| RDF/XML       | 1.4 MB (1 480 044 B)   | 41 ms      | 85 ms      | 144%     | 210%    | 105%    |
| Jelly         | **755 KB (773 314 B)** | **15 ms**  | **5.6 ms** | **75%**  | **78%** | **7%**  |

> Baseline: **Turtle** — enc 19 ms, dec 81 ms. Enc/Dec % < 100% = faster, > 100% = slower.

## Dataset Codecs — Tiny (5 quads, synthetic)

Source: 5 synthetic quads (default graph)

| Format        | Out size (bytes)       | Enc time   | Dec time   | Size %   | Enc %   | Dec %   |
| :------------ | :--------------------- | :--------- | :--------- | :------- | :------ | :------ |
| TriG          | 324 B                  | 16 µs      | 31 µs      | 100%     | 100%    | 100%    |
| N-Quads       | 350 B                  | **4 µs**   | 13 µs      | 108%     | **25%** | 41%     |
| JSON-LD       | 440 B                  | 18 µs      | 10 µs      | 136%     | 112%    | 31%     |
| Jelly         | **212 B**              | 9 µs       | **7 µs**   | **65%**  | 58%     | **24%** |

> Baseline: **TriG** — enc 16 µs, dec 31 µs. Enc/Dec % < 100% = faster, > 100% = slower.

## Dataset Codecs — Small

Source: acl.ttl (wrapped in default graph) · 93 quads

| Format        | Out size (bytes)       | Enc time   | Dec time   | Size %   | Enc %   | Dec %   |
| :------------ | :--------------------- | :--------- | :--------- | :------- | :------ | :------ |
| TriG          | 7 KB (7 107 B)         | 133 µs     | 462 µs     | 100%     | 100%    | 100%    |
| N-Quads       | 15 KB (14 916 B)       | 100 µs     | 518 µs     | 210%     | 75%     | 112%    |
| JSON-LD       | 9 KB (9 644 B)         | 136 µs     | 144 µs     | 136%     | 102%    | 31%     |
| Jelly         | **6 KB (6 328 B)**     | **85 µs**  | **35 µs**  | **89%**  | **64%** | **8%**  |

> Baseline: **TriG** — enc 133 µs, dec 462 µs. Enc/Dec % < 100% = faster, > 100% = slower.

## Dataset Codecs — Large (shard.trig)

Source: shard-mod-md5.trig · 34.3k quads · 2.3 MB source

| Format        | Out size (bytes)       | Enc time   | Dec time   | Size %   | Enc %   | Dec %   |
| :------------ | :--------------------- | :--------- | :--------- | :------- | :------ | :------ |
| TriG          | 2.3 MB (2 463 952 B)   | 75 ms      | 166 ms     | 100%     | 100%    | 100%    |
| N-Quads       | 12.8 MB (13 401 021 B) | 69 ms      | 417 ms     | 544%     | 93%     | 252%    |
| JSON-LD       | 3.9 MB (4 072 259 B)   | 123 ms     | 836 ms     | 165%     | 164%    | 504%    |
| Jelly         | **1.8 MB (1 853 608 B)** | **40 ms**  | **20 ms**  | **75%**  | **54%** | **12%** |

> Baseline: **TriG** — enc 75 ms, dec 166 ms. Enc/Dec % < 100% = faster, > 100% = slower.

## Per-Triple Encode Cost (µs/triple)

Shows how encode cost per triple changes with dataset size. Constant = linear scaling, increasing = super-linear overhead.

| Format        | Tiny (5)     | Small (93)   | Large (17.2k) | Ratio (Large/Small) |
| :------------ | :----------- | :----------- | :----------- | :----------------- |
| Turtle        | 9.543 µs     | 1.839 µs     | 1.124 µs     | 0.61×              |
| N-Triples     | 1.775 µs     | 1.118 µs     | 1.173 µs     | 1.05×              |
| JSON-LD       | 8.544 µs     | 1.498 µs     | 1.204 µs     | 0.80×              |
| RDF/XML       | 10.105 µs    | 2.045 µs     | 2.363 µs     | 1.16×              |
| Jelly         | 4.050 µs     | 0.886 µs     | 0.882 µs     | 1.00×              |

> A ratio of ~1.0× means linear scaling. >1× indicates super-linear overhead at larger sizes.

## Per-Triple Decode Cost (µs/triple)

Shows how decode cost per triple changes with dataset size.

| Format        | Tiny (5)     | Small (93)   | Large (17.2k) | Ratio (Large/Small) |
| :------------ | :----------- | :----------- | :----------- | :----------------- |
| Turtle        | 5.937 µs     | 4.950 µs     | 4.679 µs     | 0.95×              |
| N-Triples     | 3.318 µs     | 4.118 µs     | 5.024 µs     | 1.22×              |
| JSON-LD       | 5.008 µs     | 1.605 µs     | 1.975 µs     | 1.23×              |
| RDF/XML       | 1138.673 µs  | 63.942 µs    | 4.930 µs     | 0.08×              |
| Jelly         | 3.655 µs     | 0.378 µs     | 0.323 µs     | 0.86×              |

> A ratio of ~1.0× means linear scaling. >1× indicates super-linear overhead at larger sizes.

## Per-Quad Encode Cost (µs/quad)

Shows how encode cost per quad changes with dataset size.

| Format        | Tiny (5)     | Small (93)   | Large (34.3k) | Ratio (Large/Small) |
| :------------ | :----------- | :----------- | :----------- | :----------------- |
| TriG          | 3.242 µs     | 1.430 µs     | 2.186 µs     | 1.53×              |
| N-Quads       | 0.815 µs     | 1.075 µs     | 2.025 µs     | 1.88×              |
| JSON-LD       | 3.622 µs     | 1.463 µs     | 3.583 µs     | 2.45×              |
| Jelly         | 1.882 µs     | 0.915 µs     | 1.181 µs     | 1.29×              |

> A ratio of ~1.0× means linear scaling. >1× indicates super-linear overhead at larger sizes.

## Per-Quad Decode Cost (µs/quad)

Shows how decode cost per quad changes with dataset size.

| Format        | Tiny (5)     | Small (93)   | Large (34.3k) | Ratio (Large/Small) |
| :------------ | :----------- | :----------- | :----------- | :----------------- |
| TriG          | 6.297 µs     | 4.968 µs     | 4.838 µs     | 0.97×              |
| N-Quads       | 2.563 µs     | 5.567 µs     | 12.168 µs    | 2.19×              |
| JSON-LD       | 1.930 µs     | 1.547 µs     | 24.407 µs    | 15.77×             |
| Jelly         | 1.483 µs     | 0.379 µs     | 0.590 µs     | 1.56×              |

> A ratio of ~1.0× means linear scaling. >1× indicates super-linear overhead at larger sizes.

---

*Benchmark run in JIT (dart run). Results reflect warm JIT throughput, not AOT-compiled production performance.*
