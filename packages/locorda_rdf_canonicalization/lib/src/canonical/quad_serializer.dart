import 'package:locorda_rdf_canonicalization/src/canonical/canonical_util.dart';
import 'package:locorda_rdf_core/core.dart';

import 'quad_extension.dart';

/// Handles serialization of RDF quads for canonicalization hashing purposes.
/// This class encapsulates the logic for converting quads to their string
/// representations with special handling for blank nodes during the hashing process.
class QuadSerializer {
  final NQuadsEncoder canonicalEncoder =
      NQuadsEncoder(options: NQuadsEncoderOptions(canonical: true));

  QuadSerializer();

  /// Serializes a quad for first-degree hashing with special blank node handling.
  /// The reference identifier is treated specially - it gets mapped to '_:a',
  /// while other blank nodes get mapped to '_:z'.
  String toFirstDegreeNQuad(
      Map<BlankNodeTerm, InputBlankNodeIdentifier> blankNodeIdentifiers,
      Quad quad,
      InputBlankNodeIdentifier referenceIdentifier) {
    final hIdentifiers = {
      for (final bnode in quad.blankNodes)
        bnode: blankNodeIdentifiers[bnode] == referenceIdentifier ? 'a' : 'z'
    };
    // TODO: optimize by implementing encodeQuad in canonicalEncoder
    return canonicalEncoder.encode(RdfDataset.fromQuads([quad]),
        blankNodeLabels: hIdentifiers);
  }
}
