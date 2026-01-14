import 'package:locorda_rdf_mapper_annotations/annotations.dart';

/// Base class for type-safe mapper references.
///
/// Used internally by annotations like [RdfGlobalResource], [RdfLocalResource],
/// [RdfIri], and [RdfLiteral] to specify how custom mappers should be provided
/// to the generated code. This class enables flexible dependency injection and
/// customization options.
class MapperRef<M> {
  /// The name to use for the mapper parameter in the generated `initRdfMapper`
  /// method. Enables dependency injection of specific mapper instances.
  final String? name;

  /// The [Type] of the mapper to instantiate. The generator will create an
  /// instance of this type at runtime.
  final Type? type;

  /// A direct mapper instance to be used. Allows for pre-configured mapper
  /// instances with specific behaviors.
  final M? instance;

  /// The name to use for the factory parameter in the generated `initRdfMapper`
  /// method. Enables dependency injection of factory functions that create mappers.
  final String? factoryName;

  /// The configuration instance to pass to the factory function, if any.
  final Object? factoryConfigInstance;

  /// Creates a mapper reference with optional injection configuration.
  const MapperRef({
    this.name,
    this.type,
    this.instance,
    this.factoryName,
    this.factoryConfigInstance,
  });
}
