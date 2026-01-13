import 'package:rdf_mapper_generator/src/templates/code.dart';
import 'package:rdf_mapper_generator/src/validation/validation_context.dart';
import 'package:test/test.dart';

import '../test_helper.dart';

void main() {
  group('Generic Type Validation Tests', () {
    test(
        'throws ValidationException for generic class with registerGlobally=true',
        () async {
      const sourceCode = '''
import 'package:rdf_mapper_annotations/rdf_mapper_annotations.dart';
import 'package:rdf_vocabularies_core/foaf.dart';

@RdfGlobalResource(
  FoafDocument.classIri,
  IriStrategy('{+documentIri}'),
  registerGlobally: true,
)
class InvalidGenericDocument<T> {
  @RdfIriPart()
  final String documentIri;
  
  @RdfProperty(FoafDocument.primaryTopic)
  final T primaryTopic;

  const InvalidGenericDocument({
    required this.documentIri,
    required this.primaryTopic,
  });
}
''';

      expect(
        () async => await buildTemplateDataFromString(sourceCode),
        throwsA(isA<ValidationException>().having(
          (e) => e.toString(),
          'error message',
          allOf([
            contains('InvalidGenericDocument has generic type parameters'),
            contains('must have registerGlobally set to false'),
            contains('Generic classes cannot be registered globally'),
            contains('they require concrete type parameters'),
          ]),
        )),
      );
    });

    test(
        'throws ValidationException for generic local resource with registerGlobally=true',
        () async {
      const sourceCode = '''
import 'package:rdf_mapper_annotations/rdf_mapper_annotations.dart';
import 'package:rdf_vocabularies_core/foaf.dart';
import 'package:rdf_vocabularies_schema/schema.dart';

@RdfLocalResource(FoafDocument.classIri, true)
class InvalidGenericLocalResource<T> {
  @RdfProperty(FoafDocument.primaryTopic)
  final T value;
  
  @RdfProperty(SchemaThing.name)
  final String label;

  const InvalidGenericLocalResource({
    required this.value,
    required this.label,
  });
}
''';

      expect(
        () async => await buildTemplateDataFromString(sourceCode),
        throwsA(isA<ValidationException>().having(
          (e) => e.toString(),
          'error message',
          allOf([
            contains('InvalidGenericLocalResource has generic type parameters'),
            contains('must have registerGlobally set to false'),
            contains('Generic classes cannot be registered globally'),
          ]),
        )),
      );
    });

    test('succeeds for valid generic class with registerGlobally=false',
        () async {
      const sourceCode = '''
import 'package:rdf_mapper_annotations/rdf_mapper_annotations.dart';
import 'package:rdf_vocabularies_core/foaf.dart';

@RdfGlobalResource(
  FoafDocument.classIri,
  IriStrategy('{+documentIri}'),
  registerGlobally: false,
)
class ValidGenericDocument<T> {
  @RdfIriPart()
  final String documentIri;
  
  @RdfProperty(FoafDocument.primaryTopic)
  final T primaryTopic;

  const ValidGenericDocument({
    required this.documentIri,
    required this.primaryTopic,
  });
}
''';

      // This should NOT throw an exception
      final templateData = await buildTemplateDataFromString(sourceCode);

      // Verify that the template data was generated successfully
      expect(templateData, isNotNull);
      expect(templateData!.mappers, hasLength(1));

      final mapper = templateData.mappers.first;
      var map = mapper.mapperData.toMap();
      expect(Code.fromMap(map['className']).codeWithoutAlias,
          equals('ValidGenericDocument<T>'));
    });

    test('succeeds for valid non-generic class with registerGlobally=true',
        () async {
      const sourceCode = '''
import 'package:rdf_mapper_annotations/rdf_mapper_annotations.dart';
import 'package:rdf_vocabularies_schema/schema.dart';

@RdfGlobalResource(
  SchemaPerson.classIri,
  IriStrategy('http://example.org/persons/{id}'),
  registerGlobally: true,
)
class ValidNonGenericPerson {
  @RdfIriPart()
  final String id;
  
  @RdfProperty(SchemaPerson.name)
  final String name;

  const ValidNonGenericPerson({
    required this.id,
    required this.name,
  });
}
''';

      // This should NOT throw an exception
      final templateData = await buildTemplateDataFromString(sourceCode);

      // Verify that the template data was generated successfully
      expect(templateData, isNotNull);
      expect(templateData!.mappers, hasLength(1));

      final mapper = templateData.mappers.first;
      var map = mapper.mapperData.toMap();
      expect(Code.fromMap(map['className']).codeWithoutAlias,
          equals('ValidNonGenericPerson'));
    });

    test('succeeds for multiple valid generic classes', () async {
      const sourceCode = '''
import 'package:rdf_mapper_annotations/rdf_mapper_annotations.dart';
import 'package:rdf_vocabularies_core/foaf.dart';
import 'package:rdf_vocabularies_schema/schema.dart';

@RdfGlobalResource(
  FoafDocument.classIri,
  IriStrategy('{+documentIri}'),
  registerGlobally: false,
)
class SingleGeneric<T> {
  @RdfIriPart()
  final String documentIri;
  
  @RdfProperty(FoafDocument.primaryTopic)
  final T primaryTopic;

  const SingleGeneric({
    required this.documentIri,
    required this.primaryTopic,
  });
}

@RdfGlobalResource(
  FoafDocument.classIri,
  IriStrategy('{+documentIri}'),
  registerGlobally: false,
)
class MultipleGeneric<T, U, V> {
  @RdfIriPart()
  final String documentIri;
  
  @RdfProperty(FoafDocument.primaryTopic)
  final T primaryTopic;
  
  @RdfProperty(SchemaCreativeWork.author)
  final U author;
  
  @RdfProperty(SchemaCreativeWork.about)
  final V metadata;

  const MultipleGeneric({
    required this.documentIri,
    required this.primaryTopic,
    required this.author,
    required this.metadata,
  });
}
''';

      // This should NOT throw an exception
      final templateData = await buildTemplateDataFromString(sourceCode);

      // Verify that both mappers were generated successfully
      expect(templateData, isNotNull);
      expect(templateData!.mappers, hasLength(2));

      // Check that both mappers contain the expected generic types in their data
      final mapperDataStrings = templateData.mappers
          .map((m) => m.mapperData.toMap().toString())
          .toList();
      expect(mapperDataStrings.any((data) => data.contains('SingleGeneric<T>')),
          isTrue);
      expect(
          mapperDataStrings
              .any((data) => data.contains('MultipleGeneric<T, U, V>')),
          isTrue);
    });
  });
}
