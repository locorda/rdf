import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:rdf_mapper_annotations/rdf_mapper_annotations.dart';
import 'package:rdf_vocabularies_core/foaf.dart';
import 'package:rdf_vocabularies_core/solid.dart';
import 'package:rdf_vocabularies_core/pim.dart';

@RdfGlobalResource(FoafPersonalProfileDocument.classIri, IriStrategy(),
    registerGlobally: false)
class Document<T> {
  @RdfIriPart()
  @RdfProvides()
  final String documentIri;

  @RdfProperty(FoafPersonalProfileDocument.primaryTopic,
      contextual: ContextualMapping.namedProvider("primaryTopic"))
  final T primaryTopic;

  @RdfProperty(FoafPersonalProfileDocument.maker)
  final Uri maker;

  @RdfUnmappedTriples(globalUnmapped: true)
  final RdfGraph unmapped;

  Document(
      {required this.documentIri,
      required this.maker,
      required this.primaryTopic,
      required this.unmapped});
}

const iriRelative =
    ContextualMapping.provider(IriRelativeSerializationProvider);

@RdfGlobalResource(FoafPerson.classIri, IriStrategy("{+documentIri}#me"),
    registerGlobally: false)
class Person {
  @RdfProperty(FoafPerson.name)
  String name;

  @RdfProperty(FoafPerson.pimPreferencesFile, contextual: iriRelative)
  String preferencesFile;

  @RdfProperty(Pim.storage)
  Uri storage;

  @RdfProperty(Solid.account, contextual: iriRelative)
  String account;

  @RdfProperty(Solid.oidcIssuer)
  Uri oidcIssuer;

  @RdfProperty(Solid.privateTypeIndex, contextual: iriRelative)
  String privateTypeIndex;

  @RdfProperty(Solid.publicTypeIndex, contextual: iriRelative)
  String publicTypeIndex;

  Person(
      {required this.name,
      required this.preferencesFile,
      required this.storage,
      required this.account,
      required this.oidcIssuer,
      required this.privateTypeIndex,
      required this.publicTypeIndex});
}
