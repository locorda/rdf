import 'package:rdf_canonicalization/src/canonical/canonical_util.dart';
import 'package:rdf_canonicalization/src/canonical/identifier_issuer.dart';
import 'package:rdf_core/rdf_core.dart';

typedef CanonicalizationState = ({
  Iterable<Quad> quads,
  Map<BlankNodeTerm, InputBlankNodeIdentifier> blankNodeIdentifiers,
  /**
   * Maps a blank node identifier to the set of quads in which it appears - which is also called the mention set in the specification.
   */
  Map<InputBlankNodeIdentifier, Set<Quad>> blankNodeToQuadsMap,
  Map<HashString, List<InputBlankNodeIdentifier>> hashToBlankNodesMap,
  Map<InputBlankNodeIdentifier, HashString> blankNodeToFirstDegreeHash,
  IdentifierIssuer canonicalIssuer,
});
