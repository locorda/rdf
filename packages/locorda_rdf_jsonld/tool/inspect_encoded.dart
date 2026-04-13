import 'dart:io';

import 'package:locorda_rdf_core/core.dart';
import 'package:locorda_rdf_jsonld/jsonld.dart';

void main() {
  final trigFile = File('test/assets/realworld/shard-mod-md5-1-0-v1_0_0.trig');
  final dataset = trig.decode(trigFile.readAsStringSync());
  final encoded = jsonld.encode(dataset);
  print('First 500 chars:\n${encoded.substring(0, 500)}\n...');
  print('Number of @graph occurrences: ${'@graph'.allMatches(encoded).length}');
  print('Number of "@id" occurrences: ${'"@id"'.allMatches(encoded).length}');
  print(
      'Number of "@context" occurrences: ${'"@context"'.allMatches(encoded).length}');
}
