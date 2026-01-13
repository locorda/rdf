import 'package:rdf_canonicalization/src/canonical/canonical_util.dart'
    show InputBlankNodeIdentifier, CanonicalBlankNodeIdentifier;

class IdentifierIssuer {
  String identifierPrefix;
  int identifierCounter;
  final Map<InputBlankNodeIdentifier, CanonicalBlankNodeIdentifier>
      issuedIdentifiersMap;
  // For convenience, keep a list of input identifiers for which we issued identifiers in order
  final List<InputBlankNodeIdentifier> inputIdentifiers;

  IdentifierIssuer([String? identifierPrefix])
      : identifierPrefix = identifierPrefix ?? 'c14n',
        identifierCounter = 0,
        inputIdentifiers = [],
        issuedIdentifiersMap =
            <InputBlankNodeIdentifier, CanonicalBlankNodeIdentifier>{};

  CanonicalBlankNodeIdentifier issueIdentifier(
      InputBlankNodeIdentifier existingIdentifier) {
    // Step 1: If there is a map entry for existing identifier in issued identifiers map, return it.
    if (issuedIdentifiersMap.containsKey(existingIdentifier)) {
      return issuedIdentifiersMap[existingIdentifier]!;
    }

    // Step 2: Generate issued identifier by concatenating identifier prefix with the string value of identifier counter.
    final issuedIdentifier = '$identifierPrefix$identifierCounter';

    // Step 3: Add an entry mapping existing identifier to issued identifier to the issued identifiers map.
    issuedIdentifiersMap[existingIdentifier] = issuedIdentifier;
    inputIdentifiers.add(existingIdentifier);

    // Step 4: Increment identifier counter.
    identifierCounter++;

    // Step 5: Return issued identifier.
    return issuedIdentifier;
  }

  bool isIssued(InputBlankNodeIdentifier existingIdentifier) {
    return issuedIdentifiersMap.containsKey(existingIdentifier);
  }

  IdentifierIssuer clone() {
    final cloned = IdentifierIssuer(identifierPrefix);
    cloned.identifierCounter = identifierCounter;
    cloned.issuedIdentifiersMap.addAll(issuedIdentifiersMap);
    cloned.inputIdentifiers.addAll(inputIdentifiers);
    return cloned;
  }
}
