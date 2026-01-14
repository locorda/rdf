import 'dart:math';

import 'package:locorda_rdf_core/core.dart';
import 'package:locorda_rdf_mapper_annotations/annotations.dart';
import 'package:locorda_rdf_terms_common/dcterms.dart';

// -- Our model class --
@RdfGlobalResource(
  SolidTaskTask.classIri,
  IriStrategy('{+storageRoot}/solidtask/task/{id}.ttl'),
)
class Item {
  @RdfIriPart()
  @RdfProvides("taskId")
  late String id;

  @RdfProperty(SolidTaskTask.text)
  late String text;

  @RdfProperty(Dcterms.created)
  late DateTime createdAt;

  @RdfProperty(SolidTaskTask.vectorClock)
  @RdfMapEntry(VectorClockEntry)
  late Map<String, int> vectorClock;

  @RdfProperty(SolidTaskTask.isDeleted)
  late bool isDeleted;

  @RdfProperty(
    Dcterms.creator,
    iri: IriMapping(
      '{+storageRoot}/solidtask/appinstance/{lastModifiedBy}.ttl',
    ),
  )
  late String lastModifiedBy;

  Item({required this.text, required this.lastModifiedBy}) {
    // Generate a UUID v4 for guaranteed uniqueness
    id = Random().nextInt(1000000).toString();
    createdAt = DateTime.now();
    vectorClock = {lastModifiedBy: 1};
    isDeleted = false;
  }
}

@RdfGlobalResource(
  SolidTaskVectorClockEntry.classIri,
  IriStrategy(
    '{+storageRoot}/solidtask/task/{taskId}.ttl#vectorclock-{clientId}',
  ),
  registerGlobally: false,
)
class VectorClockEntry {
  @RdfIriPart()
  @RdfProperty(
    SolidTaskVectorClockEntry.clientId,
    iri: IriMapping('{+storageRoot}/solidtask/appinstance/{clientId}.ttl'),
  )
  @RdfMapKey()
  final String clientId;

  @RdfProperty(SolidTaskVectorClockEntry.clockValue)
  @RdfMapValue()
  final int clockValue;

  /// Creates a new vector clock entry
  VectorClockEntry(this.clientId, this.clockValue);
}

// -- Our ontology class provided by us --
class SolidTask {
  /// Private constructor to prevent instantiation
  const SolidTask._();

  /// Base IRI for task ontology
  static const String namespace = 'http://solidtask.org/ontology#';

  /// IRI for the Task class
  static const Task = const IriTerm('${namespace}Task');

  /// IRI for VectorClockEntry class
  static const VectorClockEntry = const IriTerm(
    '${namespace}VectorClockEntry',
  );

  /// IRI for task text property
  static const text = const IriTerm('${namespace}text');

  /// IRI for task isDeleted property
  static const isDeleted = const IriTerm('${namespace}isDeleted');

  /// IRI for task vectorClock property
  static const vectorClock = const IriTerm('${namespace}vectorClock');

  /// IRI for clientId property in vector clock entries
  static const clientId = const IriTerm('${namespace}clientId');

  /// IRI for clockValue property in vector clock entries
  static const clockValue = const IriTerm('${namespace}clockValue');
}

class SolidTaskTask {
  /// Private constructor to prevent instantiation
  const SolidTaskTask._();

  /// Base IRI for task ontology
  static const classIri = SolidTask.Task;

  /// IRI for task text property
  static const text = SolidTask.text;

  /// IRI for task isDeleted property
  static const isDeleted = SolidTask.isDeleted;

  /// IRI for task vectorClock property
  static const vectorClock = SolidTask.vectorClock;
}

class SolidTaskVectorClockEntry {
  /// Private constructor to prevent instantiation
  const SolidTaskVectorClockEntry._();

  /// Base IRI for task ontology
  static const classIri = SolidTask.VectorClockEntry;

  static const clientId = SolidTask.clientId;

  static const clockValue = SolidTask.clockValue;
}
