# RDF Codec Performance Benchmark

Generated: 2026-03-20T12:33:01.675444

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
| Turtle        | 324 B                  | 52 µs      | 35 µs      | 100%     | 100%    | 100%    |
| N-Triples     | 350 B                  | 12 µs      | 17 µs      | 108%     | 23%     | 49%     |
| JSON-LD       | 440 B                  | 44 µs      | 29 µs      | 136%     | 85%     | 82%     |
| RDF/XML       | 760 B                  | 59 µs      | 5.7 ms     | 235%     | 115%    | 16442%  |
| Jelly         | 210 B                  | 38 µs      | 38 µs      | 65%      | 73%     | 110%    |

> Baseline: **Turtle** — enc 52 µs, dec 35 µs. Enc/Dec % < 100% = faster, > 100% = slower.

## Graph Codecs — Small (acl.ttl)

Source: acl.ttl · 93 triples · 7 KB source

| Format        | Out size (bytes)       | Enc time   | Dec time   | Size %   | Enc %   | Dec %   |
| :------------ | :--------------------- | :--------- | :--------- | :------- | :------ | :------ |
| Turtle        | 7 KB (7 107 B)         | 163 µs     | 474 µs     | 100%     | 100%    | 100%    |
| N-Triples     | 15 KB (14 916 B)       | 115 µs     | 385 µs     | 210%     | 71%     | 81%     |
| JSON-LD       | 9 KB (9 644 B)         | 139 µs     | 154 µs     | 136%     | 85%     | 32%     |
| RDF/XML       | 10 KB (9 807 B)        | 220 µs     | 5.8 ms     | 138%     | 135%    | 1228%   |
| Jelly         | 6 KB (6 326 B)         | 153 µs     | 124 µs     | 89%      | 94%     | 26%     |

> Baseline: **Turtle** — enc 163 µs, dec 474 µs. Enc/Dec % < 100% = faster, > 100% = slower.

## Graph Codecs — Large (schema.org.ttl)

Source: schema.org.ttl · 17.2k triples · 1.0 MB source

| Format        | Out size (bytes)       | Enc time   | Dec time   | Size %   | Enc %   | Dec %   |
| :------------ | :--------------------- | :--------- | :--------- | :------- | :------ | :------ |
| Turtle        | 1001 KB (1 024 861 B)  | 19 ms      | 82 ms      | 100%     | 100%    | 100%    |
| N-Triples     | 2.1 MB (2 247 393 B)   | 21 ms      | 87 ms      | 219%     | 109%    | 105%    |
| JSON-LD       | 1.4 MB (1 435 345 B)   | 21 ms      | 33 ms      | 140%     | 108%    | 40%     |
| RDF/XML       | 1.4 MB (1 477 689 B)   | 44 ms      | 87 ms      | 144%     | 230%    | 106%    |
| Jelly         | 755 KB (773 240 B)     | 40 ms      | 29 ms      | 75%      | 209%    | 35%     |

> Baseline: **Turtle** — enc 19 ms, dec 82 ms. Enc/Dec % < 100% = faster, > 100% = slower.

## Dataset Codecs — Tiny (5 quads, synthetic)

Source: 5 synthetic quads (default graph)

| Format        | Out size (bytes)       | Enc time   | Dec time   | Size %   | Enc %   | Dec %   |
| :------------ | :--------------------- | :--------- | :--------- | :------- | :------ | :------ |
| TriG          | 324 B                  | 15 µs      | 25 µs      | 100%     | 100%    | 100%    |
| N-Quads       | 350 B                  | 4 µs       | 13 µs      | 108%     | 29%     | 52%     |
| JSON-LD       | 440 B                  | 18 µs      | 10 µs      | 136%     | 120%    | 40%     |
| Jelly         | 212 B                  | 21 µs      | 17 µs      | 65%      | 139%    | 69%     |

> Baseline: **TriG** — enc 15 µs, dec 25 µs. Enc/Dec % < 100% = faster, > 100% = slower.

## Dataset Codecs — Small

Source: acl.ttl (wrapped in default graph) · 93 quads

| Format        | Out size (bytes)       | Enc time   | Dec time   | Size %   | Enc %   | Dec %   |
| :------------ | :--------------------- | :--------- | :--------- | :------- | :------ | :------ |
| TriG          | 7 KB (7 107 B)         | 136 µs     | 472 µs     | 100%     | 100%    | 100%    |
| N-Quads       | 15 KB (14 916 B)       | 105 µs     | 523 µs     | 210%     | 77%     | 111%    |
| JSON-LD       | 9 KB (9 644 B)         | 137 µs     | 147 µs     | 136%     | 101%    | 31%     |
| Jelly         | 6 KB (6 328 B)         | 153 µs     | 121 µs     | 89%      | 112%    | 26%     |

> Baseline: **TriG** — enc 136 µs, dec 472 µs. Enc/Dec % < 100% = faster, > 100% = slower.

## Dataset Codecs — Large (shard.trig)

Source: shard-mod-md5.trig · 34.3k quads · 2.3 MB source

| Format        | Out size (bytes)       | Enc time   | Dec time   | Size %   | Enc %   | Dec %   |
| :------------ | :--------------------- | :--------- | :--------- | :------- | :------ | :------ |
| TriG          | 2.3 MB (2 463 952 B)   | 75 ms      | 169 ms     | 100%     | 100%    | 100%    |
| N-Quads       | 12.8 MB (13 401 021 B) | 71 ms      | 405 ms     | 544%     | 95%     | 239%    |
| JSON-LD       | 3.9 MB (4 072 259 B)   | 122 ms     | 822 ms     | 165%     | 163%    | 485%    |
| Jelly         | 1.8 MB (1 853 608 B)   | 96 ms      | 72 ms      | 75%      | 128%    | 42%     |

> Baseline: **TriG** — enc 75 ms, dec 169 ms. Enc/Dec % < 100% = faster, > 100% = slower.

---

*Benchmark run in JIT (dart run). Results reflect warm JIT throughput, not AOT-compiled production performance.*
