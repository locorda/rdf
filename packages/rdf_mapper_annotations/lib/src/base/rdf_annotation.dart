/// Base annotation interface for RDF mapper generation.
///
/// This is a marker interface for all RDF mapping annotations used by the
/// `rdf_mapper_generator` package to automatically generate implementations
/// of the `rdf_mapper` interfaces. These annotations enable a declarative
/// approach to mapping between Dart objects and RDF graphs.
///
/// Note that using these annotations is optional. You can also implement mappers
/// manually and register them directly with the `RdfMapper` instance, as shown
/// in the library documentation.
abstract class RdfAnnotation {
  const RdfAnnotation();
}
