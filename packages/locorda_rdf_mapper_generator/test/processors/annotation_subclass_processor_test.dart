// Test that annotation subclassing works correctly at the processor level
import 'package:locorda_rdf_mapper_generator/src/templates/code.dart';
import 'package:test/test.dart';
import '../test_helper.dart';

void main() {
  group('Annotation Subclassing Processor Tests', () {
    test('should recognize CustomGlobalResource as RdfGlobalResource',
        () async {
      const source = '''
import 'package:locorda_rdf_core/core.dart';
import 'package:locorda_rdf_mapper_annotations/annotations.dart';
import 'package:locorda_rdf_terms_schema/schema.dart';

class CustomGlobalResource extends RdfGlobalResource {
  const CustomGlobalResource(
    IriTerm classIri, [
    IriStrategy iriStrategy = const IriStrategy('https://example.com/{id}'),
  ]) : super(classIri, iriStrategy);
}

@CustomGlobalResource(SchemaBook.classIri)
class BookWithCustomAnnotation {
  @RdfIriPart()
  final String id;

  @RdfProperty(SchemaBook.name)
  final String title;

  BookWithCustomAnnotation({required this.id, required this.title});
}
''';

      // The test succeeds if no ValidationException is thrown
      final result = await buildTemplateDataFromString(source);

      expect(result, isNotNull);

      // Verify a mapper was generated
      expect(result!.mappers, isNotEmpty,
          reason: 'Should generate a mapper for BookWithCustomAnnotation');
      expect(result.mappers.length, equals(1));
      final mapper = result.mappers.first;
      final mapperData = mapper.mapperData.toMap();

      expect(Code.fromMap(mapperData['mapperClassName']).codeWithoutAlias,
          equals('BookWithCustomAnnotationMapper'));
      expect(Code.fromMap(mapperData['mapperInterfaceName']).codeWithoutAlias,
          equals('GlobalResourceMapper<BookWithCustomAnnotation>'));
    });

    test('should handle multiple levels of inheritance', () async {
      const source = '''
import 'package:locorda_rdf_core/core.dart';
import 'package:locorda_rdf_mapper_annotations/annotations.dart';
import 'package:locorda_rdf_terms_schema/schema.dart';

class BaseCustomResource extends RdfGlobalResource {
  const BaseCustomResource(IriTerm classIri)
      : super(classIri, const IriStrategy('https://base.example.com/{id}'));
}

class DerivedCustomResource extends BaseCustomResource {
  const DerivedCustomResource(IriTerm classIri) : super(classIri);
}

@DerivedCustomResource(SchemaEvent.classIri)
class EventWithDerivedAnnotation {
  @RdfIriPart()
  final String id;

  @RdfProperty(SchemaEvent.name)
  final String name;

  EventWithDerivedAnnotation({required this.id, required this.name});
}
''';

      // The test succeeds if no ValidationException is thrown
      final result = await buildTemplateDataFromString(source);

      expect(result, isNotNull);

      // Verify a mapper was generated
      expect(result!.mappers, isNotEmpty,
          reason: 'Should generate a mapper for EventWithDerivedAnnotation');
      expect(result.mappers.length, equals(1));
      final mapper = result.mappers.first;
      final mapperData = mapper.mapperData.toMap();
      expect(Code.fromMap(mapperData['mapperClassName']).codeWithoutAlias,
          equals('EventWithDerivedAnnotationMapper'));
      expect(Code.fromMap(mapperData['mapperInterfaceName']).codeWithoutAlias,
          equals('GlobalResourceMapper<EventWithDerivedAnnotation>'));
    });

    test('should work with custom property annotations', () async {
      const source = '''
import 'package:locorda_rdf_core/core.dart';
import 'package:locorda_rdf_mapper_annotations/annotations.dart';
import 'package:locorda_rdf_terms_schema/schema.dart';

class CustomProperty extends RdfProperty {
  const CustomProperty(IriTerm propertyIri) : super(propertyIri);
}

@RdfGlobalResource(
  SchemaBook.classIri,
  IriStrategy('https://example.com/books/{id}'),
)
class BookWithCustomProperty {
  @RdfIriPart()
  final String id;

  @CustomProperty(SchemaBook.name)
  final String title;

  @RdfProperty(SchemaBook.author)
  final String author;

  BookWithCustomProperty({required this.id, required this.title, required this.author});
}
''';

      // The test succeeds if no ValidationException is thrown
      final result = await buildTemplateDataFromString(source);

      expect(result, isNotNull);

      // Verify a mapper was generated with both custom and regular property annotations
      expect(result!.mappers, isNotEmpty,
          reason: 'Should generate a mapper for BookWithCustomProperty');
      final mapper = result.mappers.first;
      final mapperData = mapper.mapperData.toMap();
      expect(Code.fromMap(mapperData['mapperClassName']).codeWithoutAlias,
          equals('BookWithCustomPropertyMapper'));
      expect(Code.fromMap(mapperData['mapperInterfaceName']).codeWithoutAlias,
          equals('GlobalResourceMapper<BookWithCustomProperty>'));

      // Verify that properties using both CustomProperty and RdfProperty were processed
      final properties = mapperData['properties'] as List<dynamic>;
      expect(properties.length, equals(3),
          reason:
              'Should have id (RdfIriPart), title (CustomProperty), and author (RdfProperty) properties');

      final titleProp = properties
          .cast<Map<String, dynamic>>()
          .firstWhere((p) => p['name'] == 'title');
      final authorProp = properties
          .cast<Map<String, dynamic>>()
          .firstWhere((p) => p['name'] == 'author');
      final idProp = properties
          .cast<Map<String, dynamic>>()
          .firstWhere((p) => p['name'] == 'id');

      expect(titleProp, isNotNull,
          reason:
              'Title property with CustomProperty annotation should be found');
      expect(authorProp, isNotNull,
          reason:
              'Author property with regular RdfProperty annotation should be found');
      expect(idProp, isNotNull,
          reason: 'ID property with RdfIriPart annotation should be found');
    });

    test('should still work with regular annotations', () async {
      const source = '''
import 'package:locorda_rdf_core/core.dart';
import 'package:locorda_rdf_mapper_annotations/annotations.dart';
import 'package:locorda_rdf_terms_schema/schema.dart';

@RdfGlobalResource(
  SchemaArticle.classIri,
  IriStrategy('https://example.com/articles/{id}'),
)
class ArticleWithRegularAnnotation {
  @RdfIriPart()
  final String id;

  @RdfProperty(SchemaArticle.name)
  final String title;

  ArticleWithRegularAnnotation({required this.id, required this.title});
}
''';

      // The test succeeds if no ValidationException is thrown
      final result = await buildTemplateDataFromString(source);

      expect(result, isNotNull);

      // Verify a mapper was generated
      expect(result!.mappers, isNotEmpty,
          reason: 'Should generate a mapper for ArticleWithRegularAnnotation');
      final mapper = result.mappers.first;
      final mapperData = mapper.mapperData.toMap();
      expect(Code.fromMap(mapperData['mapperClassName']).codeWithoutAlias,
          equals('ArticleWithRegularAnnotationMapper'));
      expect(Code.fromMap(mapperData['mapperInterfaceName']).codeWithoutAlias,
          equals('GlobalResourceMapper<ArticleWithRegularAnnotation>'));
    });
  });
}
