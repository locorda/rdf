import 'package:locorda_rdf_core/core.dart';
import 'package:locorda_rdf_mapper/mapper.dart';
import 'package:locorda_rdf_mapper/src/context/deserialization_context_impl.dart';
import 'package:locorda_rdf_mapper/src/context/serialization_context_impl.dart';
import 'package:test/test.dart';

// Import test models
import '../../fixtures/locorda_rdf_mapper_annotations/examples/enum_mapping_simple.dart';
// Import generated mappers
import '../../fixtures/locorda_rdf_mapper_annotations/examples/enum_mapping_simple.rdf_mapper.g.dart';
import '../init_test_rdf_mapper_util.dart';

void main() {
  late RdfMapper mapper;

  /// Helper to create serialization context
  SerializationContext createSerializationContext() {
    return SerializationContextImpl(registry: mapper.registry);
  }

  /// Helper to create deserialization context
  DeserializationContext createDeserializationContext() {
    final graph = RdfGraph.fromTriples([]);
    return DeserializationContextImpl(graph: graph, registry: mapper.registry);
  }

  setUp(() {
    mapper = defaultInitTestRdfMapper();
  });

  group('Enum Mapping Simple Test', () {
    group('BookFormat enum (literal)', () {
      test('serializes all enum values correctly', () {
        const mapper = BookFormatMapper();
        final context = createSerializationContext();

        final hardcoverTerm = mapper.toRdfTerm(BookFormat.hardcover, context);
        expect(hardcoverTerm, isA<LiteralTerm>());
        expect(hardcoverTerm.value, equals('hardcover'));

        final paperbackTerm = mapper.toRdfTerm(BookFormat.paperback, context);
        expect(paperbackTerm, isA<LiteralTerm>());
        expect(paperbackTerm.value, equals('paperback'));

        final ebookTerm = mapper.toRdfTerm(BookFormat.ebook, context);
        expect(ebookTerm, isA<LiteralTerm>());
        expect(ebookTerm.value, equals('ebook'));
      });

      test('deserializes all enum values correctly', () {
        const mapper = BookFormatMapper();
        final context = createDeserializationContext();

        final hardcover = mapper.fromRdfTerm(LiteralTerm('hardcover'), context);
        expect(hardcover, equals(BookFormat.hardcover));

        final paperback = mapper.fromRdfTerm(LiteralTerm('paperback'), context);
        expect(paperback, equals(BookFormat.paperback));

        final ebook = mapper.fromRdfTerm(LiteralTerm('ebook'), context);
        expect(ebook, equals(BookFormat.ebook));
      });

      test('throws on unknown literal value', () {
        const mapper = BookFormatMapper();
        final context = createDeserializationContext();

        expect(
          () => mapper.fromRdfTerm(LiteralTerm('unknown'), context),
          throwsA(isA<DeserializationException>()),
        );
      });
    });

    group('Priority enum (custom literal values)', () {
      test('serializes using custom @RdfEnumValue mappings', () {
        const mapper = PriorityMapper();
        final context = createSerializationContext();

        final highTerm = mapper.toRdfTerm(Priority.high, context);
        expect(highTerm.value, equals('H'));

        final mediumTerm = mapper.toRdfTerm(Priority.medium, context);
        expect(mediumTerm.value, equals('M'));

        final lowTerm = mapper.toRdfTerm(Priority.low, context);
        expect(lowTerm.value, equals('L'));
      });

      test('deserializes using custom @RdfEnumValue mappings', () {
        const mapper = PriorityMapper();
        final context = createDeserializationContext();

        final high = mapper.fromRdfTerm(LiteralTerm('H'), context);
        expect(high, equals(Priority.high));

        final medium = mapper.fromRdfTerm(LiteralTerm('M'), context);
        expect(medium, equals(Priority.medium));

        final low = mapper.fromRdfTerm(LiteralTerm('L'), context);
        expect(low, equals(Priority.low));
      });
    });

    group('ProductStatus enum (mixed custom and default values)', () {
      test('serializes with mixed custom and default mappings', () {
        const mapper = ProductStatusMapper();
        final context = createSerializationContext();

        final inStockTerm = mapper.toRdfTerm(ProductStatus.inStock, context);
        expect(inStockTerm.value, equals('available'));

        final outOfStockTerm =
            mapper.toRdfTerm(ProductStatus.outOfStock, context);
        expect(outOfStockTerm.value, equals('sold-out'));

        final discontinuedTerm =
            mapper.toRdfTerm(ProductStatus.discontinued, context);
        expect(discontinuedTerm.value, equals('discontinued'));
      });

      test('deserializes with mixed custom and default mappings', () {
        const mapper = ProductStatusMapper();
        final context = createDeserializationContext();

        final inStock = mapper.fromRdfTerm(LiteralTerm('available'), context);
        expect(inStock, equals(ProductStatus.inStock));

        final outOfStock = mapper.fromRdfTerm(LiteralTerm('sold-out'), context);
        expect(outOfStock, equals(ProductStatus.outOfStock));

        final discontinued =
            mapper.fromRdfTerm(LiteralTerm('discontinued'), context);
        expect(discontinued, equals(ProductStatus.discontinued));
      });
    });

    group('ItemCondition enum (IRI-based)', () {
      test('serializes to IRIs with template pattern', () {
        const mapper = ItemConditionMapper();
        final context = createSerializationContext();

        final brandNewTerm = mapper.toRdfTerm(ItemCondition.brandNew, context);
        expect(brandNewTerm, isA<IriTerm>());
        expect(brandNewTerm.value, equals('http://schema.org/NewCondition'));

        final usedTerm = mapper.toRdfTerm(ItemCondition.used, context);
        expect(usedTerm.value, equals('http://schema.org/UsedCondition'));

        final refurbishedTerm =
            mapper.toRdfTerm(ItemCondition.refurbished, context);
        expect(refurbishedTerm.value, equals('http://schema.org/refurbished'));
      });

      test('deserializes from IRIs with template pattern', () {
        const mapper = ItemConditionMapper();
        final context = createDeserializationContext();

        final brandNew = mapper.fromRdfTerm(
            const IriTerm('http://schema.org/NewCondition'), context);
        expect(brandNew, equals(ItemCondition.brandNew));

        final used = mapper.fromRdfTerm(
            const IriTerm('http://schema.org/UsedCondition'), context);
        expect(used, equals(ItemCondition.used));

        final refurbished = mapper.fromRdfTerm(
            const IriTerm('http://schema.org/refurbished'), context);
        expect(refurbished, equals(ItemCondition.refurbished));
      });

      test('throws on malformed IRI', () {
        const mapper = ItemConditionMapper();
        final context = createDeserializationContext();

        expect(
          () => mapper.fromRdfTerm(
              const IriTerm('http://invalid.org/test'), context),
          throwsA(isA<DeserializationException>()),
        );
      });
    });

    group('OrderStatus enum (controlled vocabulary IRI)', () {
      test('serializes to controlled vocabulary IRIs', () {
        const mapper = OrderStatusMapper();
        final context = createSerializationContext();

        final pendingTerm = mapper.toRdfTerm(OrderStatus.pending, context);
        expect(pendingTerm.value,
            equals('http://example.org/vocab/order-status/pending'));

        final processingTerm =
            mapper.toRdfTerm(OrderStatus.processing, context);
        expect(processingTerm.value,
            equals('http://example.org/vocab/order-status/in-progress'));

        final shippedTerm = mapper.toRdfTerm(OrderStatus.shipped, context);
        expect(shippedTerm.value,
            equals('http://example.org/vocab/order-status/shipped'));

        final deliveredTerm = mapper.toRdfTerm(OrderStatus.delivered, context);
        expect(
            deliveredTerm.value,
            equals(
                'http://example.org/vocab/order-status/delivered-completed'));
      });

      test('deserializes from controlled vocabulary IRIs', () {
        const mapper = OrderStatusMapper();
        final context = createDeserializationContext();

        final pending = mapper.fromRdfTerm(
            const IriTerm('http://example.org/vocab/order-status/pending'),
            context);
        expect(pending, equals(OrderStatus.pending));

        final processing = mapper.fromRdfTerm(
            const IriTerm('http://example.org/vocab/order-status/in-progress'),
            context);
        expect(processing, equals(OrderStatus.processing));

        final shipped = mapper.fromRdfTerm(
            const IriTerm('http://example.org/vocab/order-status/shipped'),
            context);
        expect(shipped, equals(OrderStatus.shipped));

        final delivered = mapper.fromRdfTerm(
            const IriTerm(
                'http://example.org/vocab/order-status/delivered-completed'),
            context);
        expect(delivered, equals(OrderStatus.delivered));
      });
    });

    group('CurrencyCode enum (ISO codes)', () {
      test('serializes to ISO currency codes', () {
        const mapper = CurrencyCodeMapper();
        final context = createSerializationContext();

        final usdTerm = mapper.toRdfTerm(CurrencyCode.usDollar, context);
        expect(usdTerm.value, equals('USD'));

        final eurTerm = mapper.toRdfTerm(CurrencyCode.euro, context);
        expect(eurTerm.value, equals('EUR'));

        final gbpTerm = mapper.toRdfTerm(CurrencyCode.britishPound, context);
        expect(gbpTerm.value, equals('GBP'));

        final jpyTerm = mapper.toRdfTerm(CurrencyCode.japaneseYen, context);
        expect(jpyTerm.value, equals('JPY'));
      });

      test('deserializes from ISO currency codes', () {
        const mapper = CurrencyCodeMapper();
        final context = createDeserializationContext();

        final usd = mapper.fromRdfTerm(LiteralTerm('USD'), context);
        expect(usd, equals(CurrencyCode.usDollar));

        final eur = mapper.fromRdfTerm(LiteralTerm('EUR'), context);
        expect(eur, equals(CurrencyCode.euro));

        final gbp = mapper.fromRdfTerm(LiteralTerm('GBP'), context);
        expect(gbp, equals(CurrencyCode.britishPound));

        final jpy = mapper.fromRdfTerm(LiteralTerm('JPY'), context);
        expect(jpy, equals(CurrencyCode.japaneseYen));
      });
    });

    group('BusinessEntityType enum (hierarchical vocabulary)', () {
      test('serializes to hierarchical vocabulary IRIs', () {
        const mapper = BusinessEntityTypeMapper();
        final context = createSerializationContext();

        final businessTerm =
            mapper.toRdfTerm(BusinessEntityType.business, context);
        expect(businessTerm.value,
            equals('http://purl.org/goodrelations/v1#Business'));

        final endUserTerm =
            mapper.toRdfTerm(BusinessEntityType.endUser, context);
        expect(endUserTerm.value,
            equals('http://purl.org/goodrelations/v1#Enduser'));

        final publicInstitutionTerm =
            mapper.toRdfTerm(BusinessEntityType.publicInstitution, context);
        expect(publicInstitutionTerm.value,
            equals('http://purl.org/goodrelations/v1#PublicInstitution'));

        final resellerTerm =
            mapper.toRdfTerm(BusinessEntityType.reseller, context);
        expect(resellerTerm.value,
            equals('http://purl.org/goodrelations/v1#Reseller'));
      });

      test('deserializes from hierarchical vocabulary IRIs', () {
        const mapper = BusinessEntityTypeMapper();
        final context = createDeserializationContext();

        final business = mapper.fromRdfTerm(
            const IriTerm('http://purl.org/goodrelations/v1#Business'),
            context);
        expect(business, equals(BusinessEntityType.business));

        final endUser = mapper.fromRdfTerm(
            const IriTerm('http://purl.org/goodrelations/v1#Enduser'), context);
        expect(endUser, equals(BusinessEntityType.endUser));

        final publicInstitution = mapper.fromRdfTerm(
            const IriTerm('http://purl.org/goodrelations/v1#PublicInstitution'),
            context);
        expect(publicInstitution, equals(BusinessEntityType.publicInstitution));

        final reseller = mapper.fromRdfTerm(
            const IriTerm('http://purl.org/goodrelations/v1#Reseller'),
            context);
        expect(reseller, equals(BusinessEntityType.reseller));
      });
    });

    group('UserRating enum (rating system)', () {
      test('serializes to rating system IRIs', () {
        const mapper = UserRatingMapper();
        final context = createSerializationContext();

        final excellentTerm = mapper.toRdfTerm(UserRating.excellent, context);
        expect(excellentTerm.value,
            equals('http://example.org/rating-system/excellent-5-stars'));

        final goodTerm = mapper.toRdfTerm(UserRating.good, context);
        expect(goodTerm.value,
            equals('http://example.org/rating-system/good-4-stars'));

        final averageTerm = mapper.toRdfTerm(UserRating.average, context);
        expect(averageTerm.value,
            equals('http://example.org/rating-system/average-3-stars'));

        final poorTerm = mapper.toRdfTerm(UserRating.poor, context);
        expect(poorTerm.value,
            equals('http://example.org/rating-system/poor-2-stars'));

        final terribleTerm = mapper.toRdfTerm(UserRating.terrible, context);
        expect(terribleTerm.value,
            equals('http://example.org/rating-system/terrible-1-star'));
      });

      test('deserializes from rating system IRIs', () {
        const mapper = UserRatingMapper();
        final context = createDeserializationContext();

        final excellent = mapper.fromRdfTerm(
            const IriTerm('http://example.org/rating-system/excellent-5-stars'),
            context);
        expect(excellent, equals(UserRating.excellent));

        final good = mapper.fromRdfTerm(
            const IriTerm('http://example.org/rating-system/good-4-stars'),
            context);
        expect(good, equals(UserRating.good));

        final average = mapper.fromRdfTerm(
            const IriTerm('http://example.org/rating-system/average-3-stars'),
            context);
        expect(average, equals(UserRating.average));

        final poor = mapper.fromRdfTerm(
            const IriTerm('http://example.org/rating-system/poor-2-stars'),
            context);
        expect(poor, equals(UserRating.poor));

        final terrible = mapper.fromRdfTerm(
            const IriTerm('http://example.org/rating-system/terrible-1-star'),
            context);
        expect(terrible, equals(UserRating.terrible));
      });
    });

    group('Context variable enums', () {
      test('ProductCategory uses baseVocab provider', () {
        final mapper = ProductCategoryMapper(
          baseVocabProvider: () => 'http://test.example.org/vocab',
        );
        final context = createSerializationContext();

        final electronicsTerm =
            mapper.toRdfTerm(ProductCategory.electronics, context);
        expect(electronicsTerm.value,
            equals('http://test.example.org/vocab/categories/electronics'));

        final booksMediaTerm =
            mapper.toRdfTerm(ProductCategory.booksAndMedia, context);
        expect(booksMediaTerm.value,
            equals('http://test.example.org/vocab/categories/books-media'));
      });

      test('ShippingMethod uses apiBase and version providers', () {
        final mapper = ShippingMethodMapper(
          apiBaseProvider: () => 'https://api.test.org',
          versionProvider: () => 'v2',
        );
        final context = createSerializationContext();

        final standardTerm = mapper.toRdfTerm(ShippingMethod.standard, context);
        expect(standardTerm.value,
            equals('https://api.test.org/v2/shipping-methods/standard'));

        final expressTerm = mapper.toRdfTerm(ShippingMethod.express, context);
        expect(
            expressTerm.value,
            equals(
                'https://api.test.org/v2/shipping-methods/express-overnight'));
      });

      test('EmployeeRole uses orgNamespace and department providers', () {
        final mapper = EmployeeRoleMapper(
          orgNamespaceProvider: () => 'https://company.com/ns',
          departmentProvider: () => 'engineering',
        );
        final context = createSerializationContext();

        final managerTerm = mapper.toRdfTerm(EmployeeRole.manager, context);
        expect(
            managerTerm.value,
            equals(
                'https://company.com/ns/departments/engineering/roles/manager'));

        final developerTerm = mapper.toRdfTerm(EmployeeRole.developer, context);
        expect(
            developerTerm.value,
            equals(
                'https://company.com/ns/departments/engineering/roles/developer'));
      });
    });

    group('Book resource class integration', () {
      test('serializes and deserializes Book with all enum types', () {
        final book = Book(
          sku: 'TEST-123',
          format: BookFormat.hardcover,
          condition: ItemCondition.brandNew,
          priority: Priority.high,
          status: ProductStatus.inStock,
        );

        final context = createSerializationContext();
        final mapper = BookMapper(
          customPriorityMapper: const TestCustomPriorityMapper(),
        );

        final (subject, triples) = mapper.toRdfResource(book, context);

        expect(subject.value, equals('http://example.org/books/TEST-123'));
        expect(
            triples.length, greaterThanOrEqualTo(4)); // At least 4 properties

        // Check that correct RDF terms are generated for each enum property
        final formatTriple =
            triples.firstWhere((t) => t.predicate == MyBookVocab.bookFormat);
        expect((formatTriple.object as LiteralTerm).value, equals('hardcover'));

        final conditionTriple =
            triples.firstWhere((t) => t.predicate == MyBookVocab.itemCondition);
        expect((conditionTriple.object as IriTerm).value,
            equals('http://schema.org/NewCondition'));

        final priorityTriple =
            triples.firstWhere((t) => t.predicate == MyBookVocab.priority);
        expect((priorityTriple.object as LiteralTerm).value, equals('high'));

        final statusTriple =
            triples.firstWhere((t) => t.predicate == MyBookVocab.status);
        expect((statusTriple.object as LiteralTerm).value, equals('available'));
        expect((statusTriple.object as LiteralTerm).language, equals('en'));
      });

      test('deserializes Book from RDF triples', () {
        final triples = [
          Triple(
            const IriTerm('http://example.org/books/TEST-456'),
            MyBookVocab.bookFormat,
            LiteralTerm('paperback'),
          ),
          Triple(
            const IriTerm('http://example.org/books/TEST-456'),
            MyBookVocab.itemCondition,
            const IriTerm('http://schema.org/UsedCondition'),
          ),
          Triple(
            const IriTerm('http://example.org/books/TEST-456'),
            MyBookVocab.priority,
            LiteralTerm('medium'),
          ),
          Triple(
            const IriTerm('http://example.org/books/TEST-456'),
            MyBookVocab.status,
            LiteralTerm('sold-out', language: 'en'),
          ),
        ];

        final graph = RdfGraph.fromTriples(triples);
        final context = DeserializationContextImpl(
          graph: graph,
          registry: mapper.registry,
        );

        final bookMapper = BookMapper(
          customPriorityMapper: const TestCustomPriorityMapper(),
        );

        final book = bookMapper.fromRdfResource(
          const IriTerm('http://example.org/books/TEST-456'),
          context,
        );

        expect(book.sku, equals('TEST-456'));
        expect(book.format, equals(BookFormat.paperback));
        expect(book.condition, equals(ItemCondition.used));
        expect(book.priority, equals(Priority.medium));
        expect(book.status, equals(ProductStatus.outOfStock));
      });
    });
  });
}
