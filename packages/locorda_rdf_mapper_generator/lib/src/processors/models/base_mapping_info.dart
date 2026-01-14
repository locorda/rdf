// import 'package:analyzer/dart/constant/value.dart';
import 'package:locorda_rdf_mapper_generator/src/analyzer_wrapper/analyzer_wrapper_models.dart';
import 'package:locorda_rdf_mapper_generator/src/templates/code.dart';

class MapperRefInfo<M> {
  final String? name;

  final Code? type;
  final Code? rawType;

  final DartObject? instance;

  /// Factory name for namedFactory pattern
  final String? factoryName;

  /// Configuration instance for namedFactory pattern
  final DartObject? configInstance;

  /// Type of the configuration parameter
  final Code? configType;

  const MapperRefInfo({
    required this.name,
    required this.type,
    this.rawType,
    required this.instance,
    this.factoryName,
    this.configInstance,
    this.configType,
  });

  @override
  int get hashCode => Object.hashAll([
        name,
        type,
        rawType,
        instance,
        factoryName,
        configInstance,
        configType,
      ]);

  @override
  bool operator ==(Object other) {
    if (other is! MapperRefInfo<M>) {
      return false;
    }
    return name == other.name &&
        type == other.type &&
        rawType == other.rawType &&
        instance == other.instance &&
        factoryName == other.factoryName &&
        configInstance == other.configInstance &&
        configType == other.configType;
  }

  @override
  String toString() {
    return 'MapperRefInfo{'
        'name: $name, '
        'type: $type, '
        'rawType: $rawType, '
        'instance: $instance, '
        'factoryName: $factoryName, '
        'configInstance: $configInstance, '
        'configType: $configType}';
  }
}

class BaseMappingInfo<M> {
  final MapperRefInfo<M>? mapper;
  const BaseMappingInfo({required this.mapper});

  @override
  int get hashCode => Object.hashAll([mapper]);

  @override
  bool operator ==(Object other) {
    if (other is! BaseMappingInfo<M>) {
      return false;
    }
    return mapper == other.mapper;
  }

  @override
  String toString() {
    return 'BaseMappingInfo{mapper: $mapper}';
  }
}
