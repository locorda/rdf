import 'package:locorda_rdf_mapper_generator/src/processors/models/mapper_info.dart';
import 'package:locorda_rdf_mapper_generator/src/templates/code.dart';
import 'package:test/test.dart';

void main() {
  group('IriInfo', () {
    late IriInfo testInstance;
    late IriInfo identicalInstance;
    late IriInfo differentInstance;

    setUp(() {
      final className = Code.literal('TestClass');
      const annotation = RdfIriInfo(
        registerGlobally: true,
        mapper: null,
        template: 'test-template',
        iriParts: [],
        templateInfo: null,
      );
      const constructors = <ConstructorInfo>[];
      const fields = <PropertyInfo>[];

      testInstance = IriInfo(
        className: className,
        annotation: annotation,
        constructors: constructors,
        properties: fields,
      );

      identicalInstance = IriInfo(
        className: className,
        annotation: annotation,
        constructors: constructors,
        properties: fields,
      );

      differentInstance = IriInfo(
        className: Code.literal('DifferentClass'),
        annotation: annotation,
        constructors: constructors,
        properties: fields,
      );
    });

    test('equals returns true for identical instances', () {
      expect(testInstance, equals(identicalInstance));
    });

    test('equals returns false for different instances', () {
      expect(testInstance, isNot(equals(differentInstance)));
    });

    test('equals returns false for non-IriInfo instances', () {
      expect(testInstance, isNot(equals('not an IriInfo')));
    });

    test('hashCode is consistent for identical instances', () {
      expect(testInstance.hashCode, equals(identicalInstance.hashCode));
    });

    test('hashCode is different for different instances', () {
      expect(testInstance.hashCode, isNot(equals(differentInstance.hashCode)));
    });

    test('toString returns formatted string representation', () {
      final result = testInstance.toString();
      expect(result, contains('IriInfo{'));
      expect(result, contains('className: TestClass'));
      expect(result, contains('annotation:'));
      expect(result, contains('constructors: []'));
      expect(result, contains('fields: []'));
    });
  });

  group('LiteralInfo', () {
    late LiteralInfo testInstance;
    late LiteralInfo identicalInstance;
    late LiteralInfo differentInstance;

    setUp(() {
      final className = Code.literal('TestLiteral');
      const annotation = RdfLiteralInfo(
        registerGlobally: true,
        mapper: null,
        fromLiteralTermMethod: null,
        toLiteralTermMethod: null,
        datatype: null,
      );
      const constructors = <ConstructorInfo>[];
      const fields = <PropertyInfo>[];

      testInstance = LiteralInfo(
        className: className,
        annotation: annotation,
        constructors: constructors,
        properties: fields,
      );

      identicalInstance = LiteralInfo(
        className: className,
        annotation: annotation,
        constructors: constructors,
        properties: fields,
      );

      differentInstance = LiteralInfo(
        className: Code.literal('DifferentLiteral'),
        annotation: annotation,
        constructors: constructors,
        properties: fields,
      );
    });

    test('equals returns true for identical instances', () {
      expect(testInstance, equals(identicalInstance));
    });

    test('equals returns false for different instances', () {
      expect(testInstance, isNot(equals(differentInstance)));
    });

    test('equals returns false for non-LiteralInfo instances', () {
      expect(testInstance, isNot(equals('not a LiteralInfo')));
    });

    test('hashCode is consistent for identical instances', () {
      expect(testInstance.hashCode, equals(identicalInstance.hashCode));
    });

    test('toString returns formatted string representation', () {
      final result = testInstance.toString();
      expect(result, contains('LiteralInfo{'));
      expect(result, contains('className: TestLiteral'));
    });
  });

  group('ResourceInfo', () {
    late ResourceInfo testInstance;
    late ResourceInfo identicalInstance;
    late ResourceInfo differentInstance;

    setUp(() {
      final className = Code.literal('TestResource');
      const annotation = RdfGlobalResourceInfo(
        classIri: null,
        iri: null,
        registerGlobally: true,
        mapper: null,
      );
      const constructors = <ConstructorInfo>[];
      const fields = <PropertyInfo>[];

      testInstance = ResourceInfo(
        className: className,
        annotation: annotation,
        constructors: constructors,
        properties: fields,
      );

      identicalInstance = ResourceInfo(
        className: className,
        annotation: annotation,
        constructors: constructors,
        properties: fields,
      );

      differentInstance = ResourceInfo(
        className: Code.literal('DifferentResource'),
        annotation: annotation,
        constructors: constructors,
        properties: fields,
      );
    });

    test('equals returns true for identical instances', () {
      expect(testInstance, equals(identicalInstance));
    });

    test('equals returns false for different instances', () {
      expect(testInstance, isNot(equals(differentInstance)));
    });

    test('equals returns false for non-ResourceInfo instances', () {
      expect(testInstance, isNot(equals('not a ResourceInfo')));
    });

    test('hashCode is consistent for identical instances', () {
      expect(testInstance.hashCode, equals(identicalInstance.hashCode));
    });

    test('isGlobalResource returns true for RdfGlobalResourceInfo', () {
      expect(testInstance.isGlobalResource, isTrue);
    });

    test('isGlobalResource returns false for RdfLocalResourceInfo', () {
      const localAnnotation = RdfLocalResourceInfo(
        classIri: null,
        registerGlobally: true,
        mapper: null,
      );
      final localInstance = ResourceInfo(
        className: const Code.literal('LocalResource'),
        annotation: localAnnotation,
        constructors: const [],
        properties: const [],
      );
      expect(localInstance.isGlobalResource, isFalse);
    });

    test('toString returns formatted string representation', () {
      final result = testInstance.toString();
      expect(result, contains('ResourceInfo{'));
      expect(result, contains('className: TestResource'));
    });
  });

  group('IriStrategyInfo', () {
    late IriStrategyInfo testInstance;
    late IriStrategyInfo identicalInstance;
    late IriStrategyInfo differentInstance;

    setUp(() {
      testInstance = IriStrategyInfo(
        mapper: null,
        template: 'test-template',
        templateInfo: null,
        iriMapperType: null,
      );

      identicalInstance = IriStrategyInfo(
        mapper: null,
        template: 'test-template',
        templateInfo: null,
        iriMapperType: null,
      );

      differentInstance = IriStrategyInfo(
        mapper: null,
        template: 'different-template',
        templateInfo: null,
        iriMapperType: null,
      );
    });

    test('equals returns true for identical instances', () {
      expect(testInstance, equals(identicalInstance));
    });

    test('equals returns false for different instances', () {
      expect(testInstance, isNot(equals(differentInstance)));
    });

    test('equals returns false for non-IriStrategyInfo instances', () {
      expect(testInstance, isNot(equals('not an IriStrategyInfo')));
    });

    test('hashCode is consistent for identical instances', () {
      expect(testInstance.hashCode, equals(identicalInstance.hashCode));
    });

    test('toString returns formatted string representation', () {
      final result = testInstance.toString();
      expect(result, contains('IriStrategyInfo{'));
      expect(result, contains('template: test-template'));
    });
  });

  group('VariableName', () {
    late VariableName testInstance;
    late VariableName identicalInstance;
    late VariableName differentInstance;

    setUp(() {
      testInstance = VariableName(
        dartPropertyName: 'testProperty',
        name: 'testVar',
        canBeUri: true,
      );

      identicalInstance = VariableName(
        dartPropertyName: 'testProperty',
        name: 'testVar',
        canBeUri: true,
      );

      differentInstance = VariableName(
        dartPropertyName: 'differentProperty',
        name: 'testVar',
        canBeUri: true,
      );
    });

    test('equals returns true for identical instances', () {
      expect(testInstance, equals(identicalInstance));
    });

    test('equals returns true for same instance', () {
      expect(testInstance, equals(testInstance));
    });

    test('equals returns false for different instances', () {
      expect(testInstance, isNot(equals(differentInstance)));
    });

    test('equals returns false for non-VariableName instances', () {
      expect(testInstance, isNot(equals('not a VariableName')));
    });

    test('hashCode is consistent for identical instances', () {
      expect(testInstance.hashCode, equals(identicalInstance.hashCode));
    });

    test('toString returns formatted string representation', () {
      final result = testInstance.toString();
      expect(result, contains('VariableName('));
      expect(result, contains('dartPropertyName: testProperty'));
      expect(result, contains('name: testVar'));
      expect(result, contains('canBeUri: true'));
    });
  });

  group('IriPartInfo', () {
    late IriPartInfo testInstance;
    late IriPartInfo identicalInstance;
    late IriPartInfo differentInstance;

    setUp(() {
      testInstance = IriPartInfo(
        name: 'testPart',
        dartPropertyName: 'testProperty',
        type: Code.literal('String'),
        pos: 0,
      );

      identicalInstance = IriPartInfo(
        name: 'testPart',
        dartPropertyName: 'testProperty',
        type: Code.literal('String'),
        pos: 0,
      );

      differentInstance = IriPartInfo(
        name: 'differentPart',
        dartPropertyName: 'testProperty',
        type: Code.literal('String'),
        pos: 0,
      );
    });

    test('equals returns true for identical instances', () {
      expect(testInstance, equals(identicalInstance));
    });

    test('equals returns true for same instance', () {
      expect(testInstance, equals(testInstance));
    });

    test('equals returns false for different instances', () {
      expect(testInstance, isNot(equals(differentInstance)));
    });

    test('equals returns false for non-IriPartInfo instances', () {
      expect(testInstance, isNot(equals('not an IriPartInfo')));
    });

    test('hashCode is consistent for identical instances', () {
      expect(testInstance.hashCode, equals(identicalInstance.hashCode));
    });

    test('toString returns formatted string representation', () {
      final result = testInstance.toString();
      expect(result, contains('IriPartInfo('));
      expect(result, contains('name: testPart'));
      expect(result, contains('dartPropertyName: testProperty'));
      expect(result, contains('type: String'));
      expect(result, contains('pos: 0'));
    });
  });

  group('IriMapperType', () {
    late IriMapperType testInstance;
    late IriMapperType identicalInstance;
    late IriMapperType differentInstance;

    setUp(() {
      final parts = [
        IriPartInfo(
          name: 'part1',
          dartPropertyName: 'prop1',
          type: Code.literal('String'),
          pos: 0,
        ),
      ];

      testInstance = IriMapperType(Code.literal('TestType'), parts);
      identicalInstance = IriMapperType(Code.literal('TestType'), parts);
      differentInstance = IriMapperType(Code.literal('DifferentType'), parts);
    });

    test('equals returns true for identical instances', () {
      expect(testInstance, equals(identicalInstance));
    });

    test('equals returns true for same instance', () {
      expect(testInstance, equals(testInstance));
    });

    test('equals returns false for different instances', () {
      expect(testInstance, isNot(equals(differentInstance)));
    });

    test('equals returns false for non-IriMapperType instances', () {
      expect(testInstance, isNot(equals('not an IriMapperType')));
    });

    test('hashCode is consistent for identical instances', () {
      expect(testInstance.hashCode, equals(identicalInstance.hashCode));
    });

    test('toString returns formatted string representation', () {
      final result = testInstance.toString();
      expect(result, contains('IriMapperType('));
      expect(result, contains('type: TestType'));
      expect(result, contains('parts:'));
    });
  });

  group('IriTemplateInfo', () {
    late IriTemplateInfo testInstance;
    late IriTemplateInfo identicalInstance;
    late IriTemplateInfo differentInstance;

    setUp(() {
      final variables = {
        VariableName(
          dartPropertyName: 'prop1',
          name: 'var1',
          canBeUri: true,
        ),
      };

      final propertyVariables = {
        VariableName(
          dartPropertyName: 'prop1',
          name: 'var1',
          canBeUri: true,
        ),
      };

      final contextVariables = <VariableName>{};

      testInstance = IriTemplateInfo(
        template: 'test-template',
        variables: variables,
        propertyVariables: propertyVariables,
        contextVariables: contextVariables,
        isValid: true,
        validationErrors: const ['error1'],
        warnings: const ['warning1'],
      );

      identicalInstance = IriTemplateInfo(
        template: 'test-template',
        variables: variables,
        propertyVariables: propertyVariables,
        contextVariables: contextVariables,
        isValid: true,
        validationErrors: const ['error1'],
        warnings: const ['warning1'],
      );

      differentInstance = IriTemplateInfo(
        template: 'different-template',
        variables: variables,
        propertyVariables: propertyVariables,
        contextVariables: contextVariables,
        isValid: true,
        validationErrors: const ['error1'],
        warnings: const ['warning1'],
      );
    });

    test('equals returns true for identical instances', () {
      expect(testInstance, equals(identicalInstance));
    });

    test('equals returns true for same instance', () {
      expect(testInstance, equals(testInstance));
    });

    test('equals returns false for different instances', () {
      expect(testInstance, isNot(equals(differentInstance)));
    });

    test('equals returns false for non-IriTemplateInfo instances', () {
      expect(testInstance, isNot(equals('not an IriTemplateInfo')));
    });

    test('hashCode is consistent for identical instances', () {
      expect(testInstance.hashCode, equals(identicalInstance.hashCode));
    });

    test('variables getter returns correct set', () {
      expect(testInstance.variables, contains('var1'));
    });

    test('contextVariables getter returns correct set', () {
      expect(testInstance.contextVariables, isEmpty);
    });

    test('toString returns formatted string representation', () {
      final result = testInstance.toString();
      expect(result, contains('IriTemplateInfo('));
      expect(result, contains('template: test-template'));
      expect(result, contains('isValid: true'));
    });
  });

  group('RdfResourceInfo', () {
    test('equals and hashCode work correctly for RdfGlobalResourceInfo', () {
      const instance1 = RdfGlobalResourceInfo(
        classIri: null,
        iri: null,
        registerGlobally: true,
        mapper: null,
      );

      const instance2 = RdfGlobalResourceInfo(
        classIri: null,
        iri: null,
        registerGlobally: true,
        mapper: null,
      );

      const differentInstance = RdfGlobalResourceInfo(
        classIri: null,
        iri: null,
        registerGlobally: false,
        mapper: null,
      );

      expect(instance1, equals(instance2));
      expect(instance1.hashCode, equals(instance2.hashCode));
      expect(instance1, isNot(equals(differentInstance)));
    });

    test('equals returns false for non-RdfResourceInfo instances', () {
      const instance = RdfGlobalResourceInfo(
        classIri: null,
        iri: null,
        registerGlobally: true,
        mapper: null,
      );

      expect(instance, isNot(equals('not an RdfResourceInfo')));
    });
  });

  group('RdfIriInfo', () {
    test('equals and hashCode work correctly', () {
      const instance1 = RdfIriInfo(
        registerGlobally: true,
        mapper: null,
        template: 'template1',
        iriParts: [],
        templateInfo: null,
      );

      const instance2 = RdfIriInfo(
        registerGlobally: true,
        mapper: null,
        template: 'template1',
        iriParts: [],
        templateInfo: null,
      );

      const differentInstance = RdfIriInfo(
        registerGlobally: true,
        mapper: null,
        template: 'template2',
        iriParts: [],
        templateInfo: null,
      );

      expect(instance1, equals(instance2));
      expect(instance1.hashCode, equals(instance2.hashCode));
      expect(instance1, isNot(equals(differentInstance)));
    });

    test('equals returns false for non-RdfIriInfo instances', () {
      const instance = RdfIriInfo(
        registerGlobally: true,
        mapper: null,
        template: 'template1',
        iriParts: [],
        templateInfo: null,
      );

      expect(instance, isNot(equals('not an RdfIriInfo')));
    });
  });

  group('RdfLiteralInfo', () {
    test('equals and hashCode work correctly', () {
      const instance1 = RdfLiteralInfo(
        registerGlobally: true,
        mapper: null,
        fromLiteralTermMethod: null,
        toLiteralTermMethod: null,
        datatype: null,
      );

      const instance2 = RdfLiteralInfo(
        registerGlobally: true,
        mapper: null,
        fromLiteralTermMethod: null,
        toLiteralTermMethod: null,
        datatype: null,
      );

      const differentInstance = RdfLiteralInfo(
        registerGlobally: false,
        mapper: null,
        fromLiteralTermMethod: null,
        toLiteralTermMethod: null,
        datatype: null,
      );

      expect(instance1, equals(instance2));
      expect(instance1.hashCode, equals(instance2.hashCode));
      expect(instance1, isNot(equals(differentInstance)));
    });

    test('equals returns false for non-RdfLiteralInfo instances', () {
      const instance = RdfLiteralInfo(
        registerGlobally: true,
        mapper: null,
        fromLiteralTermMethod: null,
        toLiteralTermMethod: null,
        datatype: null,
      );

      expect(instance, isNot(equals('not an RdfLiteralInfo')));
    });
  });

  group('RdfGlobalResourceInfo', () {
    test('equals and hashCode work correctly', () {
      const instance1 = RdfGlobalResourceInfo(
        classIri: null,
        iri: null,
        registerGlobally: true,
        mapper: null,
      );

      const instance2 = RdfGlobalResourceInfo(
        classIri: null,
        iri: null,
        registerGlobally: true,
        mapper: null,
      );

      const differentInstance = RdfGlobalResourceInfo(
        classIri: null,
        iri: null,
        registerGlobally: false,
        mapper: null,
      );

      expect(instance1, equals(instance2));
      expect(instance1.hashCode, equals(instance2.hashCode));
      expect(instance1, isNot(equals(differentInstance)));
    });

    test('equals returns false for non-RdfGlobalResourceInfo instances', () {
      const instance = RdfGlobalResourceInfo(
        classIri: null,
        iri: null,
        registerGlobally: true,
        mapper: null,
      );

      expect(instance, isNot(equals('not an RdfGlobalResourceInfo')));
    });
  });

  group('RdfLocalResourceInfo', () {
    test('equals and hashCode work correctly', () {
      const instance1 = RdfLocalResourceInfo(
        classIri: null,
        registerGlobally: true,
        mapper: null,
      );

      const instance2 = RdfLocalResourceInfo(
        classIri: null,
        registerGlobally: true,
        mapper: null,
      );

      const differentInstance = RdfLocalResourceInfo(
        classIri: null,
        registerGlobally: false,
        mapper: null,
      );

      expect(instance1, equals(instance2));
      expect(instance1.hashCode, equals(instance2.hashCode));
      expect(instance1, isNot(equals(differentInstance)));
    });

    test('equals returns false for non-RdfLocalResourceInfo instances', () {
      const instance = RdfLocalResourceInfo(
        classIri: null,
        registerGlobally: true,
        mapper: null,
      );

      expect(instance, isNot(equals('not an RdfLocalResourceInfo')));
    });
  });

  group('ConstructorInfo', () {
    late ConstructorInfo testInstance;
    late ConstructorInfo identicalInstance;
    late ConstructorInfo differentInstance;

    setUp(() {
      const parameters = <ParameterInfo>[];

      testInstance = ConstructorInfo(
        name: 'testConstructor',
        isFactory: false,
        isConst: true,
        isDefaultConstructor: false,
        parameters: parameters,
      );

      identicalInstance = ConstructorInfo(
        name: 'testConstructor',
        isFactory: false,
        isConst: true,
        isDefaultConstructor: false,
        parameters: parameters,
      );

      differentInstance = ConstructorInfo(
        name: 'differentConstructor',
        isFactory: false,
        isConst: true,
        isDefaultConstructor: false,
        parameters: parameters,
      );
    });

    test('equals returns true for identical instances', () {
      expect(testInstance, equals(identicalInstance));
    });

    test('equals returns false for different instances', () {
      expect(testInstance, isNot(equals(differentInstance)));
    });

    test('equals returns false for non-ConstructorInfo instances', () {
      expect(testInstance, isNot(equals('not a ConstructorInfo')));
    });

    test('hashCode is consistent for identical instances', () {
      expect(testInstance.hashCode, equals(identicalInstance.hashCode));
    });

    test('toString returns formatted string representation', () {
      final result = testInstance.toString();
      expect(result, contains('ConstructorInfo{'));
      expect(result, contains('name: testConstructor'));
      expect(result, contains('isFactory: false'));
      expect(result, contains('isConst: true'));
      expect(result, contains('isDefaultConstructor: false'));
    });
  });

  group('ParameterInfo', () {
    late ParameterInfo testInstance;
    late ParameterInfo identicalInstance;
    late ParameterInfo differentInstance;

    setUp(() {
      testInstance = ParameterInfo(
        name: 'testParam',
        type: Code.literal('String'),
        isRequired: true,
        isNamed: false,
        isPositional: true,
        isOptional: false,
        propertyInfo: null,
        isIriPart: false,
        iriPartName: null,
        isRdfValue: false,
        isRdfLanguageTag: false,
      );

      identicalInstance = ParameterInfo(
        name: 'testParam',
        type: Code.literal('String'),
        isRequired: true,
        isNamed: false,
        isPositional: true,
        isOptional: false,
        propertyInfo: null,
        isIriPart: false,
        iriPartName: null,
        isRdfValue: false,
        isRdfLanguageTag: false,
      );

      differentInstance = ParameterInfo(
        name: 'differentParam',
        type: Code.literal('String'),
        isRequired: true,
        isNamed: false,
        isPositional: true,
        isOptional: false,
        propertyInfo: null,
        isIriPart: false,
        iriPartName: null,
        isRdfValue: false,
        isRdfLanguageTag: false,
      );
    });

    test('equals returns true for identical instances', () {
      expect(testInstance, equals(identicalInstance));
    });

    test('equals returns false for different instances', () {
      expect(testInstance, isNot(equals(differentInstance)));
    });

    test('equals returns false for non-ParameterInfo instances', () {
      expect(testInstance, isNot(equals('not a ParameterInfo')));
    });

    test('hashCode is consistent for identical instances', () {
      expect(testInstance.hashCode, equals(identicalInstance.hashCode));
    });

    test('toString returns formatted string representation', () {
      final result = testInstance.toString();
      expect(result, contains('ParameterInfo{'));
      expect(result, contains('name: testParam'));
      expect(result, contains('type: String'));
      expect(result, contains('isRequired: true'));
    });
  });

  group('FieldInfo', () {
    late PropertyInfo testInstance;
    late PropertyInfo identicalInstance;
    late PropertyInfo differentInstance;

    setUp(() {
      testInstance = PropertyInfo(
          name: 'testField',
          type: Code.literal('String'),
          isFinal: true,
          isLate: false,
          hasInitializer: false,
          isStatic: false,
          isSynthetic: false,
          isRdfValue: false,
          isRdfLanguageTag: false,
          propertyInfo: null,
          isRequired: true,
          iriPart: null,
          provides: null,
          typeNonNull: null,
          isSettable: true);

      identicalInstance = PropertyInfo(
          name: 'testField',
          type: Code.literal('String'),
          isFinal: true,
          isLate: false,
          hasInitializer: false,
          isStatic: false,
          isSynthetic: false,
          isRdfValue: false,
          isRdfLanguageTag: false,
          propertyInfo: null,
          isRequired: true,
          iriPart: null,
          provides: null,
          typeNonNull: null,
          isSettable: true);

      differentInstance = PropertyInfo(
          name: 'differentField',
          type: Code.literal('String'),
          isFinal: true,
          isLate: false,
          hasInitializer: false,
          isStatic: false,
          isSynthetic: false,
          isRdfValue: false,
          isRdfLanguageTag: false,
          propertyInfo: null,
          isRequired: true,
          iriPart: null,
          provides: null,
          typeNonNull: null,
          isSettable: true);
    });

    test('equals returns true for identical instances', () {
      expect(testInstance, equals(identicalInstance));
    });

    test('equals returns false for different instances', () {
      expect(testInstance, isNot(equals(differentInstance)));
    });

    test('equals returns false for non-FieldInfo instances', () {
      expect(testInstance, isNot(equals('not a FieldInfo')));
    });

    test('hashCode is consistent for identical instances', () {
      expect(testInstance.hashCode, equals(identicalInstance.hashCode));
    });

    test('toString returns formatted string representation', () {
      final result = testInstance.toString();
      expect(result, contains('FieldInfo{'));
      expect(result, contains('name: testField'));
      expect(result, contains('type: String'));
      expect(result, contains('isFinal: true'));
      expect(result, contains('isRequired: true'));
    });
  });

  group('ProvidesInfo', () {
    test('equals and hashCode work correctly', () {
      final instance1 = ProvidesAnnotationInfo(
        name: 'testProvides',
        dartPropertyName: 'testProperty',
      );

      final instance2 = ProvidesAnnotationInfo(
        name: 'testProvides',
        dartPropertyName: 'testProperty',
      );

      final differentInstance = ProvidesAnnotationInfo(
        name: 'differentProvides',
        dartPropertyName: 'testProperty',
      );

      expect(instance1, equals(instance2));
      expect(instance1.hashCode, equals(instance2.hashCode));
      expect(instance1, isNot(equals(differentInstance)));
    });
  });
}
