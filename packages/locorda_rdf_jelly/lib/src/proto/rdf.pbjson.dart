// This is a generated file - do not edit.
//
// Generated from rdf.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports
// ignore_for_file: unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use physicalStreamTypeDescriptor instead')
const PhysicalStreamType$json = {
  '1': 'PhysicalStreamType',
  '2': [
    {'1': 'PHYSICAL_STREAM_TYPE_UNSPECIFIED', '2': 0},
    {'1': 'PHYSICAL_STREAM_TYPE_TRIPLES', '2': 1},
    {'1': 'PHYSICAL_STREAM_TYPE_QUADS', '2': 2},
    {'1': 'PHYSICAL_STREAM_TYPE_GRAPHS', '2': 3},
  ],
};

/// Descriptor for `PhysicalStreamType`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List physicalStreamTypeDescriptor = $convert.base64Decode(
    'ChJQaHlzaWNhbFN0cmVhbVR5cGUSJAogUEhZU0lDQUxfU1RSRUFNX1RZUEVfVU5TUEVDSUZJRU'
    'QQABIgChxQSFlTSUNBTF9TVFJFQU1fVFlQRV9UUklQTEVTEAESHgoaUEhZU0lDQUxfU1RSRUFN'
    'X1RZUEVfUVVBRFMQAhIfChtQSFlTSUNBTF9TVFJFQU1fVFlQRV9HUkFQSFMQAw==');

@$core.Deprecated('Use logicalStreamTypeDescriptor instead')
const LogicalStreamType$json = {
  '1': 'LogicalStreamType',
  '2': [
    {'1': 'LOGICAL_STREAM_TYPE_UNSPECIFIED', '2': 0},
    {'1': 'LOGICAL_STREAM_TYPE_FLAT_TRIPLES', '2': 1},
    {'1': 'LOGICAL_STREAM_TYPE_FLAT_QUADS', '2': 2},
    {'1': 'LOGICAL_STREAM_TYPE_GRAPHS', '2': 3},
    {'1': 'LOGICAL_STREAM_TYPE_DATASETS', '2': 4},
    {'1': 'LOGICAL_STREAM_TYPE_SUBJECT_GRAPHS', '2': 13},
    {'1': 'LOGICAL_STREAM_TYPE_NAMED_GRAPHS', '2': 14},
    {'1': 'LOGICAL_STREAM_TYPE_TIMESTAMPED_NAMED_GRAPHS', '2': 114},
  ],
};

/// Descriptor for `LogicalStreamType`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List logicalStreamTypeDescriptor = $convert.base64Decode(
    'ChFMb2dpY2FsU3RyZWFtVHlwZRIjCh9MT0dJQ0FMX1NUUkVBTV9UWVBFX1VOU1BFQ0lGSUVEEA'
    'ASJAogTE9HSUNBTF9TVFJFQU1fVFlQRV9GTEFUX1RSSVBMRVMQARIiCh5MT0dJQ0FMX1NUUkVB'
    'TV9UWVBFX0ZMQVRfUVVBRFMQAhIeChpMT0dJQ0FMX1NUUkVBTV9UWVBFX0dSQVBIUxADEiAKHE'
    'xPR0lDQUxfU1RSRUFNX1RZUEVfREFUQVNFVFMQBBImCiJMT0dJQ0FMX1NUUkVBTV9UWVBFX1NV'
    'QkpFQ1RfR1JBUEhTEA0SJAogTE9HSUNBTF9TVFJFQU1fVFlQRV9OQU1FRF9HUkFQSFMQDhIwCi'
    'xMT0dJQ0FMX1NUUkVBTV9UWVBFX1RJTUVTVEFNUEVEX05BTUVEX0dSQVBIUxBy');

@$core.Deprecated('Use rdfIriDescriptor instead')
const RdfIri$json = {
  '1': 'RdfIri',
  '2': [
    {'1': 'prefix_id', '3': 1, '4': 1, '5': 13, '10': 'prefixId'},
    {'1': 'name_id', '3': 2, '4': 1, '5': 13, '10': 'nameId'},
  ],
};

/// Descriptor for `RdfIri`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List rdfIriDescriptor = $convert.base64Decode(
    'CgZSZGZJcmkSGwoJcHJlZml4X2lkGAEgASgNUghwcmVmaXhJZBIXCgduYW1lX2lkGAIgASgNUg'
    'ZuYW1lSWQ=');

@$core.Deprecated('Use rdfLiteralDescriptor instead')
const RdfLiteral$json = {
  '1': 'RdfLiteral',
  '2': [
    {'1': 'lex', '3': 1, '4': 1, '5': 9, '10': 'lex'},
    {'1': 'langtag', '3': 2, '4': 1, '5': 9, '9': 0, '10': 'langtag'},
    {'1': 'datatype', '3': 3, '4': 1, '5': 13, '9': 0, '10': 'datatype'},
  ],
  '8': [
    {'1': 'literalKind'},
  ],
};

/// Descriptor for `RdfLiteral`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List rdfLiteralDescriptor = $convert.base64Decode(
    'CgpSZGZMaXRlcmFsEhAKA2xleBgBIAEoCVIDbGV4EhoKB2xhbmd0YWcYAiABKAlIAFIHbGFuZ3'
    'RhZxIcCghkYXRhdHlwZRgDIAEoDUgAUghkYXRhdHlwZUINCgtsaXRlcmFsS2luZA==');

@$core.Deprecated('Use rdfDefaultGraphDescriptor instead')
const RdfDefaultGraph$json = {
  '1': 'RdfDefaultGraph',
};

/// Descriptor for `RdfDefaultGraph`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List rdfDefaultGraphDescriptor =
    $convert.base64Decode('Cg9SZGZEZWZhdWx0R3JhcGg=');

@$core.Deprecated('Use rdfTripleDescriptor instead')
const RdfTriple$json = {
  '1': 'RdfTriple',
  '2': [
    {
      '1': 's_iri',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.eu.ostrzyciel.jelly.core.proto.v1.RdfIri',
      '9': 0,
      '10': 'sIri'
    },
    {'1': 's_bnode', '3': 2, '4': 1, '5': 9, '9': 0, '10': 'sBnode'},
    {
      '1': 's_literal',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.eu.ostrzyciel.jelly.core.proto.v1.RdfLiteral',
      '9': 0,
      '10': 'sLiteral'
    },
    {
      '1': 's_triple_term',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.eu.ostrzyciel.jelly.core.proto.v1.RdfTriple',
      '9': 0,
      '10': 'sTripleTerm'
    },
    {
      '1': 'p_iri',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.eu.ostrzyciel.jelly.core.proto.v1.RdfIri',
      '9': 1,
      '10': 'pIri'
    },
    {'1': 'p_bnode', '3': 6, '4': 1, '5': 9, '9': 1, '10': 'pBnode'},
    {
      '1': 'p_literal',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.eu.ostrzyciel.jelly.core.proto.v1.RdfLiteral',
      '9': 1,
      '10': 'pLiteral'
    },
    {
      '1': 'p_triple_term',
      '3': 8,
      '4': 1,
      '5': 11,
      '6': '.eu.ostrzyciel.jelly.core.proto.v1.RdfTriple',
      '9': 1,
      '10': 'pTripleTerm'
    },
    {
      '1': 'o_iri',
      '3': 9,
      '4': 1,
      '5': 11,
      '6': '.eu.ostrzyciel.jelly.core.proto.v1.RdfIri',
      '9': 2,
      '10': 'oIri'
    },
    {'1': 'o_bnode', '3': 10, '4': 1, '5': 9, '9': 2, '10': 'oBnode'},
    {
      '1': 'o_literal',
      '3': 11,
      '4': 1,
      '5': 11,
      '6': '.eu.ostrzyciel.jelly.core.proto.v1.RdfLiteral',
      '9': 2,
      '10': 'oLiteral'
    },
    {
      '1': 'o_triple_term',
      '3': 12,
      '4': 1,
      '5': 11,
      '6': '.eu.ostrzyciel.jelly.core.proto.v1.RdfTriple',
      '9': 2,
      '10': 'oTripleTerm'
    },
  ],
  '8': [
    {'1': 'subject'},
    {'1': 'predicate'},
    {'1': 'object'},
  ],
};

/// Descriptor for `RdfTriple`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List rdfTripleDescriptor = $convert.base64Decode(
    'CglSZGZUcmlwbGUSQAoFc19pcmkYASABKAsyKS5ldS5vc3RyenljaWVsLmplbGx5LmNvcmUucH'
    'JvdG8udjEuUmRmSXJpSABSBHNJcmkSGQoHc19ibm9kZRgCIAEoCUgAUgZzQm5vZGUSTAoJc19s'
    'aXRlcmFsGAMgASgLMi0uZXUub3N0cnp5Y2llbC5qZWxseS5jb3JlLnByb3RvLnYxLlJkZkxpdG'
    'VyYWxIAFIIc0xpdGVyYWwSUgoNc190cmlwbGVfdGVybRgEIAEoCzIsLmV1Lm9zdHJ6eWNpZWwu'
    'amVsbHkuY29yZS5wcm90by52MS5SZGZUcmlwbGVIAFILc1RyaXBsZVRlcm0SQAoFcF9pcmkYBS'
    'ABKAsyKS5ldS5vc3RyenljaWVsLmplbGx5LmNvcmUucHJvdG8udjEuUmRmSXJpSAFSBHBJcmkS'
    'GQoHcF9ibm9kZRgGIAEoCUgBUgZwQm5vZGUSTAoJcF9saXRlcmFsGAcgASgLMi0uZXUub3N0cn'
    'p5Y2llbC5qZWxseS5jb3JlLnByb3RvLnYxLlJkZkxpdGVyYWxIAVIIcExpdGVyYWwSUgoNcF90'
    'cmlwbGVfdGVybRgIIAEoCzIsLmV1Lm9zdHJ6eWNpZWwuamVsbHkuY29yZS5wcm90by52MS5SZG'
    'ZUcmlwbGVIAVILcFRyaXBsZVRlcm0SQAoFb19pcmkYCSABKAsyKS5ldS5vc3RyenljaWVsLmpl'
    'bGx5LmNvcmUucHJvdG8udjEuUmRmSXJpSAJSBG9JcmkSGQoHb19ibm9kZRgKIAEoCUgCUgZvQm'
    '5vZGUSTAoJb19saXRlcmFsGAsgASgLMi0uZXUub3N0cnp5Y2llbC5qZWxseS5jb3JlLnByb3Rv'
    'LnYxLlJkZkxpdGVyYWxIAlIIb0xpdGVyYWwSUgoNb190cmlwbGVfdGVybRgMIAEoCzIsLmV1Lm'
    '9zdHJ6eWNpZWwuamVsbHkuY29yZS5wcm90by52MS5SZGZUcmlwbGVIAlILb1RyaXBsZVRlcm1C'
    'CQoHc3ViamVjdEILCglwcmVkaWNhdGVCCAoGb2JqZWN0');

@$core.Deprecated('Use rdfQuadDescriptor instead')
const RdfQuad$json = {
  '1': 'RdfQuad',
  '2': [
    {
      '1': 's_iri',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.eu.ostrzyciel.jelly.core.proto.v1.RdfIri',
      '9': 0,
      '10': 'sIri'
    },
    {'1': 's_bnode', '3': 2, '4': 1, '5': 9, '9': 0, '10': 'sBnode'},
    {
      '1': 's_literal',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.eu.ostrzyciel.jelly.core.proto.v1.RdfLiteral',
      '9': 0,
      '10': 'sLiteral'
    },
    {
      '1': 's_triple_term',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.eu.ostrzyciel.jelly.core.proto.v1.RdfTriple',
      '9': 0,
      '10': 'sTripleTerm'
    },
    {
      '1': 'p_iri',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.eu.ostrzyciel.jelly.core.proto.v1.RdfIri',
      '9': 1,
      '10': 'pIri'
    },
    {'1': 'p_bnode', '3': 6, '4': 1, '5': 9, '9': 1, '10': 'pBnode'},
    {
      '1': 'p_literal',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.eu.ostrzyciel.jelly.core.proto.v1.RdfLiteral',
      '9': 1,
      '10': 'pLiteral'
    },
    {
      '1': 'p_triple_term',
      '3': 8,
      '4': 1,
      '5': 11,
      '6': '.eu.ostrzyciel.jelly.core.proto.v1.RdfTriple',
      '9': 1,
      '10': 'pTripleTerm'
    },
    {
      '1': 'o_iri',
      '3': 9,
      '4': 1,
      '5': 11,
      '6': '.eu.ostrzyciel.jelly.core.proto.v1.RdfIri',
      '9': 2,
      '10': 'oIri'
    },
    {'1': 'o_bnode', '3': 10, '4': 1, '5': 9, '9': 2, '10': 'oBnode'},
    {
      '1': 'o_literal',
      '3': 11,
      '4': 1,
      '5': 11,
      '6': '.eu.ostrzyciel.jelly.core.proto.v1.RdfLiteral',
      '9': 2,
      '10': 'oLiteral'
    },
    {
      '1': 'o_triple_term',
      '3': 12,
      '4': 1,
      '5': 11,
      '6': '.eu.ostrzyciel.jelly.core.proto.v1.RdfTriple',
      '9': 2,
      '10': 'oTripleTerm'
    },
    {
      '1': 'g_iri',
      '3': 13,
      '4': 1,
      '5': 11,
      '6': '.eu.ostrzyciel.jelly.core.proto.v1.RdfIri',
      '9': 3,
      '10': 'gIri'
    },
    {'1': 'g_bnode', '3': 14, '4': 1, '5': 9, '9': 3, '10': 'gBnode'},
    {
      '1': 'g_default_graph',
      '3': 15,
      '4': 1,
      '5': 11,
      '6': '.eu.ostrzyciel.jelly.core.proto.v1.RdfDefaultGraph',
      '9': 3,
      '10': 'gDefaultGraph'
    },
    {
      '1': 'g_literal',
      '3': 16,
      '4': 1,
      '5': 11,
      '6': '.eu.ostrzyciel.jelly.core.proto.v1.RdfLiteral',
      '9': 3,
      '10': 'gLiteral'
    },
  ],
  '8': [
    {'1': 'subject'},
    {'1': 'predicate'},
    {'1': 'object'},
    {'1': 'graph'},
  ],
};

/// Descriptor for `RdfQuad`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List rdfQuadDescriptor = $convert.base64Decode(
    'CgdSZGZRdWFkEkAKBXNfaXJpGAEgASgLMikuZXUub3N0cnp5Y2llbC5qZWxseS5jb3JlLnByb3'
    'RvLnYxLlJkZklyaUgAUgRzSXJpEhkKB3NfYm5vZGUYAiABKAlIAFIGc0Jub2RlEkwKCXNfbGl0'
    'ZXJhbBgDIAEoCzItLmV1Lm9zdHJ6eWNpZWwuamVsbHkuY29yZS5wcm90by52MS5SZGZMaXRlcm'
    'FsSABSCHNMaXRlcmFsElIKDXNfdHJpcGxlX3Rlcm0YBCABKAsyLC5ldS5vc3RyenljaWVsLmpl'
    'bGx5LmNvcmUucHJvdG8udjEuUmRmVHJpcGxlSABSC3NUcmlwbGVUZXJtEkAKBXBfaXJpGAUgAS'
    'gLMikuZXUub3N0cnp5Y2llbC5qZWxseS5jb3JlLnByb3RvLnYxLlJkZklyaUgBUgRwSXJpEhkK'
    'B3BfYm5vZGUYBiABKAlIAVIGcEJub2RlEkwKCXBfbGl0ZXJhbBgHIAEoCzItLmV1Lm9zdHJ6eW'
    'NpZWwuamVsbHkuY29yZS5wcm90by52MS5SZGZMaXRlcmFsSAFSCHBMaXRlcmFsElIKDXBfdHJp'
    'cGxlX3Rlcm0YCCABKAsyLC5ldS5vc3RyenljaWVsLmplbGx5LmNvcmUucHJvdG8udjEuUmRmVH'
    'JpcGxlSAFSC3BUcmlwbGVUZXJtEkAKBW9faXJpGAkgASgLMikuZXUub3N0cnp5Y2llbC5qZWxs'
    'eS5jb3JlLnByb3RvLnYxLlJkZklyaUgCUgRvSXJpEhkKB29fYm5vZGUYCiABKAlIAlIGb0Jub2'
    'RlEkwKCW9fbGl0ZXJhbBgLIAEoCzItLmV1Lm9zdHJ6eWNpZWwuamVsbHkuY29yZS5wcm90by52'
    'MS5SZGZMaXRlcmFsSAJSCG9MaXRlcmFsElIKDW9fdHJpcGxlX3Rlcm0YDCABKAsyLC5ldS5vc3'
    'RyenljaWVsLmplbGx5LmNvcmUucHJvdG8udjEuUmRmVHJpcGxlSAJSC29UcmlwbGVUZXJtEkAK'
    'BWdfaXJpGA0gASgLMikuZXUub3N0cnp5Y2llbC5qZWxseS5jb3JlLnByb3RvLnYxLlJkZklyaU'
    'gDUgRnSXJpEhkKB2dfYm5vZGUYDiABKAlIA1IGZ0Jub2RlElwKD2dfZGVmYXVsdF9ncmFwaBgP'
    'IAEoCzIyLmV1Lm9zdHJ6eWNpZWwuamVsbHkuY29yZS5wcm90by52MS5SZGZEZWZhdWx0R3JhcG'
    'hIA1INZ0RlZmF1bHRHcmFwaBJMCglnX2xpdGVyYWwYECABKAsyLS5ldS5vc3RyenljaWVsLmpl'
    'bGx5LmNvcmUucHJvdG8udjEuUmRmTGl0ZXJhbEgDUghnTGl0ZXJhbEIJCgdzdWJqZWN0QgsKCX'
    'ByZWRpY2F0ZUIICgZvYmplY3RCBwoFZ3JhcGg=');

@$core.Deprecated('Use rdfGraphStartDescriptor instead')
const RdfGraphStart$json = {
  '1': 'RdfGraphStart',
  '2': [
    {
      '1': 'g_iri',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.eu.ostrzyciel.jelly.core.proto.v1.RdfIri',
      '9': 0,
      '10': 'gIri'
    },
    {'1': 'g_bnode', '3': 2, '4': 1, '5': 9, '9': 0, '10': 'gBnode'},
    {
      '1': 'g_default_graph',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.eu.ostrzyciel.jelly.core.proto.v1.RdfDefaultGraph',
      '9': 0,
      '10': 'gDefaultGraph'
    },
    {
      '1': 'g_literal',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.eu.ostrzyciel.jelly.core.proto.v1.RdfLiteral',
      '9': 0,
      '10': 'gLiteral'
    },
  ],
  '8': [
    {'1': 'graph'},
  ],
};

/// Descriptor for `RdfGraphStart`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List rdfGraphStartDescriptor = $convert.base64Decode(
    'Cg1SZGZHcmFwaFN0YXJ0EkAKBWdfaXJpGAEgASgLMikuZXUub3N0cnp5Y2llbC5qZWxseS5jb3'
    'JlLnByb3RvLnYxLlJkZklyaUgAUgRnSXJpEhkKB2dfYm5vZGUYAiABKAlIAFIGZ0Jub2RlElwK'
    'D2dfZGVmYXVsdF9ncmFwaBgDIAEoCzIyLmV1Lm9zdHJ6eWNpZWwuamVsbHkuY29yZS5wcm90by'
    '52MS5SZGZEZWZhdWx0R3JhcGhIAFINZ0RlZmF1bHRHcmFwaBJMCglnX2xpdGVyYWwYBCABKAsy'
    'LS5ldS5vc3RyenljaWVsLmplbGx5LmNvcmUucHJvdG8udjEuUmRmTGl0ZXJhbEgAUghnTGl0ZX'
    'JhbEIHCgVncmFwaA==');

@$core.Deprecated('Use rdfGraphEndDescriptor instead')
const RdfGraphEnd$json = {
  '1': 'RdfGraphEnd',
};

/// Descriptor for `RdfGraphEnd`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List rdfGraphEndDescriptor =
    $convert.base64Decode('CgtSZGZHcmFwaEVuZA==');

@$core.Deprecated('Use rdfNamespaceDeclarationDescriptor instead')
const RdfNamespaceDeclaration$json = {
  '1': 'RdfNamespaceDeclaration',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {
      '1': 'value',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.eu.ostrzyciel.jelly.core.proto.v1.RdfIri',
      '10': 'value'
    },
  ],
};

/// Descriptor for `RdfNamespaceDeclaration`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List rdfNamespaceDeclarationDescriptor = $convert.base64Decode(
    'ChdSZGZOYW1lc3BhY2VEZWNsYXJhdGlvbhISCgRuYW1lGAEgASgJUgRuYW1lEj8KBXZhbHVlGA'
    'IgASgLMikuZXUub3N0cnp5Y2llbC5qZWxseS5jb3JlLnByb3RvLnYxLlJkZklyaVIFdmFsdWU=');

@$core.Deprecated('Use rdfNameEntryDescriptor instead')
const RdfNameEntry$json = {
  '1': 'RdfNameEntry',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 13, '10': 'id'},
    {'1': 'value', '3': 2, '4': 1, '5': 9, '10': 'value'},
  ],
};

/// Descriptor for `RdfNameEntry`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List rdfNameEntryDescriptor = $convert.base64Decode(
    'CgxSZGZOYW1lRW50cnkSDgoCaWQYASABKA1SAmlkEhQKBXZhbHVlGAIgASgJUgV2YWx1ZQ==');

@$core.Deprecated('Use rdfPrefixEntryDescriptor instead')
const RdfPrefixEntry$json = {
  '1': 'RdfPrefixEntry',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 13, '10': 'id'},
    {'1': 'value', '3': 2, '4': 1, '5': 9, '10': 'value'},
  ],
};

/// Descriptor for `RdfPrefixEntry`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List rdfPrefixEntryDescriptor = $convert.base64Decode(
    'Cg5SZGZQcmVmaXhFbnRyeRIOCgJpZBgBIAEoDVICaWQSFAoFdmFsdWUYAiABKAlSBXZhbHVl');

@$core.Deprecated('Use rdfDatatypeEntryDescriptor instead')
const RdfDatatypeEntry$json = {
  '1': 'RdfDatatypeEntry',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 13, '10': 'id'},
    {'1': 'value', '3': 2, '4': 1, '5': 9, '10': 'value'},
  ],
};

/// Descriptor for `RdfDatatypeEntry`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List rdfDatatypeEntryDescriptor = $convert.base64Decode(
    'ChBSZGZEYXRhdHlwZUVudHJ5Eg4KAmlkGAEgASgNUgJpZBIUCgV2YWx1ZRgCIAEoCVIFdmFsdW'
    'U=');

@$core.Deprecated('Use rdfStreamOptionsDescriptor instead')
const RdfStreamOptions$json = {
  '1': 'RdfStreamOptions',
  '2': [
    {'1': 'stream_name', '3': 1, '4': 1, '5': 9, '10': 'streamName'},
    {
      '1': 'physical_type',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.eu.ostrzyciel.jelly.core.proto.v1.PhysicalStreamType',
      '10': 'physicalType'
    },
    {
      '1': 'generalized_statements',
      '3': 3,
      '4': 1,
      '5': 8,
      '10': 'generalizedStatements'
    },
    {'1': 'rdf_star', '3': 4, '4': 1, '5': 8, '10': 'rdfStar'},
    {
      '1': 'max_name_table_size',
      '3': 9,
      '4': 1,
      '5': 13,
      '10': 'maxNameTableSize'
    },
    {
      '1': 'max_prefix_table_size',
      '3': 10,
      '4': 1,
      '5': 13,
      '10': 'maxPrefixTableSize'
    },
    {
      '1': 'max_datatype_table_size',
      '3': 11,
      '4': 1,
      '5': 13,
      '10': 'maxDatatypeTableSize'
    },
    {
      '1': 'logical_type',
      '3': 14,
      '4': 1,
      '5': 14,
      '6': '.eu.ostrzyciel.jelly.core.proto.v1.LogicalStreamType',
      '10': 'logicalType'
    },
    {'1': 'version', '3': 15, '4': 1, '5': 13, '10': 'version'},
  ],
};

/// Descriptor for `RdfStreamOptions`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List rdfStreamOptionsDescriptor = $convert.base64Decode(
    'ChBSZGZTdHJlYW1PcHRpb25zEh8KC3N0cmVhbV9uYW1lGAEgASgJUgpzdHJlYW1OYW1lEloKDX'
    'BoeXNpY2FsX3R5cGUYAiABKA4yNS5ldS5vc3RyenljaWVsLmplbGx5LmNvcmUucHJvdG8udjEu'
    'UGh5c2ljYWxTdHJlYW1UeXBlUgxwaHlzaWNhbFR5cGUSNQoWZ2VuZXJhbGl6ZWRfc3RhdGVtZW'
    '50cxgDIAEoCFIVZ2VuZXJhbGl6ZWRTdGF0ZW1lbnRzEhkKCHJkZl9zdGFyGAQgASgIUgdyZGZT'
    'dGFyEi0KE21heF9uYW1lX3RhYmxlX3NpemUYCSABKA1SEG1heE5hbWVUYWJsZVNpemUSMQoVbW'
    'F4X3ByZWZpeF90YWJsZV9zaXplGAogASgNUhJtYXhQcmVmaXhUYWJsZVNpemUSNQoXbWF4X2Rh'
    'dGF0eXBlX3RhYmxlX3NpemUYCyABKA1SFG1heERhdGF0eXBlVGFibGVTaXplElcKDGxvZ2ljYW'
    'xfdHlwZRgOIAEoDjI0LmV1Lm9zdHJ6eWNpZWwuamVsbHkuY29yZS5wcm90by52MS5Mb2dpY2Fs'
    'U3RyZWFtVHlwZVILbG9naWNhbFR5cGUSGAoHdmVyc2lvbhgPIAEoDVIHdmVyc2lvbg==');

@$core.Deprecated('Use rdfStreamRowDescriptor instead')
const RdfStreamRow$json = {
  '1': 'RdfStreamRow',
  '2': [
    {
      '1': 'options',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.eu.ostrzyciel.jelly.core.proto.v1.RdfStreamOptions',
      '9': 0,
      '10': 'options'
    },
    {
      '1': 'triple',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.eu.ostrzyciel.jelly.core.proto.v1.RdfTriple',
      '9': 0,
      '10': 'triple'
    },
    {
      '1': 'quad',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.eu.ostrzyciel.jelly.core.proto.v1.RdfQuad',
      '9': 0,
      '10': 'quad'
    },
    {
      '1': 'graph_start',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.eu.ostrzyciel.jelly.core.proto.v1.RdfGraphStart',
      '9': 0,
      '10': 'graphStart'
    },
    {
      '1': 'graph_end',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.eu.ostrzyciel.jelly.core.proto.v1.RdfGraphEnd',
      '9': 0,
      '10': 'graphEnd'
    },
    {
      '1': 'namespace',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.eu.ostrzyciel.jelly.core.proto.v1.RdfNamespaceDeclaration',
      '9': 0,
      '10': 'namespace'
    },
    {
      '1': 'name',
      '3': 9,
      '4': 1,
      '5': 11,
      '6': '.eu.ostrzyciel.jelly.core.proto.v1.RdfNameEntry',
      '9': 0,
      '10': 'name'
    },
    {
      '1': 'prefix',
      '3': 10,
      '4': 1,
      '5': 11,
      '6': '.eu.ostrzyciel.jelly.core.proto.v1.RdfPrefixEntry',
      '9': 0,
      '10': 'prefix'
    },
    {
      '1': 'datatype',
      '3': 11,
      '4': 1,
      '5': 11,
      '6': '.eu.ostrzyciel.jelly.core.proto.v1.RdfDatatypeEntry',
      '9': 0,
      '10': 'datatype'
    },
  ],
  '8': [
    {'1': 'row'},
  ],
};

/// Descriptor for `RdfStreamRow`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List rdfStreamRowDescriptor = $convert.base64Decode(
    'CgxSZGZTdHJlYW1Sb3cSTwoHb3B0aW9ucxgBIAEoCzIzLmV1Lm9zdHJ6eWNpZWwuamVsbHkuY2'
    '9yZS5wcm90by52MS5SZGZTdHJlYW1PcHRpb25zSABSB29wdGlvbnMSRgoGdHJpcGxlGAIgASgL'
    'MiwuZXUub3N0cnp5Y2llbC5qZWxseS5jb3JlLnByb3RvLnYxLlJkZlRyaXBsZUgAUgZ0cmlwbG'
    'USQAoEcXVhZBgDIAEoCzIqLmV1Lm9zdHJ6eWNpZWwuamVsbHkuY29yZS5wcm90by52MS5SZGZR'
    'dWFkSABSBHF1YWQSUwoLZ3JhcGhfc3RhcnQYBCABKAsyMC5ldS5vc3RyenljaWVsLmplbGx5Lm'
    'NvcmUucHJvdG8udjEuUmRmR3JhcGhTdGFydEgAUgpncmFwaFN0YXJ0Ek0KCWdyYXBoX2VuZBgF'
    'IAEoCzIuLmV1Lm9zdHJ6eWNpZWwuamVsbHkuY29yZS5wcm90by52MS5SZGZHcmFwaEVuZEgAUg'
    'hncmFwaEVuZBJaCgluYW1lc3BhY2UYBiABKAsyOi5ldS5vc3RyenljaWVsLmplbGx5LmNvcmUu'
    'cHJvdG8udjEuUmRmTmFtZXNwYWNlRGVjbGFyYXRpb25IAFIJbmFtZXNwYWNlEkUKBG5hbWUYCS'
    'ABKAsyLy5ldS5vc3RyenljaWVsLmplbGx5LmNvcmUucHJvdG8udjEuUmRmTmFtZUVudHJ5SABS'
    'BG5hbWUSSwoGcHJlZml4GAogASgLMjEuZXUub3N0cnp5Y2llbC5qZWxseS5jb3JlLnByb3RvLn'
    'YxLlJkZlByZWZpeEVudHJ5SABSBnByZWZpeBJRCghkYXRhdHlwZRgLIAEoCzIzLmV1Lm9zdHJ6'
    'eWNpZWwuamVsbHkuY29yZS5wcm90by52MS5SZGZEYXRhdHlwZUVudHJ5SABSCGRhdGF0eXBlQg'
    'UKA3Jvdw==');

@$core.Deprecated('Use rdfStreamFrameDescriptor instead')
const RdfStreamFrame$json = {
  '1': 'RdfStreamFrame',
  '2': [
    {
      '1': 'rows',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.eu.ostrzyciel.jelly.core.proto.v1.RdfStreamRow',
      '10': 'rows'
    },
    {
      '1': 'metadata',
      '3': 15,
      '4': 3,
      '5': 11,
      '6': '.eu.ostrzyciel.jelly.core.proto.v1.RdfStreamFrame.MetadataEntry',
      '10': 'metadata'
    },
  ],
  '3': [RdfStreamFrame_MetadataEntry$json],
};

@$core.Deprecated('Use rdfStreamFrameDescriptor instead')
const RdfStreamFrame_MetadataEntry$json = {
  '1': 'MetadataEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 12, '10': 'value'},
  ],
  '7': {'7': true},
};

/// Descriptor for `RdfStreamFrame`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List rdfStreamFrameDescriptor = $convert.base64Decode(
    'Cg5SZGZTdHJlYW1GcmFtZRJDCgRyb3dzGAEgAygLMi8uZXUub3N0cnp5Y2llbC5qZWxseS5jb3'
    'JlLnByb3RvLnYxLlJkZlN0cmVhbVJvd1IEcm93cxJbCghtZXRhZGF0YRgPIAMoCzI/LmV1Lm9z'
    'dHJ6eWNpZWwuamVsbHkuY29yZS5wcm90by52MS5SZGZTdHJlYW1GcmFtZS5NZXRhZGF0YUVudH'
    'J5UghtZXRhZGF0YRo7Cg1NZXRhZGF0YUVudHJ5EhAKA2tleRgBIAEoCVIDa2V5EhQKBXZhbHVl'
    'GAIgASgMUgV2YWx1ZToCOAE=');
