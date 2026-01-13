import 'package:rdf_mapper_generator/src/mappers/mapper_model.dart';
import 'package:rdf_mapper_generator/src/processors/models/mapper_info.dart';
import 'package:rdf_mapper_generator/src/templates/code.dart';
import 'package:rdf_mapper_generator/src/templates/util.dart';

EnumValueModel toEnumValueModel(EnumValueInfo e) {
  return EnumValueModel(
    constantName: e.constantName,
    serializedValue: e.serializedValue,
  );
}

/// Builds the mapper interface type, considering collection types
Code buildElementTypeForProperty(
    CollectionModel? collectionModel, Code typeNonNull) {
  if (collectionModel == null || !collectionModel.isCollection) {
    return typeNonNull;
  }

  // For collections, the mapper type should be for the element type
  if (collectionModel.isMap && collectionModel.mapEntryClassModel != null) {
    return collectionModel.mapEntryClassModel!.className;
  } else if (collectionModel.isMap &&
      collectionModel.mapKeyTypeCode != null &&
      collectionModel.mapValueTypeCode != null) {
    // For maps, use MapEntry<K,V> as the element type
    final mapEntryType = codeGeneric2(Code.type('MapEntry'),
        collectionModel.mapKeyTypeCode!, collectionModel.mapValueTypeCode!);
    return mapEntryType;
  } else if (collectionModel.elementTypeCode != null) {
    // For List/Set, use the element type
    return collectionModel.elementTypeCode!;
  }
  return typeNonNull;
}

/// Builds the mapper interface type, considering collection types
Code buildMapperInterfaceTypeForProperty(
    Code mapperInterface, CollectionModel? collectionModel, Code typeNonNull) {
  return codeGeneric1(mapperInterface,
      buildElementTypeForProperty(collectionModel, typeNonNull));
}
