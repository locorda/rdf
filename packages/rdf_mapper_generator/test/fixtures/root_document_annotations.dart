import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper_annotations/rdf_mapper_annotations.dart';

final class RootResource extends RdfGlobalResource {
  const RootResource()
      : super(
          const IriTerm('http://example.org/RootDocument'),
          const IriStrategy(
              'tag:example.org,2025:document-{id}', 'documentIri'),
        );
}

final class ChildResource extends RdfGlobalResource {
  const ChildResource()
      : super(
            const IriTerm('http://example.org/Section'),
            const IriStrategy.withFragment(
                '{+documentIri}', 'section-{sectionId}'),
            registerGlobally: false);
}
