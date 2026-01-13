import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:rdf_mapper_annotations/rdf_mapper_annotations.dart';

/// Base class for all mapping configurations that share common mapper functionality.
///
/// This abstract class serves as the foundation for all mapper reference classes like
/// [GlobalResourceMapping], [LocalResourceMapping], [IriMapping], and [LiteralMapping].
/// It provides a unified approach to specify mapper selection strategies:
///
/// 1. By name: Use dependency injection to supply a mapper at runtime
/// 2. By type: Automatically instantiate a mapper from a given class type
/// 3. By instance: Use a pre-configured mapper instance directly
/// 4. By factory: Use a factory function to create mappers with optional configuration
///
/// This abstraction enables consistent constructor patterns across all mapping types
/// while maintaining type safety with the generic parameter [M] defining the expected
/// mapper interface.
///
/// This base class is not intended to be used directly, but rather serves as the
/// foundation for specialized mapping classes.
abstract class BaseMapping<M> {
  /// The name to use for the mapper parameter in the generated `initRdfMapper`
  /// method when using named mapper injection.
  final String? _mapperName;

  /// The type of mapper to instantiate when using type-based mapper creation.
  final Type? _mapperType;

  /// The mapper instance to use directly when provided.
  final M? _mapperInstance;

  /// The name to use for the factory parameter in the generated `initRdfMapper`
  /// method when using named factory injection.
  final String? _factoryName;

  /// The configuration instance to pass to the factory function, if any.
  final Object? _factoryConfigInstance;

  /// Creates a base resource mapping with the specified class IRI and mapper configuration.
  const BaseMapping({
    String? mapperName,
    Type? mapperType,
    M? mapperInstance,
    String? factoryName,
    Object? factoryConfigInstance,
  })  : _mapperName = mapperName,
        _mapperType = mapperType,
        _mapperInstance = mapperInstance,
        _factoryName = factoryName,
        _factoryConfigInstance = factoryConfigInstance;

  /// Provides a [MapperRef] if a custom mapper is specified.
  ///
  /// Returns a MapperRef instance if any mapper configuration is provided
  /// (name, type, instance, or factory), otherwise returns null.
  MapperRef<M>? get mapper => (_mapperName != null ||
          _mapperInstance != null ||
          _mapperType != null ||
          _factoryName != null)
      ? MapperRef(
          name: _mapperName,
          instance: _mapperInstance,
          type: _mapperType,
          factoryName: _factoryName,
          factoryConfigInstance: _factoryConfigInstance,
        )
      : null;

  /// Creates a reference to a named mapper that will be injected at runtime.
  ///
  /// Use this constructor when you want to provide a custom mapper through
  /// dependency injection. With this approach:
  ///
  /// 1. You implement the mapper yourself
  /// 2. Instantiate it outside of the generated code
  /// 3. Provide it as a named parameter to `initRdfMapper`
  ///
  /// The [name] will appear as a parameter name in the generated `initRdfMapper` function.
  ///
  /// Example:
  /// ```dart
  /// // In your class property
  /// @RdfProperty(
  ///   SchemaBook.price,
  ///   literal: LiteralMapping.namedMapper('priceMapper')
  /// )
  /// final Price price;
  ///
  /// // Later when initializing mappers:
  /// final rdfMapper = initRdfMapper(
  ///   priceMapper: myCustomPriceMapper
  /// );
  /// ```
  const BaseMapping.namedMapper(String name)
      : _mapperName = name,
        _mapperType = null,
        _mapperInstance = null,
        _factoryName = null,
        _factoryConfigInstance = null;

  /// Creates a reference to a mapper that will be instantiated from the given type.
  ///
  /// The code generator will create an instance of [mapperType] using its default
  /// constructor to handle mapping for this type.
  ///
  /// Use this approach when your mapper has a default constructor and doesn't
  /// require additional configuration parameters.
  ///
  /// Example:
  /// ```dart
  /// @RdfProperty(
  ///   SchemaBook.price,
  ///   literal: LiteralMapping.mapper(StandardPriceMapper)
  /// )
  /// final Price price;
  ///
  /// // The mapper class must be accessible to the generator:
  /// class StandardPriceMapper implements LiteralTermMapper<Price> {
  ///   // Implementation...
  /// }
  /// ```
  const BaseMapping.mapper(Type mapperType)
      : _mapperName = null,
        _mapperType = mapperType,
        _mapperInstance = null,
        _factoryName = null,
        _factoryConfigInstance = null;

  /// Creates a reference to a directly provided mapper instance.
  ///
  /// This allows you to supply a pre-configured mapper instance to handle mapping
  /// for this type. Useful when your mapper requires constructor parameters or
  /// complex setup that cannot be handled by simple instantiation.
  ///
  /// Since Dart annotations must be compile-time constants, the mapper instance
  /// must be a `const` instance. If it cannot be `const`, consider using
  /// [BaseMapping.namedMapper] instead.
  ///
  /// Example:
  /// ```dart
  /// // Create a pre-configured mapper with const constructor:
  /// const myPriceMapper = PriceMapper(
  ///   currency: 'EUR',
  ///   locale: 'de_DE',
  /// );
  ///
  /// @RdfProperty(
  ///   SchemaBook.price,
  ///   literal: LiteralMapping.mapperInstance(myPriceMapper)
  /// )
  /// final Price price;
  /// ```
  const BaseMapping.mapperInstance(M instance)
      : _mapperName = null,
        _mapperType = null,
        _mapperInstance = instance,
        _factoryName = null,
        _factoryConfigInstance = null;

  /// Creates a reference to a named factory function for creating mappers.
  ///
  /// Use this constructor when you want to provide a factory function that creates
  /// mapper instances dynamically. This is particularly useful for libraries that
  /// need to coordinate mapping across multiple types with a single, shared
  /// configuration and strategy.
  ///
  /// The factory function is called with the specific type information for this
  /// class, and optionally the configuration object if [configInstance] is specified.
  /// This allows a single factory to handle different classes while maintaining
  /// type safety.
  ///
  /// When using this approach, you must:
  /// 1. Implement a factory function with the appropriate signature
  /// 2. Provide the factory function as a named parameter to `initRdfMapper`
  ///
  /// This approach is ideal for:
  /// - Libraries that need to coordinate mapping across all stored types
  /// - Cases where a single authority needs to manage resource allocation
  ///
  /// The [name] will appear as a parameter name in the generated `initRdfMapper` function.
  /// The optional [configInstance] specifies the configuration object instance that will
  /// be passed to the factory function and thus influences the type signature of the factory function.
  ///
  /// Example:
  /// ```dart
  /// // Configuration for pod coordination
  /// const podConfig = PodConfig(storagePolicy: 'distributed');
  ///
  /// // Used in annotation
  /// @RdfGlobalResource(
  ///   Document.classIri,
  ///   IriStrategy.namedFactory('podIriFactory', podConfig)
  /// )
  /// class Document { /* ... */ }
  ///
  /// // Factory function with type parameter and config:
  /// IriTermMapper<(String,)> createPodIriMapper<T>(PodConfig config) {
  ///   return PodIriMapper<(String,)>(
  ///     targetType: T,
  ///     storagePolicy: config.storagePolicy
  ///   );
  /// }
  ///
  /// // Generated initRdfMapper calls: podIriFactory<Document>(podConfig)
  /// final rdfMapper = initRdfMapper(
  ///   podIriFactory: createPodIriMapper,
  /// );
  /// ```
  const BaseMapping.namedFactory(String name, [Object? configInstance])
      : _mapperName = null,
        _mapperType = null,
        _mapperInstance = null,
        _factoryName = name,
        _factoryConfigInstance = configInstance;
}

abstract class BaseMappingAnnotation<M extends Mapper> extends BaseMapping<M>
    implements RdfAnnotation {
  /// Controls whether the generated mapper should be registered globally
  /// in the `initRdfMapper` function.
  ///
  /// When `true` (default), the mapper is registered globally and can be used by any
  /// class in your application. Use this for standard resources that are accessed
  /// throughout your application.
  ///
  /// When `false`, the mapper is not registered globally and is only used within
  /// the context where it's needed. Use this when:
  /// - The mapper has dependencies that are provided by parent objects via `@RdfProvides`
  /// - The mapper is only used in specific contexts and shouldn't be generally available
  /// - You want to prevent the mapper's dependencies from being required in `initRdfMapper`
  final bool registerGlobally;

  /// Specifies whether this mapper should handle serialization, deserialization, or both.
  ///
  /// This is only used when custom mappers are specified (via `.namedMapper()`,
  /// `.mapper()`, or `.mapperInstance()` constructors). For standard constructors,
  /// specialized constructors like `.deserializeOnly()` should be used instead.
  final MapperDirection? direction;

  const BaseMappingAnnotation(
      {this.registerGlobally = true,
      MapperDirection direction = MapperDirection.both})
      : direction = direction,
        super();

  const BaseMappingAnnotation.namedMapper(String name,
      {MapperDirection direction = MapperDirection.both})
      : registerGlobally = true,
        direction = direction,
        super.namedMapper(name);

  const BaseMappingAnnotation.mapper(Type mapperType,
      {MapperDirection direction = MapperDirection.both})
      : registerGlobally = true,
        direction = direction,
        super.mapper(mapperType);

  const BaseMappingAnnotation.mapperInstance(M instance,
      {MapperDirection direction = MapperDirection.both})
      : registerGlobally = true,
        direction = direction,
        super.mapperInstance(instance);

  const BaseMappingAnnotation.namedFactory(String name,
      [Object? configInstance, bool registerGlobally = true])
      : registerGlobally = registerGlobally,
        direction = null,
        super.namedFactory(name, configInstance);
}
