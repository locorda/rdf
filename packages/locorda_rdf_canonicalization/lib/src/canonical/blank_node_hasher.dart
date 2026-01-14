import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:logging/logging.dart';
import 'package:locorda_rdf_canonicalization/src/canonical/canonicalization_state.dart';
import 'package:locorda_rdf_core/core.dart';

import 'canonical_util.dart';
import 'identifier_issuer.dart';
import 'quad_serializer.dart';

final _log = Logger('locorda_rdf_canonicalization.blank_node_hasher');
typedef HashNDegreeResult = ({HashString hash, IdentifierIssuer issuer});

enum Position {
  subject('s'),
  object('o'),
  graph('g');

  final String label;
  const Position(this.label);
}

/// Handles hash computation for blank nodes during RDF canonicalization.
/// Encapsulates the logic for both first-degree and N-degree hash computation
/// as specified in the RDF Dataset Canonicalization specification.
class BlankNodeHasher {
  final QuadSerializer quadSerializer;
  final CanonicalizationOptions options;

  BlankNodeHasher({
    required this.options,
  }) : quadSerializer = QuadSerializer();

  /// Get the hash function based on the configured algorithm.
  Hash _getHashFunction() {
    switch (options.hashAlgorithm) {
      case CanonicalHashAlgorithm.sha256:
        return sha256;
      case CanonicalHashAlgorithm.sha384:
        return sha384;
    }
  }

  /// Computes the first-degree hash for a blank node identifier.
  /// This hash is based only on the immediate quads that contain the blank node.
  ///
  /// Implements https://www.w3.org/TR/rdf-canon/#hash-1d-quads
  HashString hashFirstDegreeQuads(
      CanonicalizationState state, InputBlankNodeIdentifier identifier) {
    final mentions = state.blankNodeToQuadsMap[identifier] ?? {};
    final nquads = mentions
        .map((quad) => quadSerializer.toFirstDegreeNQuad(
            state.blankNodeIdentifiers, quad, identifier))
        .toList();

    // Sort in Unicode code point order for deterministic results
    nquads.sort();

    // Concatenate and hash
    return _computeHash(nquads.join(''));
  }

  HashString _computeHash(String input) {
    final bytes = utf8.encode(input);
    final digest = _getHashFunction().convert(bytes);
    return digest.toString();
  }

  HashString _hashRelatedBlankNode(
      CanonicalizationState state,
      InputBlankNodeIdentifier relatedId,
      Quad quad,
      IdentifierIssuer issuer,
      Position position) {
    StringBuffer input = StringBuffer(position.label);
    if (position != Position.graph) {
      input.write('<');
      switch (quad.predicate) {
        case IriTerm p:
          input.write(p.value);
      }
      input.write('>');
    }
    final CanonicalBlankNodeIdentifier? issuedIdentifier =
        state.canonicalIssuer.issuedIdentifiersMap[relatedId] ??
            issuer.issuedIdentifiersMap[relatedId];
    if (issuedIdentifier != null) {
      input.write('_:');
      input.write(issuedIdentifier);
    } else {
      final blankNodeHash = state.blankNodeToFirstDegreeHash[relatedId]!;
      input.write(blankNodeHash);
    }

    return _computeHash(input.toString());
  }

  /// Implements https://www.w3.org/TR/rdf-canon/#hash-nd-quads
  HashNDegreeResult hashNDegreeQuads(
      CanonicalizationState state,
      InputBlankNodeIdentifier identifier,
      IdentifierIssuer pathIdentifierIssuer) {
    // Create a new map Hn for relating hashes to related blank nodes
    final hn = <HashString, List<InputBlankNodeIdentifier>>{};
    for (final (relatedId: relatedId, hash: hash)
        in _createRelatedHashes(state, identifier, pathIdentifierIssuer)) {
      final ids = hn.putIfAbsent(hash, () => []);
      if (ids.contains(relatedId)) {
        _log.warning('Skipping duplicate relatedId $relatedId for hash $hash');
        continue; // skip duplicates
      }
      ids.add(relatedId);
    }
    final StringBuffer dataToHash = StringBuffer();
    final sortedRelatedHashes = hn.keys.toList()..sort();
    // 5. For each related hash in sorted order:
    for (final relatedHash in sortedRelatedHashes) {
      dataToHash.write(relatedHash);
      var chosenPath = '';
      IdentifierIssuer? chosenIssuer;
      final blankNodeList = hn[relatedHash]!;
      // 5.4 For each permutation p of blank node list:
      for (final p in createPermutations(blankNodeList)) {
        final result =
            _processPermutation(state, p, pathIdentifierIssuer, chosenPath);
        if (result != null) {
          chosenPath = result.path;
          chosenIssuer = result.issuer;
        }
      }
      // 5.5 Append chosen path to data to hash
      dataToHash.write(chosenPath);
      // 5.6 Replace issuer
      pathIdentifierIssuer = chosenIssuer!;
    }
    return (
      hash: _computeHash(dataToHash.toString()),
      issuer: pathIdentifierIssuer
    );
  }

  ({String path, IdentifierIssuer issuer})? _processPermutation(
    CanonicalizationState state,
    List<InputBlankNodeIdentifier> p,
    IdentifierIssuer pathIdentifierIssuer,
    String chosenPath,
  ) {
    var issuerCopy = pathIdentifierIssuer.clone();
    var path = '';
    final recursionList = <InputBlankNodeIdentifier>[];
    // TODO: also no stable order here? We will issue identifiers
    // again, so the order will influence the result!
    // 5.4.4 For each related in p:
    for (final relatedId in p) {
      final canonicalId = state.canonicalIssuer.issuedIdentifiersMap[relatedId];
      if (canonicalId != null) {
        path += '_:';
        path += canonicalId;
      } else {
        if (!issuerCopy.issuedIdentifiersMap.containsKey(relatedId)) {
          recursionList.add(relatedId);
        }
        path += '_:';
        path += issuerCopy.issueIdentifier(relatedId);
      }

      if (chosenPath.isNotEmpty && _isGossipPathShorter(chosenPath, path)) {
        // Skip to the next permutation
        return null;
      }
    }
    // 5.4.5 For each related in recursionList:
    for (final relatedId in recursionList) {
      final result = hashNDegreeQuads(state, relatedId, issuerCopy);
      final tmpIdentifier = issuerCopy.issueIdentifier(relatedId);
      path += '_:$tmpIdentifier<${result.hash}>';
      issuerCopy = result.issuer;
      if (chosenPath.isNotEmpty && _isGossipPathShorter(chosenPath, path)) {
        // Skip to the next permutation
        return null;
      }
    }
    // 5.4.6
    if (chosenPath.isEmpty || _isGossipPathShorter(path, chosenPath)) {
      return (path: path, issuer: issuerCopy);
    }
    return null;
  }

  static bool _isGossipPathShorter(String path, String other) {
    // TODO: check if the implementation really is correct
    if (path.length < other.length) {
      return true;
    }
    return path.compareTo(other) <= 0;
  }

  Iterable<({InputBlankNodeIdentifier relatedId, HashString hash})>
      _createRelatedHashes(
          CanonicalizationState state,
          InputBlankNodeIdentifier identifier,
          IdentifierIssuer pathIdentifierIssuer) sync* {
    // Get the mention set
    final quads = state.blankNodeToQuadsMap[identifier]!;
    // TODO: unordered quads - do we need some stable order here?
    // The path identifier issuer will issue temporary ids and will
    // thus influence the hash result, but this is not a stable order!
    //
    for (final quad in quads) {
      for (final pos in Position.values) {
        final termAtPosition = switch (pos) {
          Position.subject => quad.subject,
          Position.object => quad.object,
          Position.graph => quad.graphName,
        };
        if (termAtPosition is! BlankNodeTerm) {
          continue; // skip non-blank nodes
        }
        final relatedId = state.blankNodeIdentifiers[termAtPosition]!;
        if (relatedId == identifier) {
          continue; // skip self
        }
        final hash = _hashRelatedBlankNode(
            state, relatedId, quad, pathIdentifierIssuer, pos);
        yield (relatedId: relatedId, hash: hash);
      }
    }
  }

  static List<List<InputBlankNodeIdentifier>> createPermutations(
      List<InputBlankNodeIdentifier> blankNodeList) {
    if (blankNodeList.isEmpty) return [[]];
    final first = blankNodeList.first;
    final rest = blankNodeList.sublist(1);
    final permsWithoutFirst = createPermutations(rest);
    final result = <List<InputBlankNodeIdentifier>>[];
    for (final perm in permsWithoutFirst) {
      for (int i = 0; i <= perm.length; i++) {
        final newPerm = List<InputBlankNodeIdentifier>.from(perm)
          ..insert(i, first);
        result.add(newPerm);
      }
    }
    return result;
  }
}
