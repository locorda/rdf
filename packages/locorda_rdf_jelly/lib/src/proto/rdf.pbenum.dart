// This is a generated file - do not edit.
//
// Generated from rdf.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

/// Physical stream type
/// This determines how the data is encoded in the stream, not the logical
/// structure of the data. See LogicalStreamType for the latter.
class PhysicalStreamType extends $pb.ProtobufEnum {
  /// Unspecified stream type – invalid
  static const PhysicalStreamType PHYSICAL_STREAM_TYPE_UNSPECIFIED =
      PhysicalStreamType._(
          0, _omitEnumNames ? '' : 'PHYSICAL_STREAM_TYPE_UNSPECIFIED');

  /// RDF triples
  static const PhysicalStreamType PHYSICAL_STREAM_TYPE_TRIPLES =
      PhysicalStreamType._(
          1, _omitEnumNames ? '' : 'PHYSICAL_STREAM_TYPE_TRIPLES');

  /// RDF quads
  static const PhysicalStreamType PHYSICAL_STREAM_TYPE_QUADS =
      PhysicalStreamType._(
          2, _omitEnumNames ? '' : 'PHYSICAL_STREAM_TYPE_QUADS');

  /// RDF triples grouped in graphs
  static const PhysicalStreamType PHYSICAL_STREAM_TYPE_GRAPHS =
      PhysicalStreamType._(
          3, _omitEnumNames ? '' : 'PHYSICAL_STREAM_TYPE_GRAPHS');

  static const $core.List<PhysicalStreamType> values = <PhysicalStreamType>[
    PHYSICAL_STREAM_TYPE_UNSPECIFIED,
    PHYSICAL_STREAM_TYPE_TRIPLES,
    PHYSICAL_STREAM_TYPE_QUADS,
    PHYSICAL_STREAM_TYPE_GRAPHS,
  ];

  static final $core.List<PhysicalStreamType?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static PhysicalStreamType? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const PhysicalStreamType._(super.value, super.name);
}

/// Logical stream type, according to the RDF Stream Taxonomy (RDF-STaX).
/// Type 0 is reserved for the unspecified stream type.
/// The rest of the type numbers follow the taxonomical structure of RDF-STaX.
/// For example: 1 is a subtype of 0, 13 and 23 are subtypes of 3,
/// 114 is a subtype of 14, etc.
///
/// Types 1–4 correspond to the four base concrete stream types. Their
/// subtypes can be in most cases simply processed in the same way as
/// the base types.
/// Therefore, implementations can take the modulo 10 of the stream
/// type to determine the base type of the stream and use this information
/// to select the appropriate processing logic.
///
/// RDF-STaX version: 1.1.2
/// https://w3id.org/stax/1.1.2
///
/// ^ The above URL is used to automatically determine the version of RDF-STaX
/// in the Jelly protocol specification. Please keep it up-to-date and in the
/// same format.
class LogicalStreamType extends $pb.ProtobufEnum {
  /// Unspecified stream type – invalid
  static const LogicalStreamType LOGICAL_STREAM_TYPE_UNSPECIFIED =
      LogicalStreamType._(
          0, _omitEnumNames ? '' : 'LOGICAL_STREAM_TYPE_UNSPECIFIED');

  /// Flat RDF triple stream
  /// https://w3id.org/stax/ontology#flatTripleStream
  static const LogicalStreamType LOGICAL_STREAM_TYPE_FLAT_TRIPLES =
      LogicalStreamType._(
          1, _omitEnumNames ? '' : 'LOGICAL_STREAM_TYPE_FLAT_TRIPLES');

  /// Flat RDF quad stream
  /// https://w3id.org/stax/ontology#flatQuadStream
  static const LogicalStreamType LOGICAL_STREAM_TYPE_FLAT_QUADS =
      LogicalStreamType._(
          2, _omitEnumNames ? '' : 'LOGICAL_STREAM_TYPE_FLAT_QUADS');

  /// RDF graph stream
  /// https://w3id.org/stax/ontology#graphStream
  static const LogicalStreamType LOGICAL_STREAM_TYPE_GRAPHS =
      LogicalStreamType._(
          3, _omitEnumNames ? '' : 'LOGICAL_STREAM_TYPE_GRAPHS');

  /// RDF dataset stream
  /// https://w3id.org/stax/ontology#datasetStream
  static const LogicalStreamType LOGICAL_STREAM_TYPE_DATASETS =
      LogicalStreamType._(
          4, _omitEnumNames ? '' : 'LOGICAL_STREAM_TYPE_DATASETS');

  /// RDF subject graph stream (subtype of RDF graph stream)
  /// https://w3id.org/stax/ontology#subjectGraphStream
  static const LogicalStreamType LOGICAL_STREAM_TYPE_SUBJECT_GRAPHS =
      LogicalStreamType._(
          13, _omitEnumNames ? '' : 'LOGICAL_STREAM_TYPE_SUBJECT_GRAPHS');

  /// RDF named graph stream (subtype of RDF dataset stream)
  /// https://w3id.org/stax/ontology#namedGraphStream
  static const LogicalStreamType LOGICAL_STREAM_TYPE_NAMED_GRAPHS =
      LogicalStreamType._(
          14, _omitEnumNames ? '' : 'LOGICAL_STREAM_TYPE_NAMED_GRAPHS');

  /// RDF timestamped named graph stream (subtype of RDF dataset stream)
  /// https://w3id.org/stax/ontology#timestampedNamedGraphStream
  static const LogicalStreamType LOGICAL_STREAM_TYPE_TIMESTAMPED_NAMED_GRAPHS =
      LogicalStreamType._(114,
          _omitEnumNames ? '' : 'LOGICAL_STREAM_TYPE_TIMESTAMPED_NAMED_GRAPHS');

  static const $core.List<LogicalStreamType> values = <LogicalStreamType>[
    LOGICAL_STREAM_TYPE_UNSPECIFIED,
    LOGICAL_STREAM_TYPE_FLAT_TRIPLES,
    LOGICAL_STREAM_TYPE_FLAT_QUADS,
    LOGICAL_STREAM_TYPE_GRAPHS,
    LOGICAL_STREAM_TYPE_DATASETS,
    LOGICAL_STREAM_TYPE_SUBJECT_GRAPHS,
    LOGICAL_STREAM_TYPE_NAMED_GRAPHS,
    LOGICAL_STREAM_TYPE_TIMESTAMPED_NAMED_GRAPHS,
  ];

  static final $core.Map<$core.int, LogicalStreamType> _byValue =
      $pb.ProtobufEnum.initByValue(values);
  static LogicalStreamType? valueOf($core.int value) => _byValue[value];

  const LogicalStreamType._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
