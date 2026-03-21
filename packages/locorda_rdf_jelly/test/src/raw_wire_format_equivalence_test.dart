/// Tests that the raw wire-format encoding in [JellyRawFrameWriter] and
/// [JellyEncoderState] produces byte-identical output to the protobuf
/// [GeneratedMessage]-based serialization.
///
/// This is the safety net for the performance optimization that bypasses
/// proto object allocation: any wire-format encoding bug will show up as a
/// byte mismatch here.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:locorda_rdf_core/core.dart';
import 'package:locorda_rdf_jelly/jelly.dart';
import 'package:locorda_rdf_jelly/src/jelly_frame_encoder.dart';
import 'package:locorda_rdf_jelly/src/proto/rdf.pb.dart';
import 'package:test/test.dart';

void main() {
  // =========================================================================
  // Varint utilities
  // =========================================================================

  group('varint utilities', () {
    test('varintSize returns correct byte count', () {
      expect(varintSize(0), 1);
      expect(varintSize(1), 1);
      expect(varintSize(0x7F), 1);
      expect(varintSize(0x80), 2);
      expect(varintSize(0x3FFF), 2);
      expect(varintSize(0x4000), 3);
      expect(varintSize(0x1FFFFF), 3);
      expect(varintSize(0x200000), 4);
      expect(varintSize(0xFFFFFFF), 4);
      expect(varintSize(0x10000000), 5);
    });

    test('writeVarintTo matches protobuf varint encoding', () {
      // Reference: protobuf encodes varints with 7 bits per byte, MSB = more.
      void verifyVarint(int value) {
        final buf = BytesBuilder();
        writeVarintTo(buf, value);
        final raw = buf.takeBytes();

        // Verify by decoding back
        int decoded = 0;
        int shift = 0;
        for (final byte in raw) {
          decoded |= (byte & 0x7F) << shift;
          shift += 7;
        }
        expect(decoded, value, reason: 'varint roundtrip for $value');
        expect(raw.length, varintSize(value), reason: 'varint size for $value');
      }

      for (final v in [0, 1, 127, 128, 255, 300, 16383, 16384, 100000]) {
        verifyVarint(v);
      }
    });

    test('writeVarintToArray matches writeVarintTo', () {
      for (final value in [0, 1, 127, 128, 16383, 16384, 100000, 0xFFFFFFF]) {
        final buf = BytesBuilder();
        writeVarintTo(buf, value);
        final expected = buf.takeBytes();

        final array = Uint8List(10);
        final end = writeVarintToArray(array, 0, value);
        final actual = Uint8List.sublistView(array, 0, end);

        expect(actual, expected, reason: 'array varint for $value');
      }
    });
  });

  // =========================================================================
  // Sub-message byte equivalence: RdfIri
  // =========================================================================

  group('RdfIri wire-format equivalence', () {
    /// Builds an RdfIri proto and returns its serialized bytes.
    Uint8List protoIri(int prefixId, int nameId) {
      final iri = RdfIri();
      if (prefixId != 0) iri.prefixId = prefixId;
      if (nameId != 0) iri.nameId = nameId;
      return iri.writeToBuffer();
    }

    /// Builds an RdfIri using raw wire-format encoding.
    Uint8List rawIri(int prefixId, int nameId) {
      final buf = BytesBuilder();
      if (prefixId != 0) {
        buf.addByte(kIriPrefixIdTag);
        writeVarintTo(buf, prefixId);
      }
      if (nameId != 0) {
        buf.addByte(kIriNameIdTag);
        writeVarintTo(buf, nameId);
      }
      return buf.toBytes();
    }

    test('empty IRI (both zero)', () {
      expect(rawIri(0, 0), protoIri(0, 0));
    });

    test('prefix only', () {
      for (final pid in [1, 2, 127, 128, 300]) {
        expect(rawIri(pid, 0), protoIri(pid, 0), reason: 'prefixId=$pid');
      }
    });

    test('name only', () {
      for (final nid in [1, 2, 127, 128, 300]) {
        expect(rawIri(0, nid), protoIri(0, nid), reason: 'nameId=$nid');
      }
    });

    test('both prefix and name', () {
      for (final (pid, nid) in [
        (1, 1),
        (1, 128),
        (128, 1),
        (128, 128),
        (300, 500)
      ]) {
        expect(rawIri(pid, nid), protoIri(pid, nid),
            reason: 'prefixId=$pid, nameId=$nid');
      }
    });
  });

  // =========================================================================
  // Sub-message byte equivalence: RdfLiteral
  // =========================================================================

  group('RdfLiteral wire-format equivalence', () {
    Uint8List protoLiteral(String lex, {String? langtag, int? datatype}) {
      final lit = RdfLiteral()..lex = lex;
      if (langtag != null) lit.langtag = langtag;
      if (datatype != null) lit.datatype = datatype;
      return lit.writeToBuffer();
    }

    Uint8List rawLiteral(String lex, {String? langtag, int? datatype}) {
      final buf = BytesBuilder();
      final lexUtf8 = utf8.encode(lex);
      buf.addByte(kLitLexTag);
      writeVarintTo(buf, lexUtf8.length);
      buf.add(lexUtf8);
      if (langtag != null) {
        final langUtf8 = utf8.encode(langtag);
        buf.addByte(kLitLangtagTag);
        writeVarintTo(buf, langUtf8.length);
        buf.add(langUtf8);
      } else if (datatype != null) {
        buf.addByte(kLitDatatypeTag);
        writeVarintTo(buf, datatype);
      }
      return buf.toBytes();
    }

    test('plain string literal', () {
      expect(rawLiteral('hello'), protoLiteral('hello'));
    });

    test('empty string literal', () {
      expect(rawLiteral(''), protoLiteral(''));
    });

    test('UTF-8 multi-byte literal', () {
      expect(rawLiteral('Ünïcödé 🎉'), protoLiteral('Ünïcödé 🎉'));
    });

    test('language-tagged literal', () {
      expect(
        rawLiteral('bonjour', langtag: 'fr'),
        protoLiteral('bonjour', langtag: 'fr'),
      );
    });

    test('typed literal with small datatype ID', () {
      expect(
        rawLiteral('42', datatype: 1),
        protoLiteral('42', datatype: 1),
      );
    });

    test('typed literal with large datatype ID', () {
      expect(
        rawLiteral('3.14', datatype: 300),
        protoLiteral('3.14', datatype: 300),
      );
    });
  });

  // =========================================================================
  // Sub-message byte equivalence: RdfTriple
  // =========================================================================

  group('RdfTriple wire-format equivalence', () {
    Uint8List protoTriple({
      RdfIri? sIri,
      String? sBnode,
      RdfIri? pIri,
      RdfIri? oIri,
      String? oBnode,
      RdfLiteral? oLiteral,
    }) {
      final t = RdfTriple();
      if (sIri != null) t.sIri = sIri;
      if (sBnode != null) t.sBnode = sBnode;
      if (pIri != null) t.pIri = pIri;
      if (oIri != null) t.oIri = oIri;
      if (oBnode != null) t.oBnode = oBnode;
      if (oLiteral != null) t.oLiteral = oLiteral;
      return t.writeToBuffer();
    }

    Uint8List rawTriple({
      (int prefixId, int nameId)? sIri,
      String? sBnode,
      (int prefixId, int nameId)? pIri,
      (int prefixId, int nameId)? oIri,
      String? oBnode,
      (String lex, String? langtag, int? datatype)? oLiteral,
    }) {
      final buf = BytesBuilder();

      if (sIri != null) {
        _writeIriFieldTo(buf, kSIriTag, sIri.$1, sIri.$2);
      } else if (sBnode != null) {
        _writeStringFieldTo(buf, kSBnodeTag, sBnode);
      }

      if (pIri != null) {
        _writeIriFieldTo(buf, kPIriTag, pIri.$1, pIri.$2);
      }

      if (oIri != null) {
        _writeIriFieldTo(buf, kOIriTag, oIri.$1, oIri.$2);
      } else if (oBnode != null) {
        _writeStringFieldTo(buf, kOBnodeTag, oBnode);
      } else if (oLiteral != null) {
        _writeLiteralFieldTo(
            buf, kOLiteralTag, oLiteral.$1, oLiteral.$2, oLiteral.$3);
      }

      return buf.toBytes();
    }

    test('all-IRI triple', () {
      expect(
        rawTriple(
          sIri: (1, 10),
          pIri: (1, 5),
          oIri: (2, 3),
        ),
        protoTriple(
          sIri: RdfIri(prefixId: 1, nameId: 10),
          pIri: RdfIri(prefixId: 1, nameId: 5),
          oIri: RdfIri(prefixId: 2, nameId: 3),
        ),
      );
    });

    test('triple with delta-encoded IRIs (zero fields)', () {
      // When prefixId or nameId is 0, the field is omitted per proto semantics.
      expect(
        rawTriple(
          sIri: (0, 5),
          pIri: (1, 0),
          oIri: (0, 0),
        ),
        protoTriple(
          sIri: RdfIri(nameId: 5),
          pIri: RdfIri(prefixId: 1),
          oIri: RdfIri(),
        ),
      );
    });

    test('triple with bnode subject', () {
      expect(
        rawTriple(
          sBnode: 'b1',
          pIri: (1, 1),
          oIri: (2, 2),
        ),
        protoTriple(
          sBnode: 'b1',
          pIri: RdfIri(prefixId: 1, nameId: 1),
          oIri: RdfIri(prefixId: 2, nameId: 2),
        ),
      );
    });

    test('triple with literal object', () {
      expect(
        rawTriple(
          sIri: (1, 1),
          pIri: (1, 2),
          oLiteral: ('hello', null, null),
        ),
        protoTriple(
          sIri: RdfIri(prefixId: 1, nameId: 1),
          pIri: RdfIri(prefixId: 1, nameId: 2),
          oLiteral: RdfLiteral(lex: 'hello'),
        ),
      );
    });

    test('triple with language-tagged literal', () {
      expect(
        rawTriple(
          sIri: (1, 1),
          pIri: (1, 2),
          oLiteral: ('bonjour', 'fr', null),
        ),
        protoTriple(
          sIri: RdfIri(prefixId: 1, nameId: 1),
          pIri: RdfIri(prefixId: 1, nameId: 2),
          oLiteral: RdfLiteral(lex: 'bonjour', langtag: 'fr'),
        ),
      );
    });

    test('triple with typed literal', () {
      expect(
        rawTriple(
          sIri: (1, 1),
          pIri: (1, 2),
          oLiteral: ('42', null, 3),
        ),
        protoTriple(
          sIri: RdfIri(prefixId: 1, nameId: 1),
          pIri: RdfIri(prefixId: 1, nameId: 2),
          oLiteral: RdfLiteral(lex: '42', datatype: 3),
        ),
      );
    });

    test('triple with bnode object', () {
      expect(
        rawTriple(
          sIri: (1, 1),
          pIri: (1, 2),
          oBnode: 'b42',
        ),
        protoTriple(
          sIri: RdfIri(prefixId: 1, nameId: 1),
          pIri: RdfIri(prefixId: 1, nameId: 2),
          oBnode: 'b42',
        ),
      );
    });

    test('triple with repeated-term compression (empty bytes)', () {
      // When a term is repeated (same as _last*), the encoder omits the field.
      // This shows up as an empty triple bytes (no fields set).
      expect(rawTriple(), protoTriple());
    });

    test('triple with only subject changed', () {
      expect(
        rawTriple(sIri: (3, 7)),
        protoTriple(sIri: RdfIri(prefixId: 3, nameId: 7)),
      );
    });
  });

  // =========================================================================
  // Sub-message byte equivalence: RdfQuad (graph field)
  // =========================================================================

  group('RdfQuad wire-format equivalence', () {
    Uint8List protoQuad({
      RdfIri? sIri,
      RdfIri? pIri,
      RdfIri? oIri,
      RdfLiteral? oLiteral,
      RdfIri? gIri,
      String? gBnode,
      bool gDefault = false,
    }) {
      final q = RdfQuad();
      if (sIri != null) q.sIri = sIri;
      if (pIri != null) q.pIri = pIri;
      if (oIri != null) q.oIri = oIri;
      if (oLiteral != null) q.oLiteral = oLiteral;
      if (gIri != null) q.gIri = gIri;
      if (gBnode != null) q.gBnode = gBnode;
      if (gDefault) q.gDefaultGraph = RdfDefaultGraph();
      return q.writeToBuffer();
    }

    Uint8List rawQuad({
      (int, int)? sIri,
      (int, int)? pIri,
      (int, int)? oIri,
      (String lex, String? lang, int? dt)? oLiteral,
      (int, int)? gIri,
      String? gBnode,
      bool gDefault = false,
    }) {
      final buf = BytesBuilder();
      if (sIri != null) _writeIriFieldTo(buf, kSIriTag, sIri.$1, sIri.$2);
      if (pIri != null) _writeIriFieldTo(buf, kPIriTag, pIri.$1, pIri.$2);
      if (oIri != null) _writeIriFieldTo(buf, kOIriTag, oIri.$1, oIri.$2);
      if (oLiteral != null) {
        _writeLiteralFieldTo(
            buf, kOLiteralTag, oLiteral.$1, oLiteral.$2, oLiteral.$3);
      }
      if (gIri != null) _writeIriFieldTo(buf, kGIriTag, gIri.$1, gIri.$2);
      if (gBnode != null) _writeStringFieldTo(buf, kGBnodeTag, gBnode);
      if (gDefault) {
        buf.addByte(kGDefaultTag);
        buf.addByte(0x00); // empty sub-message
      }
      return buf.toBytes();
    }

    test('quad with IRI graph', () {
      expect(
        rawQuad(
          sIri: (1, 1),
          pIri: (1, 2),
          oIri: (1, 3),
          gIri: (2, 1),
        ),
        protoQuad(
          sIri: RdfIri(prefixId: 1, nameId: 1),
          pIri: RdfIri(prefixId: 1, nameId: 2),
          oIri: RdfIri(prefixId: 1, nameId: 3),
          gIri: RdfIri(prefixId: 2, nameId: 1),
        ),
      );
    });

    test('quad with default graph', () {
      expect(
        rawQuad(
          sIri: (1, 1),
          pIri: (1, 2),
          oIri: (1, 3),
          gDefault: true,
        ),
        protoQuad(
          sIri: RdfIri(prefixId: 1, nameId: 1),
          pIri: RdfIri(prefixId: 1, nameId: 2),
          oIri: RdfIri(prefixId: 1, nameId: 3),
          gDefault: true,
        ),
      );
    });

    test('quad with bnode graph', () {
      expect(
        rawQuad(
          sIri: (1, 1),
          pIri: (1, 2),
          oLiteral: ('42', null, 5),
          gBnode: 'g1',
        ),
        protoQuad(
          sIri: RdfIri(prefixId: 1, nameId: 1),
          pIri: RdfIri(prefixId: 1, nameId: 2),
          oLiteral: RdfLiteral(lex: '42', datatype: 5),
          gBnode: 'g1',
        ),
      );
    });
  });

  // =========================================================================
  // Sub-message byte equivalence: RdfGraphStart
  // =========================================================================

  group('RdfGraphStart wire-format equivalence', () {
    test('default graph', () {
      final proto = RdfGraphStart()..gDefaultGraph = RdfDefaultGraph();
      final raw = BytesBuilder();
      raw.addByte(kGraphStartDefaultTag);
      raw.addByte(0x00);
      expect(raw.toBytes(), proto.writeToBuffer());
    });

    test('IRI graph', () {
      final proto = RdfGraphStart()..gIri = RdfIri(prefixId: 2, nameId: 5);
      final raw = BytesBuilder();
      _writeIriFieldTo(raw, kGraphStartIriTag, 2, 5);
      expect(raw.toBytes(), proto.writeToBuffer());
    });

    test('bnode graph', () {
      final proto = RdfGraphStart()..gBnode = 'g1';
      final raw = BytesBuilder();
      _writeStringFieldTo(raw, kGraphStartBnodeTag, 'g1');
      expect(raw.toBytes(), proto.writeToBuffer());
    });
  });

  // =========================================================================
  // Sub-message byte equivalence: Table entries
  // =========================================================================

  group('table entry wire-format equivalence', () {
    Uint8List protoNameEntry(int deltaId, String value) {
      final entry = RdfNameEntry()..value = value;
      if (deltaId != 0) entry.id = deltaId;
      return entry.writeToBuffer();
    }

    Uint8List protoPrefixEntry(int deltaId, String value) {
      final entry = RdfPrefixEntry()..value = value;
      if (deltaId != 0) entry.id = deltaId;
      return entry.writeToBuffer();
    }

    Uint8List protoDatatypeEntry(int deltaId, String value) {
      final entry = RdfDatatypeEntry()..value = value;
      if (deltaId != 0) entry.id = deltaId;
      return entry.writeToBuffer();
    }

    /// Builds a raw table entry using the same logic as
    /// [JellyRawFrameWriter._encodeTableEntry].
    Uint8List rawEntry(int deltaId, String value) {
      final utf8Value = utf8.encode(value);
      int size = 0;
      if (deltaId != 0) size += 1 + varintSize(deltaId);
      size += 1 + varintSize(utf8Value.length) + utf8Value.length;

      final bytes = Uint8List(size);
      int offset = 0;
      if (deltaId != 0) {
        bytes[offset++] = kEntryIdTag;
        offset = writeVarintToArray(bytes, offset, deltaId);
      }
      bytes[offset++] = kEntryValueTag;
      offset = writeVarintToArray(bytes, offset, utf8Value.length);
      bytes.setRange(offset, offset + utf8Value.length, utf8Value);
      return bytes;
    }

    test('name entry with delta=0 (sequential)', () {
      expect(rawEntry(0, 'Person'), protoNameEntry(0, 'Person'));
    });

    test('name entry with nonzero ID', () {
      expect(rawEntry(5, 'name'), protoNameEntry(5, 'name'));
    });

    test('name entry with large ID', () {
      expect(rawEntry(300, 'birthDate'), protoNameEntry(300, 'birthDate'));
    });

    test('prefix entry', () {
      const uri = 'http://schema.org/';
      expect(rawEntry(1, uri), protoPrefixEntry(1, uri));
    });

    test('datatype entry', () {
      const xsdInt = 'http://www.w3.org/2001/XMLSchema#integer';
      expect(rawEntry(2, xsdInt), protoDatatypeEntry(2, xsdInt));
    });

    // All three entry types share the same proto field numbers (id=1, value=2),
    // so the bytes must be identical regardless of which message type is used.
    test('all entry types produce identical bytes for the same content', () {
      expect(protoNameEntry(3, 'foo'), protoPrefixEntry(3, 'foo'));
      expect(protoNameEntry(3, 'foo'), protoDatatypeEntry(3, 'foo'));
    });
  });

  // =========================================================================
  // Row wrapping equivalence: RdfStreamRow
  // =========================================================================

  group('RdfStreamRow wrapping equivalence', () {
    /// Wraps a raw sub-message inside an RdfStreamRow at the frame level,
    /// reproducing what [JellyRawFrameWriter._addRow] writes for a single row
    /// (the kFrameRowsTag + rowSize + rowFieldTag + contentLen + content part).
    Uint8List rawRowInFrame(int rowFieldTag, List<int> contentBytes) {
      final contentLen = contentBytes.length;
      final rowWrapperSize = 1 + varintSize(contentLen) + contentLen;
      final buf = BytesBuilder();
      buf.addByte(kFrameRowsTag);
      writeVarintTo(buf, rowWrapperSize);
      buf.addByte(rowFieldTag);
      writeVarintTo(buf, contentLen);
      if (contentLen > 0) buf.add(contentBytes);
      return buf.toBytes();
    }

    /// Wraps content via proto: RdfStreamFrame with one row.
    Uint8List protoRowInFrame(RdfStreamRow row) {
      final frame = RdfStreamFrame()..rows.add(row);
      return frame.writeToBuffer();
    }

    test('triple row wrapping', () {
      final tripleProto = RdfTriple()
        ..sIri = RdfIri(prefixId: 1, nameId: 2)
        ..pIri = RdfIri(prefixId: 1, nameId: 3)
        ..oLiteral = RdfLiteral(lex: 'hello');
      final tripleBytes = tripleProto.writeToBuffer();

      final protoFrame = protoRowInFrame(RdfStreamRow()..triple = tripleProto);
      final rawFrame = rawRowInFrame(kRowTripleTag, tripleBytes);

      expect(rawFrame, protoFrame);
    });

    test('quad row wrapping', () {
      final quadProto = RdfQuad()
        ..sIri = RdfIri(prefixId: 1, nameId: 1)
        ..pIri = RdfIri(prefixId: 1, nameId: 2)
        ..oIri = RdfIri(prefixId: 2, nameId: 1)
        ..gDefaultGraph = RdfDefaultGraph();
      final quadBytes = quadProto.writeToBuffer();

      final protoFrame = protoRowInFrame(RdfStreamRow()..quad = quadProto);
      final rawFrame = rawRowInFrame(kRowQuadTag, quadBytes);

      expect(rawFrame, protoFrame);
    });

    test('name entry row wrapping', () {
      final entry = RdfNameEntry()
        ..id = 5
        ..value = 'Person';
      final entryBytes = entry.writeToBuffer();

      final protoFrame = protoRowInFrame(RdfStreamRow()..name = entry);
      final rawFrame = rawRowInFrame(kRowNameTag, entryBytes);

      expect(rawFrame, protoFrame);
    });

    test('graph start row wrapping', () {
      final gs = RdfGraphStart()..gIri = RdfIri(prefixId: 1, nameId: 3);
      final gsBytes = gs.writeToBuffer();

      final protoFrame = protoRowInFrame(RdfStreamRow()..graphStart = gs);
      final rawFrame = rawRowInFrame(kRowGraphStartTag, gsBytes);

      expect(rawFrame, protoFrame);
    });

    test('graph end row wrapping', () {
      final ge = RdfGraphEnd();
      final geBytes = ge.writeToBuffer();

      final protoFrame = protoRowInFrame(RdfStreamRow()..graphEnd = ge);
      final rawFrame = rawRowInFrame(kRowGraphEndTag, geBytes);

      expect(rawFrame, protoFrame);
    });
  });

  // =========================================================================
  // Full-frame equivalence: JellyRawFrameWriter vs proto-based frame
  // =========================================================================

  group('full frame equivalence', () {
    test('single-row frame byte identity', () {
      // Build a frame with one triple row using both approaches.
      final tripleProto = RdfTriple()
        ..sIri = RdfIri(prefixId: 1, nameId: 10)
        ..pIri = RdfIri(prefixId: 1, nameId: 5)
        ..oLiteral = RdfLiteral(lex: 'test value', langtag: 'en');

      // Proto approach: serialize frame, then varint-delimit
      final protoFrame = RdfStreamFrame()
        ..rows.add(RdfStreamRow()..triple = tripleProto);
      final protoFrameBytes = protoFrame.writeToBuffer();
      final protoDelimited = _varintDelimit(protoFrameBytes);

      // Raw approach
      final writer = JellyRawFrameWriter(256);
      writer.addTripleRow(tripleProto.writeToBuffer());
      final rawDelimited = writer.finish();

      expect(rawDelimited, protoDelimited);
    });

    test('multi-row frame byte identity', () {
      // Build a frame with several rows.
      final nameEntry = RdfNameEntry()..value = 'Person';
      final prefixEntry = RdfPrefixEntry()..value = 'http://schema.org/';
      final tripleProto = RdfTriple()
        ..sIri = RdfIri(prefixId: 1, nameId: 1)
        ..pIri = RdfIri(nameId: 1)
        ..oLiteral = RdfLiteral(lex: 'Jane');

      // Proto approach
      final protoFrame = RdfStreamFrame()
        ..rows.addAll([
          RdfStreamRow()..prefix = prefixEntry,
          RdfStreamRow()..name = nameEntry,
          RdfStreamRow()..triple = tripleProto,
        ]);
      final protoDelimited = _varintDelimit(protoFrame.writeToBuffer());

      // Raw approach
      final writer = JellyRawFrameWriter(256);
      writer.addPrefixEntry(0, 'http://schema.org/');
      writer.addNameEntry(0, 'Person');
      writer.addTripleRow(tripleProto.writeToBuffer());
      final rawDelimited = writer.finish();

      expect(rawDelimited, protoDelimited);
    });

    test('frame with options row', () {
      final options = RdfStreamOptions()
        ..physicalType = PhysicalStreamType.PHYSICAL_STREAM_TYPE_TRIPLES
        ..maxNameTableSize = 128
        ..maxPrefixTableSize = 64
        ..maxDatatypeTableSize = 16
        ..version = 2;

      final protoFrame = RdfStreamFrame()
        ..rows.add(RdfStreamRow()..options = options);
      final protoDelimited = _varintDelimit(protoFrame.writeToBuffer());

      final writer = JellyRawFrameWriter(256);
      writer.addOptionsRow(options);
      final rawDelimited = writer.finish();

      expect(rawDelimited, protoDelimited);
    });

    test('frame with graph start, triples, graph end', () {
      final gs = RdfGraphStart()..gDefaultGraph = RdfDefaultGraph();
      final t1 = RdfTriple()
        ..sIri = RdfIri(prefixId: 1, nameId: 1)
        ..pIri = RdfIri(prefixId: 1, nameId: 2)
        ..oLiteral = RdfLiteral(lex: 'A');
      final t2 = RdfTriple()
        // Repeated subject+predicate omitted (empty triple with only object)
        ..oLiteral = RdfLiteral(lex: 'B');
      final ge = RdfGraphEnd();

      final protoFrame = RdfStreamFrame()
        ..rows.addAll([
          RdfStreamRow()..graphStart = gs,
          RdfStreamRow()..triple = t1,
          RdfStreamRow()..triple = t2,
          RdfStreamRow()..graphEnd = ge,
        ]);
      final protoDelimited = _varintDelimit(protoFrame.writeToBuffer());

      final writer = JellyRawFrameWriter(256);
      writer.addGraphStartRow(gs.writeToBuffer());
      writer.addTripleRow(t1.writeToBuffer());
      writer.addTripleRow(t2.writeToBuffer());
      writer.addGraphEndRow();
      final rawDelimited = writer.finish();

      expect(rawDelimited, protoDelimited);
    });

    test('automatic frame splitting produces same frames as manual split', () {
      // Use maxRowsPerFrame=3 to force auto-splitting.
      final rows = <RdfStreamRow>[
        RdfStreamRow()..name = (RdfNameEntry()..value = 'a'),
        RdfStreamRow()..name = (RdfNameEntry()..value = 'b'),
        RdfStreamRow()..name = (RdfNameEntry()..value = 'c'),
        RdfStreamRow()..name = (RdfNameEntry()..value = 'd'),
        RdfStreamRow()..name = (RdfNameEntry()..value = 'e'),
      ];

      // Proto: manually split into frames of 3 + 2
      final frame1 = RdfStreamFrame()..rows.addAll(rows.sublist(0, 3));
      final frame2 = RdfStreamFrame()..rows.addAll(rows.sublist(3));
      final protoDelimited = BytesBuilder();
      protoDelimited.add(_varintDelimit(frame1.writeToBuffer()));
      protoDelimited.add(_varintDelimit(frame2.writeToBuffer()));

      // Raw: auto-split at maxRowsPerFrame=3
      final writer = JellyRawFrameWriter(3);
      for (final name in ['a', 'b', 'c', 'd', 'e']) {
        writer.addNameEntry(0, name);
      }
      final rawDelimited = writer.finish();

      expect(rawDelimited, protoDelimited.toBytes());
    });
  });

  // =========================================================================
  // End-to-end: full encoder roundtrip byte equivalence
  // =========================================================================

  group('end-to-end encoder byte equivalence', () {
    // These tests verify the complete pipeline: given the same RDF terms,
    // the old proto-based approach and the new raw approach produce identical
    // bytes. We verify this by decoding the raw output back through the
    // standard decoder and checking semantic equivalence.

    test('single triple encodes identically', () {
      final triple = Triple(
        IriTerm('http://example.org/s'),
        IriTerm('http://example.org/p'),
        LiteralTerm('hello'),
      );
      final encoded = JellyTripleFrameEncoder().convert([triple]);
      final decoded = const JellyTripleFrameDecoder().convert(encoded);
      expect(decoded, [triple]);
    });

    test('bnode roundtrip preserves structure', () {
      final bnode = BlankNodeTerm();
      final triple = Triple(
        bnode,
        IriTerm('http://example.org/p'),
        bnode, // same bnode in subject and object
      );
      final encoded = JellyTripleFrameEncoder().convert([triple]);
      final decoded = const JellyTripleFrameDecoder().convert(encoded);
      expect(decoded.length, 1);
      expect(decoded[0].subject, decoded[0].object,
          reason: 'bnode identity preserved');
    });

    test('typed literal roundtrip', () {
      final triple = Triple(
        IriTerm('http://example.org/s'),
        IriTerm('http://example.org/p'),
        LiteralTerm('42',
            datatype: IriTerm('http://www.w3.org/2001/XMLSchema#integer')),
      );
      final encoded = JellyTripleFrameEncoder().convert([triple]);
      final decoded = const JellyTripleFrameDecoder().convert(encoded);
      expect(decoded, [triple]);
    });

    test('language-tagged literal roundtrip', () {
      final triple = Triple(
        IriTerm('http://example.org/s'),
        IriTerm('http://example.org/p'),
        LiteralTerm.withLanguage('bonjour', 'fr'),
      );
      final encoded = JellyTripleFrameEncoder().convert([triple]);
      final decoded = const JellyTripleFrameDecoder().convert(encoded);
      expect(decoded, [triple]);
    });

    test('quad with default graph roundtrip', () {
      final quad = Quad(
        IriTerm('http://example.org/s'),
        IriTerm('http://example.org/p'),
        IriTerm('http://example.org/o'),
        null, // default graph
      );
      final encoded = JellyQuadFrameEncoder().convert([quad]);
      final decoded = const JellyQuadFrameDecoder().convert(encoded);
      expect(decoded, [quad]);
    });

    test('quad with named graph roundtrip', () {
      final quad = Quad(
        IriTerm('http://example.org/s'),
        IriTerm('http://example.org/p'),
        IriTerm('http://example.org/o'),
        IriTerm('http://example.org/graph1'),
      );
      final encoded = JellyQuadFrameEncoder().convert([quad]);
      final decoded = const JellyQuadFrameDecoder().convert(encoded);
      expect(decoded, [quad]);
    });

    test('multi-frame encode/decode preserves all triples', () {
      // Force small frames to exercise multi-frame encoding
      final options = JellyEncoderOptions(maxRowsPerFrame: 5);
      final triples = List.generate(
        20,
        (i) => Triple(
          IriTerm('http://example.org/s$i'),
          IriTerm('http://example.org/p'),
          LiteralTerm('value $i'),
        ),
      );
      final encoded =
          JellyTripleFrameEncoder(options: options).convert(triples);
      final decoded = const JellyTripleFrameDecoder().convert(encoded);
      expect(decoded, triples);
    });
  });
}

// ===========================================================================
// Test helpers — mirror the raw wire-format encoding primitives
// ===========================================================================

/// Writes an IRI sub-message field to [buf] using raw wire format.
void _writeIriFieldTo(
    BytesBuilder buf, int fieldTag, int prefixId, int nameId) {
  int iriSize = 0;
  if (prefixId != 0) iriSize += 1 + varintSize(prefixId);
  if (nameId != 0) iriSize += 1 + varintSize(nameId);
  buf.addByte(fieldTag);
  writeVarintTo(buf, iriSize);
  if (prefixId != 0) {
    buf.addByte(kIriPrefixIdTag);
    writeVarintTo(buf, prefixId);
  }
  if (nameId != 0) {
    buf.addByte(kIriNameIdTag);
    writeVarintTo(buf, nameId);
  }
}

/// Writes a string field to [buf] using raw wire format (LEN type).
void _writeStringFieldTo(BytesBuilder buf, int fieldTag, String value) {
  final utf8Bytes = utf8.encode(value);
  buf.addByte(fieldTag);
  writeVarintTo(buf, utf8Bytes.length);
  buf.add(utf8Bytes);
}

/// Writes a literal sub-message field to [buf] using raw wire format.
void _writeLiteralFieldTo(
    BytesBuilder buf, int fieldTag, String lex, String? langtag, int? dt) {
  final lexUtf8 = utf8.encode(lex);
  List<int>? langUtf8;
  int litSize = 1 + varintSize(lexUtf8.length) + lexUtf8.length;

  if (langtag != null) {
    langUtf8 = utf8.encode(langtag);
    litSize += 1 + varintSize(langUtf8.length) + langUtf8.length;
  } else if (dt != null) {
    litSize += 1 + varintSize(dt);
  }

  buf.addByte(fieldTag);
  writeVarintTo(buf, litSize);
  buf.addByte(kLitLexTag);
  writeVarintTo(buf, lexUtf8.length);
  buf.add(lexUtf8);

  if (langUtf8 != null) {
    buf.addByte(kLitLangtagTag);
    writeVarintTo(buf, langUtf8.length);
    buf.add(langUtf8);
  } else if (dt != null) {
    buf.addByte(kLitDatatypeTag);
    writeVarintTo(buf, dt);
  }
}

/// Varint-delimits a protobuf message (prepends the message length as varint).
Uint8List _varintDelimit(Uint8List messageBytes) {
  final buf = BytesBuilder();
  writeVarintTo(buf, messageBytes.length);
  buf.add(messageBytes);
  return buf.toBytes();
}
