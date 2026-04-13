import 'dart:io';

import 'package:locorda_rdf_canonicalization/canonicalization.dart';
import 'package:locorda_rdf_core/core.dart';
import 'package:locorda_rdf_jsonld/jsonld.dart';

void main() {
  final trigFile = File('test/assets/realworld/shard-mod-md5-1-0-v1_0_0.trig');
  if (!trigFile.existsSync()) {
    print('shard.trig not found at ${trigFile.path}');
    return;
  }

  var sw = Stopwatch()..start();
  final dataset = trig.decode(trigFile.readAsStringSync());
  print(
      'trig.decode:   ${sw.elapsedMilliseconds}ms, ${dataset.quads.length} quads');

  sw.reset();
  final encoded = jsonld.encode(dataset);
  print('jsonld.encode: ${sw.elapsedMilliseconds}ms, ${encoded.length} chars');

  sw.reset();
  final decoded = jsonld.decode(encoded);
  print(
      'jsonld.decode: ${sw.elapsedMilliseconds}ms, ${decoded.quads.length} quads');

  sw.reset();
  final result = isIsomorphic(dataset, decoded);
  print('isIsomorphic:  ${sw.elapsedMilliseconds}ms, result: $result');
}
