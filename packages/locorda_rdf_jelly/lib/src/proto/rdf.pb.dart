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

import 'rdf.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'rdf.pbenum.dart';

/// RDF IRIs
/// The IRIs are reconstructed by the consumer using the prefix and name
/// lookup tables.
class RdfIri extends $pb.GeneratedMessage {
  factory RdfIri({
    $core.int? prefixId,
    $core.int? nameId,
  }) {
    final result = create();
    if (prefixId != null) result.prefixId = prefixId;
    if (nameId != null) result.nameId = nameId;
    return result;
  }

  RdfIri._();

  factory RdfIri.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RdfIri.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RdfIri',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'eu.ostrzyciel.jelly.core.proto.v1'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'prefixId', fieldType: $pb.PbFieldType.OU3)
    ..aI(2, _omitFieldNames ? '' : 'nameId', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RdfIri clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RdfIri copyWith(void Function(RdfIri) updates) =>
      super.copyWith((message) => updates(message as RdfIri)) as RdfIri;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RdfIri create() => RdfIri._();
  @$core.override
  RdfIri createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RdfIri getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RdfIri>(create);
  static RdfIri? _defaultInstance;

  /// 1-based, refers to an entry in the prefix lookup.
  ///
  /// 0 signifies "use the same prefix_id as in the previous IRI".
  /// For this to work, IRIs must be processed strictly in order: firstly by
  /// stream row, then by term (subject, predicate, object, graph). This also
  /// applies recursively to RDF-star quoted triples.
  ///
  /// If 0 appears in the first IRI of the stream (and in any subsequent IRI),
  /// this should be interpreted as an empty ("") prefix. This is for example
  /// used when the prefix lookup table is disabled.
  @$pb.TagNumber(1)
  $core.int get prefixId => $_getIZ(0);
  @$pb.TagNumber(1)
  set prefixId($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPrefixId() => $_has(0);
  @$pb.TagNumber(1)
  void clearPrefixId() => $_clearField(1);

  /// 1-based, refers to an entry in the name lookup.
  ///
  /// 0 signifies "use the previous name_id + 1". This requires the same order
  /// guarantees as prefixes.
  ///
  /// If 0 appears in the first IRI of the stream, it should be interpreted as
  /// name_id = 1.
  @$pb.TagNumber(2)
  $core.int get nameId => $_getIZ(1);
  @$pb.TagNumber(2)
  set nameId($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasNameId() => $_has(1);
  @$pb.TagNumber(2)
  void clearNameId() => $_clearField(2);
}

enum RdfLiteral_LiteralKind { langtag, datatype, notSet }

/// RDF literals
class RdfLiteral extends $pb.GeneratedMessage {
  factory RdfLiteral({
    $core.String? lex,
    $core.String? langtag,
    $core.int? datatype,
  }) {
    final result = create();
    if (lex != null) result.lex = lex;
    if (langtag != null) result.langtag = langtag;
    if (datatype != null) result.datatype = datatype;
    return result;
  }

  RdfLiteral._();

  factory RdfLiteral.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RdfLiteral.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, RdfLiteral_LiteralKind>
      _RdfLiteral_LiteralKindByTag = {
    2: RdfLiteral_LiteralKind.langtag,
    3: RdfLiteral_LiteralKind.datatype,
    0: RdfLiteral_LiteralKind.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RdfLiteral',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'eu.ostrzyciel.jelly.core.proto.v1'),
      createEmptyInstance: create)
    ..oo(0, [2, 3])
    ..aOS(1, _omitFieldNames ? '' : 'lex')
    ..aOS(2, _omitFieldNames ? '' : 'langtag')
    ..aI(3, _omitFieldNames ? '' : 'datatype', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RdfLiteral clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RdfLiteral copyWith(void Function(RdfLiteral) updates) =>
      super.copyWith((message) => updates(message as RdfLiteral)) as RdfLiteral;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RdfLiteral create() => RdfLiteral._();
  @$core.override
  RdfLiteral createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RdfLiteral getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RdfLiteral>(create);
  static RdfLiteral? _defaultInstance;

  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  RdfLiteral_LiteralKind whichLiteralKind() =>
      _RdfLiteral_LiteralKindByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  void clearLiteralKind() => $_clearField($_whichOneof(0));

  /// The lexical form of the literal (required).
  @$pb.TagNumber(1)
  $core.String get lex => $_getSZ(0);
  @$pb.TagNumber(1)
  set lex($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasLex() => $_has(0);
  @$pb.TagNumber(1)
  void clearLex() => $_clearField(1);

  /// Language-tagged string.
  @$pb.TagNumber(2)
  $core.String get langtag => $_getSZ(1);
  @$pb.TagNumber(2)
  set langtag($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasLangtag() => $_has(1);
  @$pb.TagNumber(2)
  void clearLangtag() => $_clearField(2);

  /// Typed literal. The datatype is a reference to an entry in the
  /// datatype lookup. This value is 1-based and the value of 0
  /// is invalid (in contrast to prefix_id and name_id in RdfIri).
  @$pb.TagNumber(3)
  $core.int get datatype => $_getIZ(2);
  @$pb.TagNumber(3)
  set datatype($core.int value) => $_setUnsignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDatatype() => $_has(2);
  @$pb.TagNumber(3)
  void clearDatatype() => $_clearField(3);
}

/// Empty message indicating the default RDF graph.
class RdfDefaultGraph extends $pb.GeneratedMessage {
  factory RdfDefaultGraph() => create();

  RdfDefaultGraph._();

  factory RdfDefaultGraph.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RdfDefaultGraph.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RdfDefaultGraph',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'eu.ostrzyciel.jelly.core.proto.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RdfDefaultGraph clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RdfDefaultGraph copyWith(void Function(RdfDefaultGraph) updates) =>
      super.copyWith((message) => updates(message as RdfDefaultGraph))
          as RdfDefaultGraph;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RdfDefaultGraph create() => RdfDefaultGraph._();
  @$core.override
  RdfDefaultGraph createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RdfDefaultGraph getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RdfDefaultGraph>(create);
  static RdfDefaultGraph? _defaultInstance;
}

enum RdfTriple_Subject { sIri, sBnode, sLiteral, sTripleTerm, notSet }

enum RdfTriple_Predicate { pIri, pBnode, pLiteral, pTripleTerm, notSet }

enum RdfTriple_Object { oIri, oBnode, oLiteral, oTripleTerm, notSet }

/// RDF triple
///
/// For each term (subject, predicate, object), the fields are repeated for
/// performance reasons. This is to avoid the need for boxing each term in a
/// separate message.
///
/// Note: this message allows for representing generalized RDF triples (for
/// example, with literals as predicates). Whether this is used in the stream
/// is determined by the stream options (see RdfStreamOptions).
///
/// If no field in a given oneof is set, the term is interpreted as a repeated
/// term – the same as the term in the same position in the previous triple.
/// In the first triple of the stream, all terms must be set.
/// All terms must also be set in quoted triples (RDF-star).
class RdfTriple extends $pb.GeneratedMessage {
  factory RdfTriple({
    RdfIri? sIri,
    $core.String? sBnode,
    RdfLiteral? sLiteral,
    RdfTriple? sTripleTerm,
    RdfIri? pIri,
    $core.String? pBnode,
    RdfLiteral? pLiteral,
    RdfTriple? pTripleTerm,
    RdfIri? oIri,
    $core.String? oBnode,
    RdfLiteral? oLiteral,
    RdfTriple? oTripleTerm,
  }) {
    final result = create();
    if (sIri != null) result.sIri = sIri;
    if (sBnode != null) result.sBnode = sBnode;
    if (sLiteral != null) result.sLiteral = sLiteral;
    if (sTripleTerm != null) result.sTripleTerm = sTripleTerm;
    if (pIri != null) result.pIri = pIri;
    if (pBnode != null) result.pBnode = pBnode;
    if (pLiteral != null) result.pLiteral = pLiteral;
    if (pTripleTerm != null) result.pTripleTerm = pTripleTerm;
    if (oIri != null) result.oIri = oIri;
    if (oBnode != null) result.oBnode = oBnode;
    if (oLiteral != null) result.oLiteral = oLiteral;
    if (oTripleTerm != null) result.oTripleTerm = oTripleTerm;
    return result;
  }

  RdfTriple._();

  factory RdfTriple.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RdfTriple.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, RdfTriple_Subject> _RdfTriple_SubjectByTag =
      {
    1: RdfTriple_Subject.sIri,
    2: RdfTriple_Subject.sBnode,
    3: RdfTriple_Subject.sLiteral,
    4: RdfTriple_Subject.sTripleTerm,
    0: RdfTriple_Subject.notSet
  };
  static const $core.Map<$core.int, RdfTriple_Predicate>
      _RdfTriple_PredicateByTag = {
    5: RdfTriple_Predicate.pIri,
    6: RdfTriple_Predicate.pBnode,
    7: RdfTriple_Predicate.pLiteral,
    8: RdfTriple_Predicate.pTripleTerm,
    0: RdfTriple_Predicate.notSet
  };
  static const $core.Map<$core.int, RdfTriple_Object> _RdfTriple_ObjectByTag = {
    9: RdfTriple_Object.oIri,
    10: RdfTriple_Object.oBnode,
    11: RdfTriple_Object.oLiteral,
    12: RdfTriple_Object.oTripleTerm,
    0: RdfTriple_Object.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RdfTriple',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'eu.ostrzyciel.jelly.core.proto.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2, 3, 4])
    ..oo(1, [5, 6, 7, 8])
    ..oo(2, [9, 10, 11, 12])
    ..aOM<RdfIri>(1, _omitFieldNames ? '' : 'sIri', subBuilder: RdfIri.create)
    ..aOS(2, _omitFieldNames ? '' : 'sBnode')
    ..aOM<RdfLiteral>(3, _omitFieldNames ? '' : 'sLiteral',
        subBuilder: RdfLiteral.create)
    ..aOM<RdfTriple>(4, _omitFieldNames ? '' : 'sTripleTerm',
        subBuilder: RdfTriple.create)
    ..aOM<RdfIri>(5, _omitFieldNames ? '' : 'pIri', subBuilder: RdfIri.create)
    ..aOS(6, _omitFieldNames ? '' : 'pBnode')
    ..aOM<RdfLiteral>(7, _omitFieldNames ? '' : 'pLiteral',
        subBuilder: RdfLiteral.create)
    ..aOM<RdfTriple>(8, _omitFieldNames ? '' : 'pTripleTerm',
        subBuilder: RdfTriple.create)
    ..aOM<RdfIri>(9, _omitFieldNames ? '' : 'oIri', subBuilder: RdfIri.create)
    ..aOS(10, _omitFieldNames ? '' : 'oBnode')
    ..aOM<RdfLiteral>(11, _omitFieldNames ? '' : 'oLiteral',
        subBuilder: RdfLiteral.create)
    ..aOM<RdfTriple>(12, _omitFieldNames ? '' : 'oTripleTerm',
        subBuilder: RdfTriple.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RdfTriple clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RdfTriple copyWith(void Function(RdfTriple) updates) =>
      super.copyWith((message) => updates(message as RdfTriple)) as RdfTriple;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RdfTriple create() => RdfTriple._();
  @$core.override
  RdfTriple createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RdfTriple getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RdfTriple>(create);
  static RdfTriple? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  @$pb.TagNumber(4)
  RdfTriple_Subject whichSubject() => _RdfTriple_SubjectByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  @$pb.TagNumber(4)
  void clearSubject() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(5)
  @$pb.TagNumber(6)
  @$pb.TagNumber(7)
  @$pb.TagNumber(8)
  RdfTriple_Predicate whichPredicate() =>
      _RdfTriple_PredicateByTag[$_whichOneof(1)]!;
  @$pb.TagNumber(5)
  @$pb.TagNumber(6)
  @$pb.TagNumber(7)
  @$pb.TagNumber(8)
  void clearPredicate() => $_clearField($_whichOneof(1));

  @$pb.TagNumber(9)
  @$pb.TagNumber(10)
  @$pb.TagNumber(11)
  @$pb.TagNumber(12)
  RdfTriple_Object whichObject() => _RdfTriple_ObjectByTag[$_whichOneof(2)]!;
  @$pb.TagNumber(9)
  @$pb.TagNumber(10)
  @$pb.TagNumber(11)
  @$pb.TagNumber(12)
  void clearObject() => $_clearField($_whichOneof(2));

  /// IRI
  @$pb.TagNumber(1)
  RdfIri get sIri => $_getN(0);
  @$pb.TagNumber(1)
  set sIri(RdfIri value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasSIri() => $_has(0);
  @$pb.TagNumber(1)
  void clearSIri() => $_clearField(1);
  @$pb.TagNumber(1)
  RdfIri ensureSIri() => $_ensure(0);

  /// Blank node
  @$pb.TagNumber(2)
  $core.String get sBnode => $_getSZ(1);
  @$pb.TagNumber(2)
  set sBnode($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSBnode() => $_has(1);
  @$pb.TagNumber(2)
  void clearSBnode() => $_clearField(2);

  /// Literal
  /// Only valid in a generalized RDF stream.
  @$pb.TagNumber(3)
  RdfLiteral get sLiteral => $_getN(2);
  @$pb.TagNumber(3)
  set sLiteral(RdfLiteral value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasSLiteral() => $_has(2);
  @$pb.TagNumber(3)
  void clearSLiteral() => $_clearField(3);
  @$pb.TagNumber(3)
  RdfLiteral ensureSLiteral() => $_ensure(2);

  /// RDF-star quoted triple
  @$pb.TagNumber(4)
  RdfTriple get sTripleTerm => $_getN(3);
  @$pb.TagNumber(4)
  set sTripleTerm(RdfTriple value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasSTripleTerm() => $_has(3);
  @$pb.TagNumber(4)
  void clearSTripleTerm() => $_clearField(4);
  @$pb.TagNumber(4)
  RdfTriple ensureSTripleTerm() => $_ensure(3);

  /// IRI
  @$pb.TagNumber(5)
  RdfIri get pIri => $_getN(4);
  @$pb.TagNumber(5)
  set pIri(RdfIri value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasPIri() => $_has(4);
  @$pb.TagNumber(5)
  void clearPIri() => $_clearField(5);
  @$pb.TagNumber(5)
  RdfIri ensurePIri() => $_ensure(4);

  /// Blank node
  /// Only valid in a generalized RDF stream.
  @$pb.TagNumber(6)
  $core.String get pBnode => $_getSZ(5);
  @$pb.TagNumber(6)
  set pBnode($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasPBnode() => $_has(5);
  @$pb.TagNumber(6)
  void clearPBnode() => $_clearField(6);

  /// Literal
  /// Only valid in a generalized RDF stream.
  @$pb.TagNumber(7)
  RdfLiteral get pLiteral => $_getN(6);
  @$pb.TagNumber(7)
  set pLiteral(RdfLiteral value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasPLiteral() => $_has(6);
  @$pb.TagNumber(7)
  void clearPLiteral() => $_clearField(7);
  @$pb.TagNumber(7)
  RdfLiteral ensurePLiteral() => $_ensure(6);

  /// RDF-star quoted triple
  @$pb.TagNumber(8)
  RdfTriple get pTripleTerm => $_getN(7);
  @$pb.TagNumber(8)
  set pTripleTerm(RdfTriple value) => $_setField(8, value);
  @$pb.TagNumber(8)
  $core.bool hasPTripleTerm() => $_has(7);
  @$pb.TagNumber(8)
  void clearPTripleTerm() => $_clearField(8);
  @$pb.TagNumber(8)
  RdfTriple ensurePTripleTerm() => $_ensure(7);

  /// IRI
  @$pb.TagNumber(9)
  RdfIri get oIri => $_getN(8);
  @$pb.TagNumber(9)
  set oIri(RdfIri value) => $_setField(9, value);
  @$pb.TagNumber(9)
  $core.bool hasOIri() => $_has(8);
  @$pb.TagNumber(9)
  void clearOIri() => $_clearField(9);
  @$pb.TagNumber(9)
  RdfIri ensureOIri() => $_ensure(8);

  /// Blank node
  @$pb.TagNumber(10)
  $core.String get oBnode => $_getSZ(9);
  @$pb.TagNumber(10)
  set oBnode($core.String value) => $_setString(9, value);
  @$pb.TagNumber(10)
  $core.bool hasOBnode() => $_has(9);
  @$pb.TagNumber(10)
  void clearOBnode() => $_clearField(10);

  /// Literal
  @$pb.TagNumber(11)
  RdfLiteral get oLiteral => $_getN(10);
  @$pb.TagNumber(11)
  set oLiteral(RdfLiteral value) => $_setField(11, value);
  @$pb.TagNumber(11)
  $core.bool hasOLiteral() => $_has(10);
  @$pb.TagNumber(11)
  void clearOLiteral() => $_clearField(11);
  @$pb.TagNumber(11)
  RdfLiteral ensureOLiteral() => $_ensure(10);

  /// RDF-star quoted triple
  @$pb.TagNumber(12)
  RdfTriple get oTripleTerm => $_getN(11);
  @$pb.TagNumber(12)
  set oTripleTerm(RdfTriple value) => $_setField(12, value);
  @$pb.TagNumber(12)
  $core.bool hasOTripleTerm() => $_has(11);
  @$pb.TagNumber(12)
  void clearOTripleTerm() => $_clearField(12);
  @$pb.TagNumber(12)
  RdfTriple ensureOTripleTerm() => $_ensure(11);
}

enum RdfQuad_Subject { sIri, sBnode, sLiteral, sTripleTerm, notSet }

enum RdfQuad_Predicate { pIri, pBnode, pLiteral, pTripleTerm, notSet }

enum RdfQuad_Object { oIri, oBnode, oLiteral, oTripleTerm, notSet }

enum RdfQuad_Graph { gIri, gBnode, gDefaultGraph, gLiteral, notSet }

/// RDF quad
///
/// Fields 1–12 are repeated from RdfTriple for performance reasons.
///
/// Similarly to RdfTriple, this message allows for representing generalized
/// RDF quads (for example, with literals as predicates). Whether this is used
/// in the stream is determined by the stream options (see RdfStreamOptions).
///
/// If no field in a given oneof is set, the term is interpreted as a repeated
/// term – the same as the term in the same position in the previous quad.
/// In the first quad of the stream, all terms must be set.
class RdfQuad extends $pb.GeneratedMessage {
  factory RdfQuad({
    RdfIri? sIri,
    $core.String? sBnode,
    RdfLiteral? sLiteral,
    RdfTriple? sTripleTerm,
    RdfIri? pIri,
    $core.String? pBnode,
    RdfLiteral? pLiteral,
    RdfTriple? pTripleTerm,
    RdfIri? oIri,
    $core.String? oBnode,
    RdfLiteral? oLiteral,
    RdfTriple? oTripleTerm,
    RdfIri? gIri,
    $core.String? gBnode,
    RdfDefaultGraph? gDefaultGraph,
    RdfLiteral? gLiteral,
  }) {
    final result = create();
    if (sIri != null) result.sIri = sIri;
    if (sBnode != null) result.sBnode = sBnode;
    if (sLiteral != null) result.sLiteral = sLiteral;
    if (sTripleTerm != null) result.sTripleTerm = sTripleTerm;
    if (pIri != null) result.pIri = pIri;
    if (pBnode != null) result.pBnode = pBnode;
    if (pLiteral != null) result.pLiteral = pLiteral;
    if (pTripleTerm != null) result.pTripleTerm = pTripleTerm;
    if (oIri != null) result.oIri = oIri;
    if (oBnode != null) result.oBnode = oBnode;
    if (oLiteral != null) result.oLiteral = oLiteral;
    if (oTripleTerm != null) result.oTripleTerm = oTripleTerm;
    if (gIri != null) result.gIri = gIri;
    if (gBnode != null) result.gBnode = gBnode;
    if (gDefaultGraph != null) result.gDefaultGraph = gDefaultGraph;
    if (gLiteral != null) result.gLiteral = gLiteral;
    return result;
  }

  RdfQuad._();

  factory RdfQuad.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RdfQuad.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, RdfQuad_Subject> _RdfQuad_SubjectByTag = {
    1: RdfQuad_Subject.sIri,
    2: RdfQuad_Subject.sBnode,
    3: RdfQuad_Subject.sLiteral,
    4: RdfQuad_Subject.sTripleTerm,
    0: RdfQuad_Subject.notSet
  };
  static const $core.Map<$core.int, RdfQuad_Predicate> _RdfQuad_PredicateByTag =
      {
    5: RdfQuad_Predicate.pIri,
    6: RdfQuad_Predicate.pBnode,
    7: RdfQuad_Predicate.pLiteral,
    8: RdfQuad_Predicate.pTripleTerm,
    0: RdfQuad_Predicate.notSet
  };
  static const $core.Map<$core.int, RdfQuad_Object> _RdfQuad_ObjectByTag = {
    9: RdfQuad_Object.oIri,
    10: RdfQuad_Object.oBnode,
    11: RdfQuad_Object.oLiteral,
    12: RdfQuad_Object.oTripleTerm,
    0: RdfQuad_Object.notSet
  };
  static const $core.Map<$core.int, RdfQuad_Graph> _RdfQuad_GraphByTag = {
    13: RdfQuad_Graph.gIri,
    14: RdfQuad_Graph.gBnode,
    15: RdfQuad_Graph.gDefaultGraph,
    16: RdfQuad_Graph.gLiteral,
    0: RdfQuad_Graph.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RdfQuad',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'eu.ostrzyciel.jelly.core.proto.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2, 3, 4])
    ..oo(1, [5, 6, 7, 8])
    ..oo(2, [9, 10, 11, 12])
    ..oo(3, [13, 14, 15, 16])
    ..aOM<RdfIri>(1, _omitFieldNames ? '' : 'sIri', subBuilder: RdfIri.create)
    ..aOS(2, _omitFieldNames ? '' : 'sBnode')
    ..aOM<RdfLiteral>(3, _omitFieldNames ? '' : 'sLiteral',
        subBuilder: RdfLiteral.create)
    ..aOM<RdfTriple>(4, _omitFieldNames ? '' : 'sTripleTerm',
        subBuilder: RdfTriple.create)
    ..aOM<RdfIri>(5, _omitFieldNames ? '' : 'pIri', subBuilder: RdfIri.create)
    ..aOS(6, _omitFieldNames ? '' : 'pBnode')
    ..aOM<RdfLiteral>(7, _omitFieldNames ? '' : 'pLiteral',
        subBuilder: RdfLiteral.create)
    ..aOM<RdfTriple>(8, _omitFieldNames ? '' : 'pTripleTerm',
        subBuilder: RdfTriple.create)
    ..aOM<RdfIri>(9, _omitFieldNames ? '' : 'oIri', subBuilder: RdfIri.create)
    ..aOS(10, _omitFieldNames ? '' : 'oBnode')
    ..aOM<RdfLiteral>(11, _omitFieldNames ? '' : 'oLiteral',
        subBuilder: RdfLiteral.create)
    ..aOM<RdfTriple>(12, _omitFieldNames ? '' : 'oTripleTerm',
        subBuilder: RdfTriple.create)
    ..aOM<RdfIri>(13, _omitFieldNames ? '' : 'gIri', subBuilder: RdfIri.create)
    ..aOS(14, _omitFieldNames ? '' : 'gBnode')
    ..aOM<RdfDefaultGraph>(15, _omitFieldNames ? '' : 'gDefaultGraph',
        subBuilder: RdfDefaultGraph.create)
    ..aOM<RdfLiteral>(16, _omitFieldNames ? '' : 'gLiteral',
        subBuilder: RdfLiteral.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RdfQuad clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RdfQuad copyWith(void Function(RdfQuad) updates) =>
      super.copyWith((message) => updates(message as RdfQuad)) as RdfQuad;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RdfQuad create() => RdfQuad._();
  @$core.override
  RdfQuad createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RdfQuad getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RdfQuad>(create);
  static RdfQuad? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  @$pb.TagNumber(4)
  RdfQuad_Subject whichSubject() => _RdfQuad_SubjectByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  @$pb.TagNumber(4)
  void clearSubject() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(5)
  @$pb.TagNumber(6)
  @$pb.TagNumber(7)
  @$pb.TagNumber(8)
  RdfQuad_Predicate whichPredicate() =>
      _RdfQuad_PredicateByTag[$_whichOneof(1)]!;
  @$pb.TagNumber(5)
  @$pb.TagNumber(6)
  @$pb.TagNumber(7)
  @$pb.TagNumber(8)
  void clearPredicate() => $_clearField($_whichOneof(1));

  @$pb.TagNumber(9)
  @$pb.TagNumber(10)
  @$pb.TagNumber(11)
  @$pb.TagNumber(12)
  RdfQuad_Object whichObject() => _RdfQuad_ObjectByTag[$_whichOneof(2)]!;
  @$pb.TagNumber(9)
  @$pb.TagNumber(10)
  @$pb.TagNumber(11)
  @$pb.TagNumber(12)
  void clearObject() => $_clearField($_whichOneof(2));

  @$pb.TagNumber(13)
  @$pb.TagNumber(14)
  @$pb.TagNumber(15)
  @$pb.TagNumber(16)
  RdfQuad_Graph whichGraph() => _RdfQuad_GraphByTag[$_whichOneof(3)]!;
  @$pb.TagNumber(13)
  @$pb.TagNumber(14)
  @$pb.TagNumber(15)
  @$pb.TagNumber(16)
  void clearGraph() => $_clearField($_whichOneof(3));

  /// IRI
  @$pb.TagNumber(1)
  RdfIri get sIri => $_getN(0);
  @$pb.TagNumber(1)
  set sIri(RdfIri value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasSIri() => $_has(0);
  @$pb.TagNumber(1)
  void clearSIri() => $_clearField(1);
  @$pb.TagNumber(1)
  RdfIri ensureSIri() => $_ensure(0);

  /// Blank node
  @$pb.TagNumber(2)
  $core.String get sBnode => $_getSZ(1);
  @$pb.TagNumber(2)
  set sBnode($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSBnode() => $_has(1);
  @$pb.TagNumber(2)
  void clearSBnode() => $_clearField(2);

  /// Literal
  /// Only valid in a generalized RDF stream.
  @$pb.TagNumber(3)
  RdfLiteral get sLiteral => $_getN(2);
  @$pb.TagNumber(3)
  set sLiteral(RdfLiteral value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasSLiteral() => $_has(2);
  @$pb.TagNumber(3)
  void clearSLiteral() => $_clearField(3);
  @$pb.TagNumber(3)
  RdfLiteral ensureSLiteral() => $_ensure(2);

  /// RDF-star quoted triple
  @$pb.TagNumber(4)
  RdfTriple get sTripleTerm => $_getN(3);
  @$pb.TagNumber(4)
  set sTripleTerm(RdfTriple value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasSTripleTerm() => $_has(3);
  @$pb.TagNumber(4)
  void clearSTripleTerm() => $_clearField(4);
  @$pb.TagNumber(4)
  RdfTriple ensureSTripleTerm() => $_ensure(3);

  /// IRI
  @$pb.TagNumber(5)
  RdfIri get pIri => $_getN(4);
  @$pb.TagNumber(5)
  set pIri(RdfIri value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasPIri() => $_has(4);
  @$pb.TagNumber(5)
  void clearPIri() => $_clearField(5);
  @$pb.TagNumber(5)
  RdfIri ensurePIri() => $_ensure(4);

  /// Blank node
  /// Only valid in a generalized RDF stream.
  @$pb.TagNumber(6)
  $core.String get pBnode => $_getSZ(5);
  @$pb.TagNumber(6)
  set pBnode($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasPBnode() => $_has(5);
  @$pb.TagNumber(6)
  void clearPBnode() => $_clearField(6);

  /// Literal
  /// Only valid in a generalized RDF stream.
  @$pb.TagNumber(7)
  RdfLiteral get pLiteral => $_getN(6);
  @$pb.TagNumber(7)
  set pLiteral(RdfLiteral value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasPLiteral() => $_has(6);
  @$pb.TagNumber(7)
  void clearPLiteral() => $_clearField(7);
  @$pb.TagNumber(7)
  RdfLiteral ensurePLiteral() => $_ensure(6);

  /// RDF-star quoted triple
  @$pb.TagNumber(8)
  RdfTriple get pTripleTerm => $_getN(7);
  @$pb.TagNumber(8)
  set pTripleTerm(RdfTriple value) => $_setField(8, value);
  @$pb.TagNumber(8)
  $core.bool hasPTripleTerm() => $_has(7);
  @$pb.TagNumber(8)
  void clearPTripleTerm() => $_clearField(8);
  @$pb.TagNumber(8)
  RdfTriple ensurePTripleTerm() => $_ensure(7);

  /// IRI
  @$pb.TagNumber(9)
  RdfIri get oIri => $_getN(8);
  @$pb.TagNumber(9)
  set oIri(RdfIri value) => $_setField(9, value);
  @$pb.TagNumber(9)
  $core.bool hasOIri() => $_has(8);
  @$pb.TagNumber(9)
  void clearOIri() => $_clearField(9);
  @$pb.TagNumber(9)
  RdfIri ensureOIri() => $_ensure(8);

  /// Blank node
  @$pb.TagNumber(10)
  $core.String get oBnode => $_getSZ(9);
  @$pb.TagNumber(10)
  set oBnode($core.String value) => $_setString(9, value);
  @$pb.TagNumber(10)
  $core.bool hasOBnode() => $_has(9);
  @$pb.TagNumber(10)
  void clearOBnode() => $_clearField(10);

  /// Literal
  @$pb.TagNumber(11)
  RdfLiteral get oLiteral => $_getN(10);
  @$pb.TagNumber(11)
  set oLiteral(RdfLiteral value) => $_setField(11, value);
  @$pb.TagNumber(11)
  $core.bool hasOLiteral() => $_has(10);
  @$pb.TagNumber(11)
  void clearOLiteral() => $_clearField(11);
  @$pb.TagNumber(11)
  RdfLiteral ensureOLiteral() => $_ensure(10);

  /// RDF-star quoted triple
  @$pb.TagNumber(12)
  RdfTriple get oTripleTerm => $_getN(11);
  @$pb.TagNumber(12)
  set oTripleTerm(RdfTriple value) => $_setField(12, value);
  @$pb.TagNumber(12)
  $core.bool hasOTripleTerm() => $_has(11);
  @$pb.TagNumber(12)
  void clearOTripleTerm() => $_clearField(12);
  @$pb.TagNumber(12)
  RdfTriple ensureOTripleTerm() => $_ensure(11);

  /// IRI
  @$pb.TagNumber(13)
  RdfIri get gIri => $_getN(12);
  @$pb.TagNumber(13)
  set gIri(RdfIri value) => $_setField(13, value);
  @$pb.TagNumber(13)
  $core.bool hasGIri() => $_has(12);
  @$pb.TagNumber(13)
  void clearGIri() => $_clearField(13);
  @$pb.TagNumber(13)
  RdfIri ensureGIri() => $_ensure(12);

  /// Blank node
  @$pb.TagNumber(14)
  $core.String get gBnode => $_getSZ(13);
  @$pb.TagNumber(14)
  set gBnode($core.String value) => $_setString(13, value);
  @$pb.TagNumber(14)
  $core.bool hasGBnode() => $_has(13);
  @$pb.TagNumber(14)
  void clearGBnode() => $_clearField(14);

  /// Default graph
  @$pb.TagNumber(15)
  RdfDefaultGraph get gDefaultGraph => $_getN(14);
  @$pb.TagNumber(15)
  set gDefaultGraph(RdfDefaultGraph value) => $_setField(15, value);
  @$pb.TagNumber(15)
  $core.bool hasGDefaultGraph() => $_has(14);
  @$pb.TagNumber(15)
  void clearGDefaultGraph() => $_clearField(15);
  @$pb.TagNumber(15)
  RdfDefaultGraph ensureGDefaultGraph() => $_ensure(14);

  /// Literal – only valid for generalized RDF streams
  @$pb.TagNumber(16)
  RdfLiteral get gLiteral => $_getN(15);
  @$pb.TagNumber(16)
  set gLiteral(RdfLiteral value) => $_setField(16, value);
  @$pb.TagNumber(16)
  $core.bool hasGLiteral() => $_has(15);
  @$pb.TagNumber(16)
  void clearGLiteral() => $_clearField(16);
  @$pb.TagNumber(16)
  RdfLiteral ensureGLiteral() => $_ensure(15);
}

enum RdfGraphStart_Graph { gIri, gBnode, gDefaultGraph, gLiteral, notSet }

/// Start of a graph in a GRAPHS stream
///
/// In contrast to RdfQuad, setting the graph oneof to some value
/// is always required. No repeated terms are allowed.
class RdfGraphStart extends $pb.GeneratedMessage {
  factory RdfGraphStart({
    RdfIri? gIri,
    $core.String? gBnode,
    RdfDefaultGraph? gDefaultGraph,
    RdfLiteral? gLiteral,
  }) {
    final result = create();
    if (gIri != null) result.gIri = gIri;
    if (gBnode != null) result.gBnode = gBnode;
    if (gDefaultGraph != null) result.gDefaultGraph = gDefaultGraph;
    if (gLiteral != null) result.gLiteral = gLiteral;
    return result;
  }

  RdfGraphStart._();

  factory RdfGraphStart.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RdfGraphStart.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, RdfGraphStart_Graph>
      _RdfGraphStart_GraphByTag = {
    1: RdfGraphStart_Graph.gIri,
    2: RdfGraphStart_Graph.gBnode,
    3: RdfGraphStart_Graph.gDefaultGraph,
    4: RdfGraphStart_Graph.gLiteral,
    0: RdfGraphStart_Graph.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RdfGraphStart',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'eu.ostrzyciel.jelly.core.proto.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2, 3, 4])
    ..aOM<RdfIri>(1, _omitFieldNames ? '' : 'gIri', subBuilder: RdfIri.create)
    ..aOS(2, _omitFieldNames ? '' : 'gBnode')
    ..aOM<RdfDefaultGraph>(3, _omitFieldNames ? '' : 'gDefaultGraph',
        subBuilder: RdfDefaultGraph.create)
    ..aOM<RdfLiteral>(4, _omitFieldNames ? '' : 'gLiteral',
        subBuilder: RdfLiteral.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RdfGraphStart clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RdfGraphStart copyWith(void Function(RdfGraphStart) updates) =>
      super.copyWith((message) => updates(message as RdfGraphStart))
          as RdfGraphStart;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RdfGraphStart create() => RdfGraphStart._();
  @$core.override
  RdfGraphStart createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RdfGraphStart getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RdfGraphStart>(create);
  static RdfGraphStart? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  @$pb.TagNumber(4)
  RdfGraphStart_Graph whichGraph() =>
      _RdfGraphStart_GraphByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  @$pb.TagNumber(4)
  void clearGraph() => $_clearField($_whichOneof(0));

  /// IRI
  @$pb.TagNumber(1)
  RdfIri get gIri => $_getN(0);
  @$pb.TagNumber(1)
  set gIri(RdfIri value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasGIri() => $_has(0);
  @$pb.TagNumber(1)
  void clearGIri() => $_clearField(1);
  @$pb.TagNumber(1)
  RdfIri ensureGIri() => $_ensure(0);

  /// Blank node
  @$pb.TagNumber(2)
  $core.String get gBnode => $_getSZ(1);
  @$pb.TagNumber(2)
  set gBnode($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasGBnode() => $_has(1);
  @$pb.TagNumber(2)
  void clearGBnode() => $_clearField(2);

  /// Default graph
  @$pb.TagNumber(3)
  RdfDefaultGraph get gDefaultGraph => $_getN(2);
  @$pb.TagNumber(3)
  set gDefaultGraph(RdfDefaultGraph value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasGDefaultGraph() => $_has(2);
  @$pb.TagNumber(3)
  void clearGDefaultGraph() => $_clearField(3);
  @$pb.TagNumber(3)
  RdfDefaultGraph ensureGDefaultGraph() => $_ensure(2);

  /// Literal – only valid for generalized RDF streams
  @$pb.TagNumber(4)
  RdfLiteral get gLiteral => $_getN(3);
  @$pb.TagNumber(4)
  set gLiteral(RdfLiteral value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasGLiteral() => $_has(3);
  @$pb.TagNumber(4)
  void clearGLiteral() => $_clearField(4);
  @$pb.TagNumber(4)
  RdfLiteral ensureGLiteral() => $_ensure(3);
}

/// End of a graph in a GRAPHS stream
class RdfGraphEnd extends $pb.GeneratedMessage {
  factory RdfGraphEnd() => create();

  RdfGraphEnd._();

  factory RdfGraphEnd.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RdfGraphEnd.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RdfGraphEnd',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'eu.ostrzyciel.jelly.core.proto.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RdfGraphEnd clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RdfGraphEnd copyWith(void Function(RdfGraphEnd) updates) =>
      super.copyWith((message) => updates(message as RdfGraphEnd))
          as RdfGraphEnd;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RdfGraphEnd create() => RdfGraphEnd._();
  @$core.override
  RdfGraphEnd createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RdfGraphEnd getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RdfGraphEnd>(create);
  static RdfGraphEnd? _defaultInstance;
}

/// Explicit namespace declaration
///
/// This does not correspond to any construct in the RDF Abstract Syntax.
/// Rather, it is a hint to the consumer that the given IRI prefix (namespace)
/// may be associated with a shorter name, like in Turtle syntax:
/// PREFIX ex: <http://example.org/>
///
/// These short names (here "ex:") are NOT used in the RDF statement encoding.
/// This is a purely cosmetic feature useful in cases where you want to
/// preserve the namespace declarations from the original RDF document.
/// These declarations have nothing in common with the prefix lookup table.
class RdfNamespaceDeclaration extends $pb.GeneratedMessage {
  factory RdfNamespaceDeclaration({
    $core.String? name,
    RdfIri? value,
  }) {
    final result = create();
    if (name != null) result.name = name;
    if (value != null) result.value = value;
    return result;
  }

  RdfNamespaceDeclaration._();

  factory RdfNamespaceDeclaration.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RdfNamespaceDeclaration.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RdfNamespaceDeclaration',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'eu.ostrzyciel.jelly.core.proto.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aOM<RdfIri>(2, _omitFieldNames ? '' : 'value', subBuilder: RdfIri.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RdfNamespaceDeclaration clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RdfNamespaceDeclaration copyWith(
          void Function(RdfNamespaceDeclaration) updates) =>
      super.copyWith((message) => updates(message as RdfNamespaceDeclaration))
          as RdfNamespaceDeclaration;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RdfNamespaceDeclaration create() => RdfNamespaceDeclaration._();
  @$core.override
  RdfNamespaceDeclaration createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RdfNamespaceDeclaration getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RdfNamespaceDeclaration>(create);
  static RdfNamespaceDeclaration? _defaultInstance;

  /// Short name of the namespace (e.g., "ex")
  /// Do NOT include the colon.
  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  /// IRI of the namespace (e.g., "http://example.org/")
  @$pb.TagNumber(2)
  RdfIri get value => $_getN(1);
  @$pb.TagNumber(2)
  set value(RdfIri value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasValue() => $_has(1);
  @$pb.TagNumber(2)
  void clearValue() => $_clearField(2);
  @$pb.TagNumber(2)
  RdfIri ensureValue() => $_ensure(1);
}

/// Entry in the name lookup table
class RdfNameEntry extends $pb.GeneratedMessage {
  factory RdfNameEntry({
    $core.int? id,
    $core.String? value,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (value != null) result.value = value;
    return result;
  }

  RdfNameEntry._();

  factory RdfNameEntry.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RdfNameEntry.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RdfNameEntry',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'eu.ostrzyciel.jelly.core.proto.v1'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'id', fieldType: $pb.PbFieldType.OU3)
    ..aOS(2, _omitFieldNames ? '' : 'value')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RdfNameEntry clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RdfNameEntry copyWith(void Function(RdfNameEntry) updates) =>
      super.copyWith((message) => updates(message as RdfNameEntry))
          as RdfNameEntry;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RdfNameEntry create() => RdfNameEntry._();
  @$core.override
  RdfNameEntry createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RdfNameEntry getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RdfNameEntry>(create);
  static RdfNameEntry? _defaultInstance;

  /// 1-based identifier
  /// If id=0, it should be interpreted as previous_id + 1.
  /// If id=0 appears in the first RdfNameEntry of the stream, it should be
  /// interpreted as 1.
  @$pb.TagNumber(1)
  $core.int get id => $_getIZ(0);
  @$pb.TagNumber(1)
  set id($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  /// Value of the name (UTF-8 encoded)
  @$pb.TagNumber(2)
  $core.String get value => $_getSZ(1);
  @$pb.TagNumber(2)
  set value($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasValue() => $_has(1);
  @$pb.TagNumber(2)
  void clearValue() => $_clearField(2);
}

/// Entry in the prefix lookup table
///
/// Note: the prefixes in the lookup table can be arbitrary strings, and are
/// NOT meant to be user-facing. They are only used for IRI compression.
/// To transmit user-facing namespace declarations for cosmetic purposes, use
/// RdfNamespaceDeclaration.
class RdfPrefixEntry extends $pb.GeneratedMessage {
  factory RdfPrefixEntry({
    $core.int? id,
    $core.String? value,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (value != null) result.value = value;
    return result;
  }

  RdfPrefixEntry._();

  factory RdfPrefixEntry.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RdfPrefixEntry.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RdfPrefixEntry',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'eu.ostrzyciel.jelly.core.proto.v1'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'id', fieldType: $pb.PbFieldType.OU3)
    ..aOS(2, _omitFieldNames ? '' : 'value')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RdfPrefixEntry clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RdfPrefixEntry copyWith(void Function(RdfPrefixEntry) updates) =>
      super.copyWith((message) => updates(message as RdfPrefixEntry))
          as RdfPrefixEntry;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RdfPrefixEntry create() => RdfPrefixEntry._();
  @$core.override
  RdfPrefixEntry createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RdfPrefixEntry getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RdfPrefixEntry>(create);
  static RdfPrefixEntry? _defaultInstance;

  /// 1-based identifier
  /// If id=0, it should be interpreted as previous_id + 1.
  /// If id=0 appears in the first RdfPrefixEntry of the stream, it should be
  /// interpreted as 1.
  @$pb.TagNumber(1)
  $core.int get id => $_getIZ(0);
  @$pb.TagNumber(1)
  set id($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  /// Value of the prefix (UTF-8 encoded)
  @$pb.TagNumber(2)
  $core.String get value => $_getSZ(1);
  @$pb.TagNumber(2)
  set value($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasValue() => $_has(1);
  @$pb.TagNumber(2)
  void clearValue() => $_clearField(2);
}

/// Entry in the datatype lookup table
class RdfDatatypeEntry extends $pb.GeneratedMessage {
  factory RdfDatatypeEntry({
    $core.int? id,
    $core.String? value,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (value != null) result.value = value;
    return result;
  }

  RdfDatatypeEntry._();

  factory RdfDatatypeEntry.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RdfDatatypeEntry.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RdfDatatypeEntry',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'eu.ostrzyciel.jelly.core.proto.v1'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'id', fieldType: $pb.PbFieldType.OU3)
    ..aOS(2, _omitFieldNames ? '' : 'value')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RdfDatatypeEntry clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RdfDatatypeEntry copyWith(void Function(RdfDatatypeEntry) updates) =>
      super.copyWith((message) => updates(message as RdfDatatypeEntry))
          as RdfDatatypeEntry;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RdfDatatypeEntry create() => RdfDatatypeEntry._();
  @$core.override
  RdfDatatypeEntry createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RdfDatatypeEntry getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RdfDatatypeEntry>(create);
  static RdfDatatypeEntry? _defaultInstance;

  /// 1-based identifier
  /// If id=0, it should be interpreted as previous_id + 1.
  /// If id=0 appears in the first RdfDatatypeEntry of the stream, it should be
  /// interpreted as 1.
  @$pb.TagNumber(1)
  $core.int get id => $_getIZ(0);
  @$pb.TagNumber(1)
  set id($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  /// Value of the datatype (UTF-8 encoded)
  @$pb.TagNumber(2)
  $core.String get value => $_getSZ(1);
  @$pb.TagNumber(2)
  set value($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasValue() => $_has(1);
  @$pb.TagNumber(2)
  void clearValue() => $_clearField(2);
}

/// RDF stream options
class RdfStreamOptions extends $pb.GeneratedMessage {
  factory RdfStreamOptions({
    $core.String? streamName,
    PhysicalStreamType? physicalType,
    $core.bool? generalizedStatements,
    $core.bool? rdfStar,
    $core.int? maxNameTableSize,
    $core.int? maxPrefixTableSize,
    $core.int? maxDatatypeTableSize,
    LogicalStreamType? logicalType,
    $core.int? version,
  }) {
    final result = create();
    if (streamName != null) result.streamName = streamName;
    if (physicalType != null) result.physicalType = physicalType;
    if (generalizedStatements != null)
      result.generalizedStatements = generalizedStatements;
    if (rdfStar != null) result.rdfStar = rdfStar;
    if (maxNameTableSize != null) result.maxNameTableSize = maxNameTableSize;
    if (maxPrefixTableSize != null)
      result.maxPrefixTableSize = maxPrefixTableSize;
    if (maxDatatypeTableSize != null)
      result.maxDatatypeTableSize = maxDatatypeTableSize;
    if (logicalType != null) result.logicalType = logicalType;
    if (version != null) result.version = version;
    return result;
  }

  RdfStreamOptions._();

  factory RdfStreamOptions.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RdfStreamOptions.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RdfStreamOptions',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'eu.ostrzyciel.jelly.core.proto.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'streamName')
    ..aE<PhysicalStreamType>(2, _omitFieldNames ? '' : 'physicalType',
        enumValues: PhysicalStreamType.values)
    ..aOB(3, _omitFieldNames ? '' : 'generalizedStatements')
    ..aOB(4, _omitFieldNames ? '' : 'rdfStar')
    ..aI(9, _omitFieldNames ? '' : 'maxNameTableSize',
        fieldType: $pb.PbFieldType.OU3)
    ..aI(10, _omitFieldNames ? '' : 'maxPrefixTableSize',
        fieldType: $pb.PbFieldType.OU3)
    ..aI(11, _omitFieldNames ? '' : 'maxDatatypeTableSize',
        fieldType: $pb.PbFieldType.OU3)
    ..aE<LogicalStreamType>(14, _omitFieldNames ? '' : 'logicalType',
        enumValues: LogicalStreamType.values)
    ..aI(15, _omitFieldNames ? '' : 'version', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RdfStreamOptions clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RdfStreamOptions copyWith(void Function(RdfStreamOptions) updates) =>
      super.copyWith((message) => updates(message as RdfStreamOptions))
          as RdfStreamOptions;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RdfStreamOptions create() => RdfStreamOptions._();
  @$core.override
  RdfStreamOptions createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RdfStreamOptions getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RdfStreamOptions>(create);
  static RdfStreamOptions? _defaultInstance;

  /// Name of the stream (completely optional).
  /// This may be used for, e.g., topic names in a pub/sub system.
  @$pb.TagNumber(1)
  $core.String get streamName => $_getSZ(0);
  @$pb.TagNumber(1)
  set streamName($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasStreamName() => $_has(0);
  @$pb.TagNumber(1)
  void clearStreamName() => $_clearField(1);

  /// Type of the stream (required)
  @$pb.TagNumber(2)
  PhysicalStreamType get physicalType => $_getN(1);
  @$pb.TagNumber(2)
  set physicalType(PhysicalStreamType value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasPhysicalType() => $_has(1);
  @$pb.TagNumber(2)
  void clearPhysicalType() => $_clearField(2);

  /// Whether the stream may contain generalized triples, quads, or datasets
  @$pb.TagNumber(3)
  $core.bool get generalizedStatements => $_getBF(2);
  @$pb.TagNumber(3)
  set generalizedStatements($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasGeneralizedStatements() => $_has(2);
  @$pb.TagNumber(3)
  void clearGeneralizedStatements() => $_clearField(3);

  /// Whether the stream may contain RDF-star statements
  @$pb.TagNumber(4)
  $core.bool get rdfStar => $_getBF(3);
  @$pb.TagNumber(4)
  set rdfStar($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasRdfStar() => $_has(3);
  @$pb.TagNumber(4)
  void clearRdfStar() => $_clearField(4);

  /// Maximum size of the name lookup table
  /// (required, must be >= 8)
  @$pb.TagNumber(9)
  $core.int get maxNameTableSize => $_getIZ(4);
  @$pb.TagNumber(9)
  set maxNameTableSize($core.int value) => $_setUnsignedInt32(4, value);
  @$pb.TagNumber(9)
  $core.bool hasMaxNameTableSize() => $_has(4);
  @$pb.TagNumber(9)
  void clearMaxNameTableSize() => $_clearField(9);

  /// Maximum size of the prefix lookup table
  /// (required if the prefix lookup is used)
  @$pb.TagNumber(10)
  $core.int get maxPrefixTableSize => $_getIZ(5);
  @$pb.TagNumber(10)
  set maxPrefixTableSize($core.int value) => $_setUnsignedInt32(5, value);
  @$pb.TagNumber(10)
  $core.bool hasMaxPrefixTableSize() => $_has(5);
  @$pb.TagNumber(10)
  void clearMaxPrefixTableSize() => $_clearField(10);

  /// Maximum size of the datatype lookup table
  /// (required if datatype literals are used)
  @$pb.TagNumber(11)
  $core.int get maxDatatypeTableSize => $_getIZ(6);
  @$pb.TagNumber(11)
  set maxDatatypeTableSize($core.int value) => $_setUnsignedInt32(6, value);
  @$pb.TagNumber(11)
  $core.bool hasMaxDatatypeTableSize() => $_has(6);
  @$pb.TagNumber(11)
  void clearMaxDatatypeTableSize() => $_clearField(11);

  /// Logical (RDF-STaX-based) stream type
  /// In contrast to the physical type, this field is entirely optional.
  @$pb.TagNumber(14)
  LogicalStreamType get logicalType => $_getN(7);
  @$pb.TagNumber(14)
  set logicalType(LogicalStreamType value) => $_setField(14, value);
  @$pb.TagNumber(14)
  $core.bool hasLogicalType() => $_has(7);
  @$pb.TagNumber(14)
  void clearLogicalType() => $_clearField(14);

  /// Protocol version (required)
  /// For Jelly 1.0.x value must be 1.
  /// For Jelly 1.1.x value must be 2.
  /// For custom extensions, the value must be 10000 or higher.
  @$pb.TagNumber(15)
  $core.int get version => $_getIZ(8);
  @$pb.TagNumber(15)
  set version($core.int value) => $_setUnsignedInt32(8, value);
  @$pb.TagNumber(15)
  $core.bool hasVersion() => $_has(8);
  @$pb.TagNumber(15)
  void clearVersion() => $_clearField(15);
}

enum RdfStreamRow_Row {
  options,
  triple,
  quad,
  graphStart,
  graphEnd,
  namespace,
  name,
  prefix,
  datatype,
  notSet
}

/// RDF stream row
class RdfStreamRow extends $pb.GeneratedMessage {
  factory RdfStreamRow({
    RdfStreamOptions? options,
    RdfTriple? triple,
    RdfQuad? quad,
    RdfGraphStart? graphStart,
    RdfGraphEnd? graphEnd,
    RdfNamespaceDeclaration? namespace,
    RdfNameEntry? name,
    RdfPrefixEntry? prefix,
    RdfDatatypeEntry? datatype,
  }) {
    final result = create();
    if (options != null) result.options = options;
    if (triple != null) result.triple = triple;
    if (quad != null) result.quad = quad;
    if (graphStart != null) result.graphStart = graphStart;
    if (graphEnd != null) result.graphEnd = graphEnd;
    if (namespace != null) result.namespace = namespace;
    if (name != null) result.name = name;
    if (prefix != null) result.prefix = prefix;
    if (datatype != null) result.datatype = datatype;
    return result;
  }

  RdfStreamRow._();

  factory RdfStreamRow.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RdfStreamRow.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, RdfStreamRow_Row> _RdfStreamRow_RowByTag = {
    1: RdfStreamRow_Row.options,
    2: RdfStreamRow_Row.triple,
    3: RdfStreamRow_Row.quad,
    4: RdfStreamRow_Row.graphStart,
    5: RdfStreamRow_Row.graphEnd,
    6: RdfStreamRow_Row.namespace,
    9: RdfStreamRow_Row.name,
    10: RdfStreamRow_Row.prefix,
    11: RdfStreamRow_Row.datatype,
    0: RdfStreamRow_Row.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RdfStreamRow',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'eu.ostrzyciel.jelly.core.proto.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2, 3, 4, 5, 6, 9, 10, 11])
    ..aOM<RdfStreamOptions>(1, _omitFieldNames ? '' : 'options',
        subBuilder: RdfStreamOptions.create)
    ..aOM<RdfTriple>(2, _omitFieldNames ? '' : 'triple',
        subBuilder: RdfTriple.create)
    ..aOM<RdfQuad>(3, _omitFieldNames ? '' : 'quad', subBuilder: RdfQuad.create)
    ..aOM<RdfGraphStart>(4, _omitFieldNames ? '' : 'graphStart',
        subBuilder: RdfGraphStart.create)
    ..aOM<RdfGraphEnd>(5, _omitFieldNames ? '' : 'graphEnd',
        subBuilder: RdfGraphEnd.create)
    ..aOM<RdfNamespaceDeclaration>(6, _omitFieldNames ? '' : 'namespace',
        subBuilder: RdfNamespaceDeclaration.create)
    ..aOM<RdfNameEntry>(9, _omitFieldNames ? '' : 'name',
        subBuilder: RdfNameEntry.create)
    ..aOM<RdfPrefixEntry>(10, _omitFieldNames ? '' : 'prefix',
        subBuilder: RdfPrefixEntry.create)
    ..aOM<RdfDatatypeEntry>(11, _omitFieldNames ? '' : 'datatype',
        subBuilder: RdfDatatypeEntry.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RdfStreamRow clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RdfStreamRow copyWith(void Function(RdfStreamRow) updates) =>
      super.copyWith((message) => updates(message as RdfStreamRow))
          as RdfStreamRow;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RdfStreamRow create() => RdfStreamRow._();
  @$core.override
  RdfStreamRow createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RdfStreamRow getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RdfStreamRow>(create);
  static RdfStreamRow? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  @$pb.TagNumber(4)
  @$pb.TagNumber(5)
  @$pb.TagNumber(6)
  @$pb.TagNumber(9)
  @$pb.TagNumber(10)
  @$pb.TagNumber(11)
  RdfStreamRow_Row whichRow() => _RdfStreamRow_RowByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  @$pb.TagNumber(4)
  @$pb.TagNumber(5)
  @$pb.TagNumber(6)
  @$pb.TagNumber(9)
  @$pb.TagNumber(10)
  @$pb.TagNumber(11)
  void clearRow() => $_clearField($_whichOneof(0));

  /// Stream options. Must occur at the start of the stream.
  @$pb.TagNumber(1)
  RdfStreamOptions get options => $_getN(0);
  @$pb.TagNumber(1)
  set options(RdfStreamOptions value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasOptions() => $_has(0);
  @$pb.TagNumber(1)
  void clearOptions() => $_clearField(1);
  @$pb.TagNumber(1)
  RdfStreamOptions ensureOptions() => $_ensure(0);

  /// RDF triple statement.
  /// Valid in streams of physical type TRIPLES or GRAPHS.
  @$pb.TagNumber(2)
  RdfTriple get triple => $_getN(1);
  @$pb.TagNumber(2)
  set triple(RdfTriple value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasTriple() => $_has(1);
  @$pb.TagNumber(2)
  void clearTriple() => $_clearField(2);
  @$pb.TagNumber(2)
  RdfTriple ensureTriple() => $_ensure(1);

  /// RDF quad statement.
  /// Only valid in streams of physical type QUADS.
  @$pb.TagNumber(3)
  RdfQuad get quad => $_getN(2);
  @$pb.TagNumber(3)
  set quad(RdfQuad value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasQuad() => $_has(2);
  @$pb.TagNumber(3)
  void clearQuad() => $_clearField(3);
  @$pb.TagNumber(3)
  RdfQuad ensureQuad() => $_ensure(2);

  /// Graph boundary: ends the currently transmitted graph and starts a new one
  /// Only valid in streams of physical type GRAPHS.
  @$pb.TagNumber(4)
  RdfGraphStart get graphStart => $_getN(3);
  @$pb.TagNumber(4)
  set graphStart(RdfGraphStart value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasGraphStart() => $_has(3);
  @$pb.TagNumber(4)
  void clearGraphStart() => $_clearField(4);
  @$pb.TagNumber(4)
  RdfGraphStart ensureGraphStart() => $_ensure(3);

  /// Explicit end of a graph.
  /// Signals the consumer that the transmitted graph is complete.
  /// Only valid in streams of physical type GRAPHS.
  @$pb.TagNumber(5)
  RdfGraphEnd get graphEnd => $_getN(4);
  @$pb.TagNumber(5)
  set graphEnd(RdfGraphEnd value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasGraphEnd() => $_has(4);
  @$pb.TagNumber(5)
  void clearGraphEnd() => $_clearField(5);
  @$pb.TagNumber(5)
  RdfGraphEnd ensureGraphEnd() => $_ensure(4);

  /// Explicit namespace declaration.
  @$pb.TagNumber(6)
  RdfNamespaceDeclaration get namespace => $_getN(5);
  @$pb.TagNumber(6)
  set namespace(RdfNamespaceDeclaration value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasNamespace() => $_has(5);
  @$pb.TagNumber(6)
  void clearNamespace() => $_clearField(6);
  @$pb.TagNumber(6)
  RdfNamespaceDeclaration ensureNamespace() => $_ensure(5);

  /// Entry in the name lookup table.
  @$pb.TagNumber(9)
  RdfNameEntry get name => $_getN(6);
  @$pb.TagNumber(9)
  set name(RdfNameEntry value) => $_setField(9, value);
  @$pb.TagNumber(9)
  $core.bool hasName() => $_has(6);
  @$pb.TagNumber(9)
  void clearName() => $_clearField(9);
  @$pb.TagNumber(9)
  RdfNameEntry ensureName() => $_ensure(6);

  /// Entry in the prefix lookup table.
  @$pb.TagNumber(10)
  RdfPrefixEntry get prefix => $_getN(7);
  @$pb.TagNumber(10)
  set prefix(RdfPrefixEntry value) => $_setField(10, value);
  @$pb.TagNumber(10)
  $core.bool hasPrefix() => $_has(7);
  @$pb.TagNumber(10)
  void clearPrefix() => $_clearField(10);
  @$pb.TagNumber(10)
  RdfPrefixEntry ensurePrefix() => $_ensure(7);

  /// Entry in the datatype lookup table.
  @$pb.TagNumber(11)
  RdfDatatypeEntry get datatype => $_getN(8);
  @$pb.TagNumber(11)
  set datatype(RdfDatatypeEntry value) => $_setField(11, value);
  @$pb.TagNumber(11)
  $core.bool hasDatatype() => $_has(8);
  @$pb.TagNumber(11)
  void clearDatatype() => $_clearField(11);
  @$pb.TagNumber(11)
  RdfDatatypeEntry ensureDatatype() => $_ensure(8);
}

/// RDF stream frame – base message for RDF streams.
class RdfStreamFrame extends $pb.GeneratedMessage {
  factory RdfStreamFrame({
    $core.Iterable<RdfStreamRow>? rows,
    $core.Iterable<$core.MapEntry<$core.String, $core.List<$core.int>>>?
        metadata,
  }) {
    final result = create();
    if (rows != null) result.rows.addAll(rows);
    if (metadata != null) result.metadata.addEntries(metadata);
    return result;
  }

  RdfStreamFrame._();

  factory RdfStreamFrame.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RdfStreamFrame.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RdfStreamFrame',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'eu.ostrzyciel.jelly.core.proto.v1'),
      createEmptyInstance: create)
    ..pPM<RdfStreamRow>(1, _omitFieldNames ? '' : 'rows',
        subBuilder: RdfStreamRow.create)
    ..m<$core.String, $core.List<$core.int>>(
        15, _omitFieldNames ? '' : 'metadata',
        entryClassName: 'RdfStreamFrame.MetadataEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OY,
        packageName: const $pb.PackageName('eu.ostrzyciel.jelly.core.proto.v1'))
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RdfStreamFrame clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RdfStreamFrame copyWith(void Function(RdfStreamFrame) updates) =>
      super.copyWith((message) => updates(message as RdfStreamFrame))
          as RdfStreamFrame;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RdfStreamFrame create() => RdfStreamFrame._();
  @$core.override
  RdfStreamFrame createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RdfStreamFrame getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RdfStreamFrame>(create);
  static RdfStreamFrame? _defaultInstance;

  /// Stream rows
  @$pb.TagNumber(1)
  $pb.PbList<RdfStreamRow> get rows => $_getList(0);

  /// Arbitrary metadata
  /// The keys are UTF-8 encoded strings, the values are byte arrays.
  /// This may be used by implementations in any way they see fit.
  /// The metadata does not affect the RDF data in any way, treat it
  /// as comments in a text file.
  @$pb.TagNumber(15)
  $pb.PbMap<$core.String, $core.List<$core.int>> get metadata => $_getMap(1);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
