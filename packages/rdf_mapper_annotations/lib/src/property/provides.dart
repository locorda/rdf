import 'package:rdf_mapper_annotations/src/base/rdf_annotation.dart';

/// Marks a property as providing a named value that can be referenced in
/// IRI templates in the RDF mapping system.
///
/// This annotation makes the property's value available to mappers via constructor injection,
/// but only to those that explicitly require the value by name and signature in their constructor.
/// The value can then be referenced in IRI templates using the provided name. This works
/// consistently across all levels:
///
/// - Property mappers within the same class receive the provided values if their constructor
///   requires a provider for that specific variable
/// - Property mappers for nested resources (child objects) receive the provided values if they
///   require them in their constructor
/// - IRI templates can reference these values using `{variableName}` and the system automatically
///   ensures the necessary providers are available
///
/// Technically, the same constructor injection mechanism is used in all cases - each property
/// mapper receives provider functions for all variables it needs. This avoids the need
/// to register global provider functions in `initRdfMapper` for values that are
/// available within the object graph.
///
/// ## Alternative: Providing the Resource IRI
///
/// Instead of annotating properties with `@RdfProvides`, you can also provide the resource's
/// own IRI to dependent mappers by using the `providedAs` parameter on `IriStrategy`.
/// See [IriStrategy] documentation for details on this alternative approach.
///
/// Examples:
///
/// **Example: Using @RdfProvides to pass parentId to Iri property and nested resource**
/// ```dart
/// @RdfGlobalResource(
///   ExampleVocab.Parent,
///   IriStrategy('{+baseUri}/{id}.ttl'),
/// )
/// class Parent {
///   @RdfIriPart()
///   @RdfProvides("parentId")
///   late String id;
///
///   @RdfProperty(ExampleVocab.child)
///   late Child child;
///
///   @RdfProperty(ExampleVocab.sibling,
///       iri: IriMapping('{+baseUri}/{parentId}/sibling/{siblingId}.ttl'))
///   late String siblingId;
/// }
///
/// @RdfGlobalResource(
///   ExampleVocab.Child,
///   IriStrategy('{+baseUri}/{parentId}/child/{id}.ttl'),
///   registerGlobally: false,
/// )
/// class Child {
///   @RdfIriPart()
///   late String id;
///
///   @RdfProperty(ExampleVocab.childName)
///   late String name;
/// }
/// ```
/// Note that the baseUri will be provided by a global provider function
/// in `initRdfMapper`, while the parentId is provided by the `@RdfProvides`
/// annotation on the `id` property of the `Parent` class. The Child class
/// is annotated to not be registered globally, so it will not be available
/// in `initRdfMapper` and will only be used within the context of the Parent.
class RdfProvides extends RdfAnnotation {
  /// The name by which this provided value can be referenced in IRI templates.
  ///
  /// When not specified, the property's name is used as the provided variable name.
  /// For example, `@RdfProvides()` on a property named `baseUri` makes `{+baseUri}`
  /// available in IRI templates. The `+` prefix indicates that the variable may contain
  /// URI-reserved characters like slashes, which should not be percent-encoded when substituted.
  final String? name;

  /// Creates an annotation that provides a value to be used in IRI templates.
  ///
  /// [name] is the name by which the value can be referenced in templates.
  /// If omitted, the property's own name is used.
  const RdfProvides([this.name]);
}
