/// Prefix generation utilities for RDF serializers
///
/// This module provides common functionality for analyzing RDF graphs and generating
/// namespace prefixes automatically. It is used by both Turtle and JSON-LD encoders
/// to provide consistent prefix generation behavior.
library prefix_generator;

import 'package:logging/logging.dart';
import 'package:locorda_rdf_core/src/graph/rdf_graph.dart';
import 'package:locorda_rdf_core/src/graph/rdf_term.dart';
import 'package:locorda_rdf_core/src/iri_util.dart';
import 'package:locorda_rdf_core/src/rdf_encoder.dart';
import 'package:locorda_rdf_core/src/vocab/namespaces.dart';
import 'package:locorda_rdf_core/src/vocab/rdf.dart';

final _log = Logger('locorda_rdf_core.iri_compaction');

enum IriRole {
  subject,
  predicate,
  object,
  type,
  datatype,
}

enum IriCompactionType {
  /// Use a prefix for the IRI
  prefixed,

  /// Use a full IRI in angle brackets
  full,

  /// Use a relative IRI (without base URI)
  relative,
}

/// Function type for filtering IRIs that should be considered for prefix generation.
///
/// This allows different serializers to implement their own logic for determining
/// which IRIs should have prefixes generated (vs being relativized, etc).
///
/// Parameters:
/// - [iri] The IRI to check
/// - [isPredicate] Whether this IRI is being used as a predicate
///
/// Returns true if the IRI should be processed for prefix generation.
typedef IriFilter = bool Function(IriTerm iri, {required IriRole role});
typedef AllowedCompactionTypes = Map<IriRole, Set<IriCompactionType>>;
final allowedCompactionTypesAll = {
  for (final role in IriRole.values) role: {...IriCompactionType.values},
};

class IriCompactionSettings {
  /// Controls automatic generation of namespace prefixes for IRIs without matching prefixes.
  ///
  /// When set to `true` (default), the encoder will automatically generate namespace
  /// prefixes for IRIs that don't have a matching prefix in either the custom prefixes
  /// or the standard namespace mappings.
  ///
  /// The prefix generation process:
  /// 1. Attempts to extract a meaningful namespace from the IRI (splitting at '/' or '#')
  /// 2. Skips IRIs with only protocol specifiers (e.g., "http://")
  /// 3. Only generates prefixes for namespaces ending with '/' or '#'
  ///    (proper RDF namespace delimiters)
  /// 4. Uses RdfNamespaceMappings.getOrGeneratePrefix to create a compact, unique prefix
  ///
  /// Setting this to `false` will result in all IRIs without matching prefixes being
  /// written as full IRIs in angle brackets (e.g., `<http://example.org/term>`).
  ///
  /// This option is particularly useful for:
  /// - Reducing the verbosity of the output
  /// - Making the serialized data more human-readable
  /// - Automatically handling unknown namespaces without manual prefix declaration
  final bool generateMissingPrefixes;

  final AllowedCompactionTypes allowedCompactionTypes;

  final Set<IriTerm> specialPredicates;
  final Set<IriTerm> specialDatatypes;

  /// Controls how fragment IRIs are rendered.
  ///
  /// When true, fragment IRIs are rendered as prefixed IRIs with empty prefix.
  /// When false (default), they are rendered as relative IRIs.
  final bool renderFragmentsAsPrefixed;

  /// Options for controlling IRI relativization behavior during compaction.
  ///
  /// These options determine how aggressively IRIs are relativized when a base IRI
  /// is provided. Different use cases may prefer different relativization strategies.
  final IriRelativizationOptions iriRelativization;

  IriCompactionSettings({
    required this.generateMissingPrefixes,
    required AllowedCompactionTypes? allowedCompactionTypes,
    required this.specialPredicates,
    required this.specialDatatypes,
    this.renderFragmentsAsPrefixed = false,
    this.iriRelativization = const IriRelativizationOptions.full(),
  }) : allowedCompactionTypes =
            allowedCompactionTypes ?? allowedCompactionTypesAll;
}

sealed class CompactIri {}

final class PrefixedIri extends CompactIri {
  final String prefix;
  final String namespace;
  final String? localPart;

  String get colonSeparated => localPart == null || localPart!.isEmpty
      ? (prefix.isEmpty ? ':' : '$prefix:')
      : '${prefix.isEmpty ? '' : '$prefix'}:$localPart';

  PrefixedIri(this.prefix, this.namespace, String? localPart)
      : localPart = localPart?.isEmpty == true ? null : localPart;
}

final class FullIri extends CompactIri {
  final String iri;
  FullIri(this.iri);
}

final class RelativeIri extends CompactIri {
  final String relative;
  RelativeIri(this.relative);
}

final class SpecialIri extends CompactIri {
  final IriTerm iri;
  SpecialIri(this.iri);
}

final class IriCompactionResult {
  final Map<String, String> prefixes;

  /// Compacted IRIs indexed by [IriTerm]; each value is a fixed-length list
  /// of [IriRole.values.length] slots, accessed via [IriRole.index].
  ///
  /// Using a nested list instead of `Map<(IriTerm, IriRole), CompactIri>` avoids
  /// creating a record-tuple heap object on every lookup — critical for the
  /// O(unique_iris × encodings) output phase.
  final Map<IriTerm, List<CompactIri?>> compactIris;

  IriCompactionResult({
    required this.prefixes,
    required this.compactIris,
  });

  CompactIri compactIri(IriTerm iri, IriRole role) {
    final slot = compactIris[iri]?[role.index];
    if (slot == null) {
      final known = compactIris[iri];
      if (known != null) {
        final knownRoles = IriRole.values
            .where((r) => known[r.index] != null)
            .map((r) => r.name)
            .join(', ');
        _log.warning(
          'No compact IRI found for $iri with role ${role.name}. '
          'Did you specify the correct IriRole? '
          'Found this IRI for roles: $knownRoles. Will treat as full IRI.',
        );
      } else {
        _log.warning(
          'No compact IRI found for $iri with role ${role.name}. '
          'Is this IRI used in the graph? Will treat as full IRI.',
        );
      }
      return FullIri(iri.value);
    }
    return slot;
  }
}

/// Utility class for analyzing RDF graphs and generating namespace prefixes.
///
/// This class provides static methods for extracting used prefixes from RDF graphs
/// and automatically generating new prefixes for unknown namespaces. The logic is
/// shared between different RDF serializers to ensure consistent behavior.
class IriCompaction {
  final RdfNamespaceMappings _namespaceMappings;
  final IriCompactionSettings _settings;
  final bool Function(String) _isValidIriLocalPart;
  const IriCompaction(
      this._namespaceMappings, this._settings, this._isValidIriLocalPart);

  IriCompactionResult compactAllIris(
    RdfGraph graph,
    Map<String, String> customPrefixes, {
    String? baseUri,
  }) {
    final prefixCandidates = {
      ..._namespaceMappings.asMap(),
    };
    prefixCandidates
        .removeWhere((key, value) => customPrefixes.values.contains(value));
    prefixCandidates.addAll(customPrefixes);

    final usedPrefixes = <String, String>{};
    // Indexed by IriRole.index (0..IriRole.values.length-1) to avoid record-tuple
    // allocations — each map lookup used to create a (IriTerm, IriRole) heap object.
    final compactIris = <IriTerm, List<CompactIri?>>{};
    // Create an inverted index for quick lookup
    final iriToPrefixMap = {
      for (final e in prefixCandidates.entries) e.value: e.key
    };
    if (iriToPrefixMap.length != prefixCandidates.length) {
      throw ArgumentError(
        'Duplicate namespace URIs found in prefix candidates: $prefixCandidates',
      );
    }

    // Snapshot the original prefix keys before the main loop so the
    // post-processing step can distinguish user- / stdlib-provided prefixes
    // from generated ones without inspecting the mappings object again.
    final originalCandidateKeys = Set<String>.from(prefixCandidates.keys);

    // Iterate over triples directly — no intermediate list, no record-tuple
    // allocations. Each unique (IriTerm, IriRole) pair is processed exactly once;
    // duplicates are skipped via the per-term slot list.
    // Tracks the next free index per generated base-prefix (e.g. 'mo' → 3 means
    // 'mo1' and 'mo2' are taken). Passed to getOrGeneratePrefix so the
    // numbered-suffix search is O(1) amortized instead of O(N²).
    final prefixCounters = <String, int>{};
    void processIri(IriTerm iri, IriRole role) {
      final slots = compactIris[iri];
      if (slots != null && slots[role.index] != null) {
        return; // already resolved
      }
      final compacted = compactIri(
          iri, role, baseUri, iriToPrefixMap, prefixCandidates, customPrefixes,
          prefixCounters: prefixCounters);
      final dest =
          slots ?? List<CompactIri?>.filled(IriRole.values.length, null);
      if (slots == null) compactIris[iri] = dest;
      dest[role.index] = compacted;
      if (compacted
          case PrefixedIri(
            prefix: var prefix,
            namespace: var namespace,
          )) {
        // Add the prefix to all relevant maps
        usedPrefixes[prefix] = namespace;
        final oldNamespace = prefixCandidates[prefix];
        final oldPrefix = iriToPrefixMap[namespace];
        if (oldNamespace != null && oldNamespace != namespace) {
          throw ArgumentError(
            'Namespace conflict for prefix "$prefix": '
            'already mapped to "$oldNamespace", cannot map to "$namespace".',
          );
        }
        if (oldPrefix != null && oldPrefix != prefix) {
          throw ArgumentError(
            'Prefix conflict for namespace "$namespace": '
            'already mapped to "$oldPrefix", cannot map to "$prefix".',
          );
        }
        // Update candidates with new prefix
        prefixCandidates[prefix] = namespace;
        iriToPrefixMap[namespace] = prefix; // Update inverse mapping
      }
    }

    for (final triple in graph.triples) {
      if (triple.subject is IriTerm) {
        processIri(triple.subject as IriTerm, IriRole.subject);
      }
      if (triple.predicate is IriTerm) {
        processIri(triple.predicate as IriTerm, IriRole.predicate);
      }
      if (triple.object is IriTerm) {
        processIri(
          triple.object as IriTerm,
          triple.predicate == Rdf.type ? IriRole.type : IriRole.object,
        );
      } else if (triple.object is LiteralTerm) {
        processIri((triple.object as LiteralTerm).datatype, IriRole.datatype);
      }
    }

    // Post-processing: deterministic generated-prefix numbering.
    //
    // Generated prefix numbers (ns1, ns2, …) would otherwise depend on the
    // order in which namespaces are first encountered during triple iteration.
    // Because triple order can vary across decode→encode round-trips, we
    // re-number every generated prefix by sorting its namespace URI
    // alphabetically within its base-prefix group (e.g. all "ns*" entries),
    // producing stable, order-independent output.
    {
      final generated = usedPrefixes.entries
          .where((e) => !originalCandidateKeys.contains(e.key))
          .toList();

      if (generated.isNotEmpty) {
        // Group by base prefix (strip trailing digits).
        // e.g. "ns42" → "ns", "mo1" → "mo".
        final digitSuffix = RegExp(r'\d+$');
        final groups = <String, List<(String prefix, String namespace)>>{};
        for (final e in generated) {
          final base = e.key.replaceFirst(digitSuffix, '');
          (groups[base] ??= []).add((e.key, e.value));
        }

        final renaming = <String, String>{}; // oldPrefix → newPrefix
        for (final MapEntry(key: base, value: pairs) in groups.entries) {
          // Single-member groups are already stable: only one namespace competed
          // for this base prefix, so its assigned number (or lack thereof) is
          // fully determined by _tryGeneratePrefixFromUrl and is independent of
          // triple encounter order.
          if (pairs.length <= 1) continue;
          // Sort by namespace URI — makes numbering input-order-independent.
          pairs.sort((a, b) => a.$2.compareTo(b.$2));
          var num = 1;
          for (final (oldPrefix, _) in pairs) {
            // Skip indices that collide with a pre-existing non-generated
            // candidate so those prefixes are never shadowed.
            while (originalCandidateKeys.contains('$base$num')) {
              num++;
            }
            final newPrefix = '$base$num';
            num++;
            if (newPrefix != oldPrefix) renaming[oldPrefix] = newPrefix;
          }
        }

        if (renaming.isNotEmpty) {
          // Rebuild usedPrefixes, prefixCandidates, and iriToPrefixMap.
          // Renaming may form cycles (e.g. ns2↔ns8), so collect all the
          // namespace values BEFORE modifying the maps to avoid overwriting
          // an entry that another renaming still needs to read.
          final toAdd = <String, String>{}; // newPrefix → namespace
          for (final MapEntry(key: old, value: neo) in renaming.entries) {
            final ns = usedPrefixes.remove(old)!;
            prefixCandidates.remove(old);
            iriToPrefixMap[ns] = neo;
            toAdd[neo] = ns;
          }
          usedPrefixes.addAll(toAdd);
          prefixCandidates.addAll(toAdd);
          // Update every compactIris slot that references a renamed prefix.
          for (final slots in compactIris.values) {
            for (int i = 0; i < slots.length; i++) {
              final slot = slots[i];
              if (slot is PrefixedIri) {
                final neo = renaming[slot.prefix];
                if (neo != null) {
                  slots[i] = PrefixedIri(neo, slot.namespace, slot.localPart);
                }
              }
            }
          }
        }
      }
    }

    return IriCompactionResult(
        prefixes: usedPrefixes, compactIris: compactIris);
  }

  CompactIri compactIri(
      IriTerm term,
      IriRole role,
      String? baseUri,
      Map<String, String> iriToPrefixMap,
      Map<String, String> prefixCandidates,
      Map<String, String> customPrefixes,
      {required Map<String, int> prefixCounters}) {
    if (role == IriRole.predicate &&
        _settings.specialPredicates.contains(term)) {
      return SpecialIri(term);
    }
    if (role == IriRole.datatype && _settings.specialDatatypes.contains(term)) {
      return SpecialIri(term);
    }

    // In Turtle, predicates cannot be relativized (they must use prefixes or full IRIs)
    final allowedTypes = _settings.allowedCompactionTypes[role] ??
        IriCompactionType.values.toSet();

    final relativized = relativizeIri(term.value, baseUri,
        options: _settings.iriRelativization);
    final relativeUrl = (!allowedTypes.contains(IriCompactionType.relative) ||
            relativized == term.value)
        ? null
        : relativized;

    if (_settings.renderFragmentsAsPrefixed && relativized.startsWith('#')) {
      final existing = prefixCandidates[''];
      if (existing != null && existing != '#') {
        _log.warning(
            'Empty prefix already mapped to "$existing", cannot use it for fragment IRI "$relativized".');
      } else {
        // If the IRI is a fragment, render it as a prefixed IRI
        return PrefixedIri('', '#', relativized.substring(1));
      }
    }
    if (relativeUrl != null && relativeUrl.isEmpty) {
      // If we have a relative URL that is empty, we do not need to check
      // for better matching prefixes, but use the relative URL directly
      return RelativeIri(relativeUrl);
    }
    final iri = term.value;
    final prefixAllowed = allowedTypes.contains(IriCompactionType.prefixed);
    final fullAllowed = allowedTypes.contains(IriCompactionType.full);
    if (prefixAllowed && iriToPrefixMap.containsKey(iri)) {
      final prefix = iriToPrefixMap[iri]!;
      return PrefixedIri(prefix, iri, null);
    }

    if (relativeUrl != null) {
      // Special case: if we have a relative URL, check the custom prefixes
      // to see if any of them lead to a shorter local part than the relative URL
      if (prefixAllowed && customPrefixes.isNotEmpty) {
        // Build inverted customPrefixes (namespace→prefix) for O(separators) lookup.
        // customPrefixes is typically small (user-supplied), so this M+N is negligible.
        final invertedCustom = {
          for (final e in customPrefixes.entries) e.value: e.key
        };
        if (_bestMatch(iri, invertedCustom)
            case (String bestPrefix, String bestMatch)) {
          final localPart = _extractLocalPart(iri, bestMatch);
          if (localPart.length < relativeUrl.length &&
              _isValidIriLocalPart(localPart)) {
            // If the  local part of the best match is shorter than the relative one, use it instead
            return PrefixedIri(bestPrefix, bestMatch, localPart);
          }
        }
      }
      // Usually we want to use the relative URL if we have one
      return RelativeIri(relativeUrl);
    }

    // For prefix match, use the longest matching prefix (most specific).
    // [iriToPrefixMap] is already inverted (namespace→prefix), so _bestMatch
    // can do an O(separators_in_iri) walk instead of an O(P) linear scan.
    if (prefixAllowed) {
      if (_bestMatch(iri, iriToPrefixMap)
          case (String bestPrefix, String bestMatch)) {
        // If we have a prefix match, use it
        final localPart = _extractLocalPart(iri, bestMatch);
        if (_isValidIriLocalPart(localPart)) {
          return PrefixedIri(bestPrefix, bestMatch, localPart);
        }
      }
    }

    if (prefixAllowed && _settings.generateMissingPrefixes) {
      // No existing prefix found, generate a new one using namespace mappings

      // Extract namespace from IRI
      final (
        namespace,
        localPart,
      ) = RdfNamespaceMappings.extractNamespaceAndLocalPart(
        iri,
      );
      if (fullAllowed &&
          (localPart.isEmpty || !_isValidIriLocalPart(localPart))) {
        // If we have no local part, we cannot generate a prefix
        return FullIri(iri);
      }
      // Warn if https:// is used and http:// is in the prefix map for the same path (or the other way around)
      _warnSchemaNamespaceMismatch(
          iri, namespace, prefixCandidates, "http://", "https://");
      _warnSchemaNamespaceMismatch(
          iri, namespace, prefixCandidates, "https://", "http://");

      // Skip generating prefixes for protocol-only URIs like "http://" or "https://"
      if (fullAllowed &&
          (namespace == "http://" ||
              namespace == "https://" ||
              namespace == "ftp://" ||
              namespace == "file://")) {
        // If it's just a protocol URI, don't add a prefix
        return FullIri(iri);
      }

      // Skip generating prefixes for namespaces that don't end with "/" or "#"
      // since these are not proper namespace delimiters in RDF
      if (fullAllowed &&
          (!namespace.endsWith('/') && !namespace.endsWith('#'))) {
        // For IRIs without proper namespace delimiters, don't add a prefix
        return FullIri(iri);
      }

      // Get or generate a prefix for this namespace. Pass iriToPrefixMap as the
      // inverted index so getOrGeneratePrefix can do an O(1) namespace→prefix
      // lookup instead of an O(P) _getKeyByValue scan over prefixCandidates.
      // Get or generate a prefix for this namespace. Pass iriToPrefixMap as the
      // inverted index so getOrGeneratePrefix can do an O(1) namespace→prefix
      // lookup instead of an O(P) _getKeyByValue scan over prefixCandidates.
      // prefixCounters allows O(1) amortized numbered-suffix search.
      final (prefix, _) = _namespaceMappings.getOrGeneratePrefix(
        namespace,
        customMappings: prefixCandidates,
        invertedCustomMappings: iriToPrefixMap,
        prefixCounters: prefixCounters,
      );
      return PrefixedIri(prefix, namespace, localPart);
    }
    if (!fullAllowed) {
      throw ArgumentError(
        'Cannot compact IRI "$iri" with role $role: '
        'no allowed compaction types for this role.',
      );
    }
    return FullIri(iri);
  }

  void _warnSchemaNamespaceMismatch(
      String iri,
      String namespace,
      Map<String, String> prefixCandidates,
      String actualSchema,
      String preferredSchema) {
    if (namespace.startsWith(actualSchema)) {
      final preferredNamespace =
          preferredSchema + namespace.substring(actualSchema.length);
      if (prefixCandidates.containsValue(preferredNamespace)) {
        _log.warning(
          'Namespace mismatch: Found IRI $iri, but canonical prefix uses $preferredNamespace. Consider using the canonical $preferredSchema form instead of $actualSchema.',
        );
      }
    }
  }

  String _extractLocalPart(String iri, String bestMatch) =>
      iri.substring(bestMatch.length);

  /// Finds the longest namespace prefix for [iri] in [namespaceToPrefix]
  /// (a map from namespace URI to prefix name).
  ///
  /// Walks [iri] backward through `#` and `/` separator positions so the
  /// longest candidate namespace is checked first, returning immediately on
  /// the first hit.  This is O(separator_count_in_iri) — typically ≤ 10 —
  /// vs the previous O(P) linear scan over all prefix candidates where P
  /// can be thousands in large datasets.
  (String prefix, String namespace)? _bestMatch(
      String iri, Map<String, String> namespaceToPrefix) {
    if (namespaceToPrefix.isEmpty) return null;
    // '#'-delimited namespaces: walk right-to-left (longest first).
    var idx = iri.lastIndexOf('#');
    while (idx > 0) {
      final ns = iri.substring(0, idx + 1);
      final prefix = namespaceToPrefix[ns];
      if (prefix != null) return (prefix, ns);
      idx = iri.lastIndexOf('#', idx - 1);
    }
    // '/'-delimited namespaces: walk right-to-left (longest first).
    idx = iri.lastIndexOf('/');
    while (idx > 0) {
      final ns = iri.substring(0, idx + 1);
      final prefix = namespaceToPrefix[ns];
      if (prefix != null) return (prefix, ns);
      idx = iri.lastIndexOf('/', idx - 1);
    }
    return null;
  }
}
