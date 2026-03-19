import 'dart:io';
import 'package:locorda_rdf_jelly/src/jelly_frame_decoder.dart';
import 'package:locorda_rdf_jelly/src/proto/rdf.pb.dart';

void main() {
  final outBytes = File(
    '../../test_assets/jelly/jelly-protobuf/test/rdf/to_jelly/triples_rdf_1_1/pos_001/out.jelly',
  ).readAsBytesSync();

  final frames = readDelimitedFrames(outBytes).toList();
  print('frames: ${frames.length}');
  for (var fi = 0; fi < frames.length; fi++) {
    final frame = frames[fi];
    print('\n=== Frame $fi (${frame.rows.length} rows) ===');
    for (final row in frame.rows) {
      final type = row.whichRow();
      switch (type) {
        case RdfStreamRow_Row.options:
          final o = row.options;
          print('  OPTIONS: phys=${o.physicalType} nameMax=${o.maxNameTableSize} '
              'prefixMax=${o.maxPrefixTableSize} dtMax=${o.maxDatatypeTableSize} '
              'ver=${o.version}');
        case RdfStreamRow_Row.name:
          print('  NAME: id=${row.name.id} value="${row.name.value}"');
        case RdfStreamRow_Row.prefix:
          print('  PREFIX: id=${row.prefix.id} value="${row.prefix.value}"');
        case RdfStreamRow_Row.datatype:
          print('  DATATYPE: id=${row.datatype.id} value="${row.datatype.value}"');
        case RdfStreamRow_Row.triple:
          final t = row.triple;
          print('  TRIPLE:');
          if (t.hasSIri()) print('    s_iri: prefix=${t.sIri.prefixId} name=${t.sIri.nameId}');
          if (t.hasSBnode()) print('    s_bnode: ${t.sBnode}');
          if (t.hasPIri()) print('    p_iri: prefix=${t.pIri.prefixId} name=${t.pIri.nameId}');
          if (t.hasOIri()) print('    o_iri: prefix=${t.oIri.prefixId} name=${t.oIri.nameId}');
          if (t.hasOBnode()) print('    o_bnode: ${t.oBnode}');
          if (t.hasOLiteral()) print('    o_literal: "${t.oLiteral.lex}" dt=${t.oLiteral.datatype} lang=${t.oLiteral.langtag}');
          // Check for repeated (no fields set)
          if (!t.hasSIri() && !t.hasSBnode() && !t.hasSLiteral() && !t.hasSTripleTerm()) print('    s: REPEATED');
          if (!t.hasPIri() && !t.hasPBnode() && !t.hasPLiteral() && !t.hasPTripleTerm()) print('    p: REPEATED');
          if (!t.hasOIri() && !t.hasOBnode() && !t.hasOLiteral() && !t.hasOTripleTerm()) print('    o: REPEATED');
        default:
          print('  $type');
      }
    }
  }
}
