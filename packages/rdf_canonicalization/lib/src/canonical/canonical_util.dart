import 'package:rdf_canonicalization/src/canonical/canonicalization_state.dart';
import 'package:rdf_core/rdf_core.dart';

import 'blank_node_hasher.dart';
import 'identifier_issuer.dart';
import 'quad_extension.dart';

enum CanonicalHashAlgorithm { sha256, sha384 }

class CanonicalizationOptions {
  final CanonicalHashAlgorithm hashAlgorithm;
  final String blankNodePrefix;

  const CanonicalizationOptions(
      {this.hashAlgorithm = CanonicalHashAlgorithm.sha256,
      this.blankNodePrefix = 'c14n'});
}

class CanonicalizedRdfDataset {
  final RdfDataset inputDataset;
  final RdfDataset canonicalDataset;
  // Optional: if input was provided in a way that blank nodes had labels,
  // this map contains the mapping from blank node terms to their original labels.
  final Map<BlankNodeTerm, String>? inputIdentifiers;
  final Map<BlankNodeTerm, String> issuedIdentifiers;

  CanonicalizedRdfDataset(
      {required this.inputDataset,
      required this.canonicalDataset,
      required this.inputIdentifiers,
      required this.issuedIdentifiers});
}

typedef InputBlankNodeIdentifier = String;
typedef CanonicalBlankNodeIdentifier = String;
typedef HashString = String;

/// Implementation of https://www.w3.org/TR/rdf-canon/#canon-algo-algo
CanonicalizedRdfDataset toCanonicalizedRdfDataset(RdfDataset dataset,
    {Map<BlankNodeTerm, InputBlankNodeIdentifier>? inputLabels,
    CanonicalizationOptions? options}) {
  options ??= const CanonicalizationOptions();
  final hasher = BlankNodeHasher(options: options);

  // Step 1: Create canonicalization state
  final CanonicalizationState state = _createCanonicalizationState(dataset,
      inputLabels: inputLabels, options: options);

  // Step 2: Fill the blank node to quads map - the mentions of each blank node
  for (final quad in state.quads) {
    for (final bnode in quad.blankNodes) {
      final identifier = state.blankNodeIdentifiers[bnode]!;

      state.blankNodeToQuadsMap.putIfAbsent(identifier, () => {}).add(quad);
    }
  }

  // Step 3: Create the First Degree Hashes for all blank nodes

  for (final identifier in state.blankNodeToQuadsMap.keys) {
    final HashString hash = hasher.hashFirstDegreeQuads(state, identifier);

    // Add to hash-to-blank-nodes map
    state.hashToBlankNodesMap.putIfAbsent(hash, () => []).add(identifier);
    // Track first-degree hash for the blank node for later (re)use
    state.blankNodeToFirstDegreeHash[identifier] = hash;
  }

  // Step 4: Process hashes in lexicographical order
  final sortedHashes = state.hashToBlankNodesMap.keys.toList()..sort();
  final nonUniqueHashes = <HashString>[];

  for (final hash in sortedHashes) {
    final identifiers = state.hashToBlankNodesMap[hash]!;
    if (identifiers.length == 1) {
      // Unique hash - issue canonical identifier immediately
      state.canonicalIssuer.issueIdentifier(identifiers.first);
    } else {
      // Non-unique hash - handle later
      nonUniqueHashes.add(hash);
    }
  }

  // Step 5: For every non-unique hash, use N-degree hashing
  // just to be sure sort the non-unique hashes even though they should already be sorted
  final sortedNonUniqueHashes = nonUniqueHashes.toList()..sort();
  for (final HashString hash in sortedNonUniqueHashes) {
    // Step 5.1: Create a list
    final hashPathList = <HashNDegreeResult>[];

    // Step 5.2: For each blank node identifier in identifier list
    final List<InputBlankNodeIdentifier> identifiers =
        state.hashToBlankNodesMap[hash]!;
    // Note: the identifiers here cannot be stable ordered, but that should not matter
    // because each gets is own clean temporary issuer and we sort by hash later anyway
    for (final identifier in identifiers) {
      if (state.canonicalIssuer.isIssued(identifier)) {
        // already issued, skip
        continue;
      }
      // issuer for temporary blank node identifiers
      IdentifierIssuer temporaryIssuer = IdentifierIssuer('b');
      temporaryIssuer.issueIdentifier(identifier);

      final (hash: hash, issuer: issuer) =
          hasher.hashNDegreeQuads(state, identifier, temporaryIssuer);
      hashPathList.add((hash: hash, issuer: issuer));
    }
    // Step 5.3: Sort the list lexicographically by hash
    hashPathList.sort((a, b) => a.hash.compareTo(b.hash));
    for (final entry in hashPathList) {
      final issuedIdentifiers = entry.issuer.inputIdentifiers;
      for (final identifier in issuedIdentifiers) {
        state.canonicalIssuer.issueIdentifier(identifier);
      }
    }
  }

  // Step 6: Build the result
  final issuedIdentifiers = <BlankNodeTerm, String>{};
  for (final entry in state.blankNodeIdentifiers.entries) {
    final blankNode = entry.key;
    final originalIdentifier = entry.value;
    final canonicalIdentifier =
        state.canonicalIssuer.issuedIdentifiersMap[originalIdentifier];
    if (canonicalIdentifier != null) {
      issuedIdentifiers[blankNode] = canonicalIdentifier;
    } else {
      throw StateError(
          'No canonical identifier issued for blank node $blankNode with original identifier $originalIdentifier');
    }
  }

  return CanonicalizedRdfDataset(
    inputDataset: dataset,
    inputIdentifiers: inputLabels,
    issuedIdentifiers: issuedIdentifiers,
    // Note that the correct ordering in the canonical dataset cannot be
    // created here because it depends on the nquad serialization.
    // The only difference to inputDataset is actually that duplicates are removed.
    canonicalDataset: RdfDataset.fromQuads(state.quads),
  );
}

CanonicalizedRdfDataset toCanonicalizedRdfDatasetFromNQuads(String nquads,
    {CanonicalizationOptions? options}) {
  NQuadsDecoder decoder = NQuadsDecoder();
  final (blankNodeLabels: inputLabels, dataset: inputDataset) =
      decoder.decode(nquads);

  return toCanonicalizedRdfDataset(inputDataset,
      inputLabels: inputLabels, options: options);
}

String toNQuads(CanonicalizedRdfDataset canonicalized,
    {CanonicalizationOptions? options}) {
  final NQuadsEncoder encoder =
      NQuadsEncoder(options: NQuadsEncoderOptions(canonical: true));
  return encoder.encode(canonicalized.canonicalDataset,
      blankNodeLabels: canonicalized.issuedIdentifiers,
      generateNewBlankNodeLabels: false);
}

/// https://www.w3.org/TR/rdf-canon/#canonicalization states: "Canonicalization is the process of transforming an input dataset to its serialized canonical form"
String canonicalize(RdfDataset dataset, {CanonicalizationOptions? options}) {
  options ??= const CanonicalizationOptions();
  final canonicalized = toCanonicalizedRdfDataset(dataset, options: options);
  return toNQuads(canonicalized, options: options);
}

String canonicalizeGraph(RdfGraph graph, {CanonicalizationOptions? options}) {
  return canonicalize(RdfDataset.fromDefaultGraph(graph), options: options);
}

bool isIsomorphic(RdfDataset a, RdfDataset b,
    {CanonicalizationOptions? options}) {
  options ??= const CanonicalizationOptions();
  final canA = canonicalize(a, options: options);
  final canB = canonicalize(b, options: options);

  // Two datasets are isomorphic if their canonical serializations match
  return canA == canB;
}

bool isIsomorphicGraphs(RdfGraph a, RdfGraph b,
    {CanonicalizationOptions? options}) {
  final canA = canonicalizeGraph(a, options: options);
  final canB = canonicalizeGraph(b, options: options);

  // Two graphs are isomorphic if their canonical serializations match
  return canA == canB;
}

/// Helper function to create canonicalization state from dataset

Map<BlankNodeTerm, InputBlankNodeIdentifier> _createBlankNodeIdentifiersMap(
    Iterable<Quad> dataset,
    Map<BlankNodeTerm, InputBlankNodeIdentifier>? inputLabels,
    CanonicalizationOptions options) {
  // Generate identifiers for blank nodes if not provided
  final blankNodeIdentifiers = <BlankNodeTerm, InputBlankNodeIdentifier>{
    if (inputLabels != null) ...inputLabels
  };
  final identifiers = <InputBlankNodeIdentifier>{
    if (inputLabels != null) ...inputLabels.values
  };

  // Generate temporary identifiers and track the mentions of blank nodes
  var counter = 0;
  for (final quad in dataset) {
    for (final bnode in quad.blankNodes) {
      InputBlankNodeIdentifier? identifier = blankNodeIdentifiers[bnode];
      if (identifier == null) {
        // should not happen, but just in case, avoid collisions
        while (identifiers.contains(identifier = '_:n$counter')) {
          counter++;
        }
        identifiers.add(identifier);
        blankNodeIdentifiers[bnode] = identifier;
      }
    }
  }
  return blankNodeIdentifiers;
}

/// Deduplicate an RDF dataset to ensure set semantics (no duplicate quads)
Set<Quad> _deduplicateQuads(RdfDataset dataset) {
  final uniqueQuads = <Quad>{};
  for (final quad in dataset.quads) {
    uniqueQuads.add(quad);
  }
  return uniqueQuads;
}

CanonicalizationState _createCanonicalizationState(RdfDataset dataset,
    {Map<BlankNodeTerm, InputBlankNodeIdentifier>? inputLabels,
    required CanonicalizationOptions options}) {
  final allQuads = _deduplicateQuads(dataset);
  final blankNodeIdentifiers =
      _createBlankNodeIdentifiersMap(allQuads, inputLabels, options);
  return (
    quads: allQuads,
    blankNodeIdentifiers: blankNodeIdentifiers,
    blankNodeToQuadsMap: <InputBlankNodeIdentifier, Set<Quad>>{},
    hashToBlankNodesMap: <HashString, List<InputBlankNodeIdentifier>>{},
    blankNodeToFirstDegreeHash: <InputBlankNodeIdentifier, HashString>{},
    canonicalIssuer: IdentifierIssuer(options.blankNodePrefix),
  );
}
