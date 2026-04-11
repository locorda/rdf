# RDF Codec Performance Benchmark

Generated: 2026-04-11T21:16:03.639701

## Versions

| Package | Version |
| :------ | :------ |
| locorda_rdf_core | 0.11.12 |
| locorda_rdf_jelly | 0.11.12 |
| locorda_rdf_xml | 0.11.12 |
| Dart SDK | 3.10.8 |
| Platform | macos (Version 26.4) |

## Column guide

- **Out size (bytes)** — encoded output size: human-readable + exact byte count (UTF-8 bytes for text formats, raw bytes for Jelly binary)
- **Enc/Dec time** — average per-operation latency
- **Size %** — output size relative to baseline format (100% = same size)
- **Enc/Dec %** — encode/decode latency relative to baseline (< 100% = faster)


## Graph Codecs — Tiny (5 triples, synthetic)

Source: 5 synthetic triples (schema:name literals)

| Format        | Out size (bytes)       | Enc time   | Dec time   | Size %   | Enc %   | Dec %   |
| :------------ | :--------------------- | :--------- | :--------- | :------- | :------ | :------ |
| Turtle        | 324 B                  | 51 µs      | 33 µs      | 100%     | 100%    | 100%    |
| N-Triples     | 350 B                  | **8 µs**   | **16 µs**  | 108%     | **16%** | **50%** |
| JSON-LD expanded | 682 B                  | 27 µs      | 51 µs      | 210%     | 53%     | 155%    |
| JSON-LD compact | 440 B                  | 64 µs      | 42 µs      | 136%     | 124%    | 129%    |
| JSON-LD flattened | 440 B                  | 49 µs      | 23 µs      | 136%     | 95%     | 69%     |
| RDF/XML       | 760 B                  | 50 µs      | 5.5 ms     | 235%     | 98%     | 16763%  |
| Jelly         | **210 B**              | 26 µs      | 19 µs      | **65%**  | 50%     | 57%     |

> Baseline: **Turtle** — enc 51 µs, dec 33 µs. Enc/Dec % < 100% = faster, > 100% = slower.

## Graph Codecs — Small (acl.ttl)

Source: acl.ttl · 93 triples · 7 KB source

| Format        | Out size (bytes)       | Enc time   | Dec time   | Size %   | Enc %   | Dec %   |
| :------------ | :--------------------- | :--------- | :--------- | :------- | :------ | :------ |
| Turtle        | 7 KB (7 107 B)         | 164 µs     | 469 µs     | 100%     | 100%    | 100%    |
| N-Triples     | 15 KB (14 916 B)       | 108 µs     | 374 µs     | 210%     | 66%     | 80%     |
| JSON-LD expanded | 15 KB (15 368 B)       | 152 µs     | 305 µs     | 216%     | 92%     | 65%     |
| JSON-LD compact | 9 KB (9 644 B)         | 326 µs     | 256 µs     | 136%     | 198%    | 55%     |
| JSON-LD flattened | 9 KB (9 644 B)         | 366 µs     | 253 µs     | 136%     | 223%    | 54%     |
| RDF/XML       | 10 KB (10 033 B)       | 188 µs     | 5.7 ms     | 141%     | 115%    | 1205%   |
| Jelly         | **6 KB (6 326 B)**     | **87 µs**  | **37 µs**  | **89%**  | **53%** | **8%**  |

> Baseline: **Turtle** — enc 164 µs, dec 469 µs. Enc/Dec % < 100% = faster, > 100% = slower.

## Graph Codecs — Large (schema.org.ttl)

Source: schema.org.ttl · 17.2k triples · 1.0 MB source

| Format        | Out size (bytes)       | Enc time   | Dec time   | Size %   | Enc %   | Dec %   |
| :------------ | :--------------------- | :--------- | :--------- | :------- | :------ | :------ |
| Turtle        | 1001 KB (1 024 861 B)  | 19 ms      | 82 ms      | 100%     | 100%    | 100%    |
| N-Triples     | 2.1 MB (2 247 393 B)   | 19 ms      | 88 ms      | 219%     | 104%    | 107%    |
| JSON-LD expanded | 2.2 MB (2 281 247 B)   | 31 ms      | 74 ms      | 223%     | 168%    | 90%     |
| JSON-LD compact | 1.4 MB (1 435 345 B)   | 52 ms      | 56 ms      | 140%     | 283%    | 68%     |
| JSON-LD flattened | 1.4 MB (1 435 345 B)   | 67 ms      | 56 ms      | 140%     | 361%    | 69%     |
| RDF/XML       | 1.4 MB (1 480 044 B)   | 40 ms      | 79 ms      | 144%     | 219%    | 96%     |
| Jelly         | **755 KB (773 314 B)** | **16 ms**  | **5.7 ms** | **75%**  | **86%** | **7%**  |

> Baseline: **Turtle** — enc 19 ms, dec 82 ms. Enc/Dec % < 100% = faster, > 100% = slower.

## Dataset Codecs — Tiny (5 quads, synthetic)

Source: 5 synthetic quads (default graph)

| Format        | Out size (bytes)       | Enc time   | Dec time   | Size %   | Enc %   | Dec %   |
| :------------ | :--------------------- | :--------- | :--------- | :------- | :------ | :------ |
| TriG          | 324 B                  | 17 µs      | 30 µs      | 100%     | 100%    | 100%    |
| N-Quads       | 350 B                  | **4 µs**   | 12 µs      | 108%     | **24%** | 41%     |
| JSON-LD expanded | 682 B                  | 10 µs      | 20 µs      | 210%     | 59%     | 66%     |
| JSON-LD compact | 440 B                  | 41 µs      | 36 µs      | 136%     | 242%    | 119%    |
| JSON-LD flattened | 440 B                  | 32 µs      | 18 µs      | 136%     | 193%    | 59%     |
| Jelly         | **212 B**              | 10 µs      | **7 µs**   | **65%**  | 59%     | **23%** |

> Baseline: **TriG** — enc 17 µs, dec 30 µs. Enc/Dec % < 100% = faster, > 100% = slower.

## Dataset Codecs — Small

Source: acl.ttl (wrapped in default graph) · 93 quads

| Format        | Out size (bytes)       | Enc time   | Dec time   | Size %   | Enc %   | Dec %   |
| :------------ | :--------------------- | :--------- | :--------- | :------- | :------ | :------ |
| TriG          | 7 KB (7 107 B)         | 134 µs     | 458 µs     | 100%     | 100%    | 100%    |
| N-Quads       | 15 KB (14 916 B)       | 100 µs     | 575 µs     | 210%     | 75%     | 125%    |
| JSON-LD expanded | 15 KB (15 368 B)       | 157 µs     | 295 µs     | 216%     | 118%    | 64%     |
| JSON-LD compact | 9 KB (9 644 B)         | 364 µs     | 253 µs     | 136%     | 272%    | 55%     |
| JSON-LD flattened | 9 KB (9 644 B)         | 365 µs     | 254 µs     | 136%     | 273%    | 55%     |
| Jelly         | **6 KB (6 328 B)**     | **86 µs**  | **34 µs**  | **89%**  | **64%** | **7%**  |

> Baseline: **TriG** — enc 134 µs, dec 458 µs. Enc/Dec % < 100% = faster, > 100% = slower.

## Dataset Codecs — Large (shard.trig)

Source: shard-mod-md5.trig · 34.3k quads · 2.3 MB source

| Format        | Out size (bytes)       | Enc time   | Dec time   | Size %   | Enc %   | Dec %   |
| :------------ | :--------------------- | :--------- | :--------- | :------- | :------ | :------ |
| TriG          | 2.3 MB (2 463 952 B)   | 76 ms      | 163 ms     | 100%     | 100%    | 100%    |
| N-Quads       | 12.8 MB (13 401 021 B) | 70 ms      | 410 ms     | 544%     | 92%     | 251%    |
| JSON-LD expanded | 7.8 MB (8 163 611 B)   | 92 ms      | 175 ms     | 331%     | 121%    | 107%    |
| JSON-LD compact | 3.6 MB (3 798 307 B)   | 288 ms     | 149 ms     | 154%     | 379%    | 91%     |
| JSON-LD flattened | 3.6 MB (3 798 307 B)   | 456 ms     | 156 ms     | 154%     | 598%    | 95%     |
| Jelly         | **1.8 MB (1 853 610 B)** | **42 ms**  | **20 ms**  | **75%**  | **55%** | **12%** |

> Baseline: **TriG** — enc 76 ms, dec 163 ms. Enc/Dec % < 100% = faster, > 100% = slower.

## Per-Triple Encode Cost (µs/triple)

Shows how encode cost per triple changes with dataset size. Constant = linear scaling, increasing = super-linear overhead.

| Format        | Tiny (5)     | Small (93)   | Large (17.2k) | Ratio (Large/Small) |
| :------------ | :----------- | :----------- | :----------- | :----------------- |
| Turtle        | 10.262 µs    | 1.765 µs     | 1.076 µs     | 0.61×              |
| N-Triples     | 1.622 µs     | 1.165 µs     | 1.125 µs     | 0.97×              |
| JSON-LD expanded | 5.434 µs     | 1.629 µs     | 1.805 µs     | 1.11×              |
| JSON-LD compact | 12.704 µs    | 3.502 µs     | 3.051 µs     | 0.87×              |
| JSON-LD flattened | 9.744 µs     | 3.935 µs     | 3.890 µs     | 0.99×              |
| RDF/XML       | 10.019 µs    | 2.022 µs     | 2.353 µs     | 1.16×              |
| Jelly         | 5.155 µs     | 0.939 µs     | 0.923 µs     | 0.98×              |

> A ratio of ~1.0× means linear scaling. >1× indicates super-linear overhead at larger sizes.

## Per-Triple Decode Cost (µs/triple)

Shows how decode cost per triple changes with dataset size.

| Format        | Tiny (5)     | Small (93)   | Large (17.2k) | Ratio (Large/Small) |
| :------------ | :----------- | :----------- | :----------- | :----------------- |
| Turtle        | 6.571 µs     | 5.044 µs     | 4.761 µs     | 0.94×              |
| N-Triples     | 3.283 µs     | 4.025 µs     | 5.089 µs     | 1.26×              |
| JSON-LD expanded | 10.190 µs    | 3.275 µs     | 4.278 µs     | 1.31×              |
| JSON-LD compact | 8.464 µs     | 2.757 µs     | 3.254 µs     | 1.18×              |
| JSON-LD flattened | 4.565 µs     | 2.718 µs     | 3.263 µs     | 1.20×              |
| RDF/XML       | 1101.460 µs  | 60.803 µs    | 4.588 µs     | 0.08×              |
| Jelly         | 3.775 µs     | 0.398 µs     | 0.329 µs     | 0.83×              |

> A ratio of ~1.0× means linear scaling. >1× indicates super-linear overhead at larger sizes.

## Per-Quad Encode Cost (µs/quad)

Shows how encode cost per quad changes with dataset size.

| Format        | Tiny (5)     | Small (93)   | Large (34.3k) | Ratio (Large/Small) |
| :------------ | :----------- | :----------- | :----------- | :----------------- |
| TriG          | 3.348 µs     | 1.437 µs     | 2.222 µs     | 1.55×              |
| N-Quads       | 0.798 µs     | 1.076 µs     | 2.052 µs     | 1.91×              |
| JSON-LD expanded | 1.979 µs     | 1.693 µs     | 2.681 µs     | 1.58×              |
| JSON-LD compact | 8.108 µs     | 3.912 µs     | 8.415 µs     | 2.15×              |
| JSON-LD flattened | 6.448 µs     | 3.921 µs     | 13.296 µs    | 3.39×              |
| Jelly         | 1.969 µs     | 0.923 µs     | 1.230 µs     | 1.33×              |

> A ratio of ~1.0× means linear scaling. >1× indicates super-linear overhead at larger sizes.

## Per-Quad Decode Cost (µs/quad)

Shows how decode cost per quad changes with dataset size.

| Format        | Tiny (5)     | Small (93)   | Large (34.3k) | Ratio (Large/Small) |
| :------------ | :----------- | :----------- | :----------- | :----------------- |
| TriG          | 5.973 µs     | 4.925 µs     | 4.764 µs     | 0.97×              |
| N-Quads       | 2.431 µs     | 6.179 µs     | 11.978 µs    | 1.94×              |
| JSON-LD expanded | 3.932 µs     | 3.176 µs     | 5.112 µs     | 1.61×              |
| JSON-LD compact | 7.131 µs     | 2.724 µs     | 4.346 µs     | 1.60×              |
| JSON-LD flattened | 3.517 µs     | 2.731 µs     | 4.548 µs     | 1.67×              |
| Jelly         | 1.379 µs     | 0.366 µs     | 0.574 µs     | 1.57×              |

> A ratio of ~1.0× means linear scaling. >1× indicates super-linear overhead at larger sizes.

---

*Benchmark run in JIT (dart run). Results reflect warm JIT throughput, not AOT-compiled production performance.*
