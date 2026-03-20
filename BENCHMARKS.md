# RDF Codec Performance Benchmark

Generated: 2026-03-20T12:36:10.136158

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
| N-Triples     | 350 B                  | **9 µs**   | **17 µs**  | 108%     | **17%** | **50%** |
| JSON-LD       | 440 B                  | 43 µs      | 30 µs      | 136%     | 82%     | 87%     |
| RDF/XML       | 760 B                  | 65 µs      | 5.7 ms     | 235%     | 125%    | 16516%  |
| Jelly         | 210 B                  | 43 µs      | 36 µs      | **65%**  | 83%     | 104%    |

> Baseline: **Turtle** — enc 52 µs, dec 34 µs. Enc/Dec % < 100% = faster, > 100% = slower.

## Graph Codecs — Small (acl.ttl)

Source: acl.ttl · 93 triples · 7 KB source

| Format        | Out size (bytes)       | Enc time   | Dec time   | Size %   | Enc %   | Dec %   |
| :------------ | :--------------------- | :--------- | :--------- | :------- | :------ | :------ |
| Turtle        | 7 KB (7 107 B)         | 160 µs     | 482 µs     | 100%     | 100%    | 100%    |
| N-Triples     | 15 KB (14 916 B)       | **117 µs** | 394 µs     | 210%     | **73%** | 82%     |
| JSON-LD       | 9 KB (9 644 B)         | 143 µs     | 156 µs     | 136%     | 89%     | 32%     |
| RDF/XML       | 10 KB (9 807 B)        | 221 µs     | 5.8 ms     | 138%     | 138%    | 1206%   |
| Jelly         | 6 KB (6 326 B)         | 151 µs     | **123 µs** | **89%**  | 94%     | **26%** |

> Baseline: **Turtle** — enc 160 µs, dec 482 µs. Enc/Dec % < 100% = faster, > 100% = slower.

## Graph Codecs — Large (schema.org.ttl)

Source: schema.org.ttl · 17.2k triples · 1.0 MB source

| Format        | Out size (bytes)       | Enc time   | Dec time   | Size %   | Enc %   | Dec %   |
| :------------ | :--------------------- | :--------- | :--------- | :------- | :------ | :------ |
| Turtle        | 1001 KB (1 024 861 B)  | **19 ms**  | 82 ms      | 100%     | **100%** | 100%    |
| N-Triples     | 2.1 MB (2 247 393 B)   | 21 ms      | 87 ms      | 219%     | 110%    | 107%    |
| JSON-LD       | 1.4 MB (1 435 345 B)   | 21 ms      | 33 ms      | 140%     | 108%    | 40%     |
| RDF/XML       | 1.4 MB (1 477 689 B)   | 44 ms      | 85 ms      | 144%     | 230%    | 104%    |
| Jelly         | 755 KB (773 240 B)     | 42 ms      | **29 ms**  | **75%**  | 218%    | **35%** |

> Baseline: **Turtle** — enc 19 ms, dec 82 ms. Enc/Dec % < 100% = faster, > 100% = slower.

## Dataset Codecs — Tiny (5 quads, synthetic)

Source: 5 synthetic quads (default graph)

| Format        | Out size (bytes)       | Enc time   | Dec time   | Size %   | Enc %   | Dec %   |
| :------------ | :--------------------- | :--------- | :--------- | :------- | :------ | :------ |
| TriG          | 324 B                  | 17 µs      | 25 µs      | 100%     | 100%    | 100%    |
| N-Quads       | 350 B                  | **4 µs**   | 13 µs      | 108%     | **24%** | 52%     |
| JSON-LD       | 440 B                  | 19 µs      | **9 µs**   | 136%     | 109%    | **38%** |
| Jelly         | 212 B                  | 22 µs      | 17 µs      | **65%**  | 125%    | 70%     |

> Baseline: **TriG** — enc 17 µs, dec 25 µs. Enc/Dec % < 100% = faster, > 100% = slower.

## Dataset Codecs — Small

Source: acl.ttl (wrapped in default graph) · 93 quads

| Format        | Out size (bytes)       | Enc time   | Dec time   | Size %   | Enc %   | Dec %   |
| :------------ | :--------------------- | :--------- | :--------- | :------- | :------ | :------ |
| TriG          | 7 KB (7 107 B)         | 134 µs     | 473 µs     | 100%     | 100%    | 100%    |
| N-Quads       | 15 KB (14 916 B)       | **107 µs** | 524 µs     | 210%     | **79%** | 111%    |
| JSON-LD       | 9 KB (9 644 B)         | 138 µs     | 148 µs     | 136%     | 102%    | 31%     |
| Jelly         | 6 KB (6 328 B)         | 155 µs     | **120 µs** | **89%**  | 115%    | **25%** |

> Baseline: **TriG** — enc 134 µs, dec 473 µs. Enc/Dec % < 100% = faster, > 100% = slower.

## Dataset Codecs — Large (shard.trig)

Source: shard-mod-md5.trig · 34.3k quads · 2.3 MB source

| Format        | Out size (bytes)       | Enc time   | Dec time   | Size %   | Enc %   | Dec %   |
| :------------ | :--------------------- | :--------- | :--------- | :------- | :------ | :------ |
| TriG          | 2.3 MB (2 463 952 B)   | 73 ms      | 169 ms     | 100%     | 100%    | 100%    |
| N-Quads       | 12.8 MB (13 401 021 B) | **71 ms**  | 405 ms     | 544%     | **97%** | 240%    |
| JSON-LD       | 3.9 MB (4 072 259 B)   | 122 ms     | 830 ms     | 165%     | 167%    | 493%    |
| Jelly         | 1.8 MB (1 853 608 B)   | 98 ms      | **71 ms**  | **75%**  | 133%    | **42%** |

> Baseline: **TriG** — enc 73 ms, dec 169 ms. Enc/Dec % < 100% = faster, > 100% = slower.

---

*Benchmark run in JIT (dart run). Results reflect warm JIT throughput, not AOT-compiled production performance.*
