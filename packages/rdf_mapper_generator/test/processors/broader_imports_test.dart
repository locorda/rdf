import 'package:test/test.dart';
import 'package:rdf_mapper_generator/src/processors/broader_imports.dart';
import 'package:rdf_mapper_generator/src/analyzer_wrapper/analyzer_wrapper_models.dart';

/// Tests for circular import handling in BroaderImports
void main() {
  group('BroaderImports Circular Reference Tests', () {
    test('should handle circular exports without infinite recursion', () {
      // Create mock libraries with circular exports
      final mockLibrary = MockLibraryElement();
      final mockImportedLibrary = MockLibraryElement();
      final mockExportLibrary = MockLibraryElement();

      // Set up circular reference: library imports mockImportedLibrary, which exports mockExportLibrary, which exports mockImportedLibrary
      mockLibrary.identifier = 'test:main';
      mockImportedLibrary.identifier = 'test:imported';
      mockExportLibrary.identifier = 'test:exported';

      mockLibrary.importedLibraries = [mockImportedLibrary];
      mockImportedLibrary.exportedLibraries = [mockExportLibrary];
      mockExportLibrary.exportedLibraries = [
        mockImportedLibrary
      ]; // circular reference

      // This should not cause infinite recursion
      final broaderImports = BroaderImports.create(mockLibrary);

      // Verify the result contains the exported library
      expect(broaderImports['test:exported'], equals('test:imported'));
    });

    test('should handle complex circular exports with multiple libraries', () {
      // Create mock libraries with complex circular references
      final libMain = MockLibraryElement();
      final libA = MockLibraryElement();
      final libB = MockLibraryElement();
      final libC = MockLibraryElement();

      libMain.identifier = 'test:main';
      libA.identifier = 'test:libA';
      libB.identifier = 'test:libB';
      libC.identifier = 'test:libC';

      // Set up complex circular reference: main imports A, A exports B, B exports C, C exports A
      libMain.importedLibraries = [libA];
      libA.exportedLibraries = [libB];
      libB.exportedLibraries = [libC];
      libC.exportedLibraries = [libA]; // circular back to A

      // This should not cause infinite recursion
      final broaderImports = BroaderImports.create(libMain);

      // Verify the result contains libraries in the export chain
      expect(broaderImports['test:libB'], equals('test:libA'));
      expect(broaderImports['test:libC'], equals('test:libA'));
      // Note: The circular reference to A should be handled
      expect(broaderImports['test:libA'], equals('test:libA'));
    });

    test('should handle self-referencing library', () {
      // Create a library that imports another library that exports itself
      final mainLib = MockLibraryElement();
      final selfRefLib = MockLibraryElement();

      mainLib.identifier = 'test:main';
      selfRefLib.identifier = 'test:selfRef';

      mainLib.importedLibraries = [selfRefLib];
      selfRefLib.exportedLibraries = [selfRefLib]; // self-reference

      // This should not cause infinite recursion
      final broaderImports = BroaderImports.create(mainLib);

      // The result should handle the self-reference appropriately
      expect(broaderImports['test:selfRef'], equals('test:selfRef'));
    });

    test('should handle deep circular chains efficiently', () {
      // Create a deep circular chain to test performance
      final mainLib = MockLibraryElement();
      final libs = List.generate(50, (i) => MockLibraryElement());

      mainLib.identifier = 'test:main';
      for (int i = 0; i < libs.length; i++) {
        libs[i].identifier = 'test:lib$i';
      }

      // Set up chain: main imports lib0, lib0 exports lib1, lib1 exports lib2, ..., lib49 exports lib0
      mainLib.importedLibraries = [libs[0]];
      for (int i = 0; i < libs.length - 1; i++) {
        libs[i].exportedLibraries = [libs[i + 1]];
      }
      libs[libs.length - 1].exportedLibraries = [
        libs[0]
      ]; // circular back to lib0

      // This should not cause infinite recursion and should complete quickly
      final stopwatch = Stopwatch()..start();
      final broaderImports = BroaderImports.create(mainLib);
      stopwatch.stop();

      // Should complete in reasonable time (less than 1 second)
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));

      // Verify some mappings exist
      expect(broaderImports['test:lib1'], equals('test:lib0'));
      expect(broaderImports['test:lib25'], equals('test:lib0'));
    });

    test('should handle multiple imports with circular exports', () {
      // Test case where main library imports multiple libraries that have circular exports
      final mainLib = MockLibraryElement();
      final libA = MockLibraryElement();
      final libB = MockLibraryElement();
      final libC = MockLibraryElement();
      final libD = MockLibraryElement();

      mainLib.identifier = 'test:main';
      libA.identifier = 'test:libA';
      libB.identifier = 'test:libB';
      libC.identifier = 'test:libC';
      libD.identifier = 'test:libD';

      // Main imports both A and C
      mainLib.importedLibraries = [libA, libC];

      // Set up circular reference: A exports B, B exports A (circular)
      libA.exportedLibraries = [libB];
      libB.exportedLibraries = [libA];

      // Set up another circular reference: C exports D, D exports C (circular)
      libC.exportedLibraries = [libD];
      libD.exportedLibraries = [libC];

      // This should not cause infinite recursion
      final broaderImports = BroaderImports.create(mainLib);

      // Verify both circular chains are handled
      expect(broaderImports['test:libB'], equals('test:libA'));
      expect(broaderImports['test:libA'], equals('test:libA'));
      expect(broaderImports['test:libD'], equals('test:libC'));
      expect(broaderImports['test:libC'], equals('test:libC'));
    });
  });

  group('BroaderImports Transitive Import Chain Tests', () {
    test('should handle import->import->export chain', () {
      // Scenario: Main imports Annotations, Annotations imports Core, Core exports Src
      // Expected: Src should map to Core (the library that directly exports it)
      final mainLib = MockLibraryElement();
      final annotationsLib = MockLibraryElement();
      final coreLib = MockLibraryElement();
      final srcLib = MockLibraryElement();

      mainLib.identifier = 'package:test_project/models.dart';
      annotationsLib.identifier = 'package:my_annotations/my_annotations.dart';
      coreLib.identifier = 'package:my_core/my_core.dart';
      srcLib.identifier = 'package:my_core/src/config.dart';

      mainLib.importedLibraries = [annotationsLib];
      annotationsLib.importedLibraries = [coreLib];
      coreLib.exportedLibraries = [srcLib];

      final broaderImports = BroaderImports.create(mainLib);

      // The src library should map to the core library (which exports it)
      expect(broaderImports['package:my_core/src/config.dart'],
          equals('package:my_core/my_core.dart'),
          reason:
              'Src imports should map to the library that directly exports them');
    });

    test('should handle direct import->export chain', () {
      // Scenario: Main imports Core, Core exports Src
      // Expected: Src should map to Core
      final mainLib = MockLibraryElement();
      final coreLib = MockLibraryElement();
      final srcLib = MockLibraryElement();

      mainLib.identifier = 'package:test_project/models.dart';
      coreLib.identifier = 'package:my_core/my_core.dart';
      srcLib.identifier = 'package:my_core/src/config.dart';

      mainLib.importedLibraries = [coreLib];
      coreLib.exportedLibraries = [srcLib];

      final broaderImports = BroaderImports.create(mainLib);

      expect(broaderImports['package:my_core/src/config.dart'],
          equals('package:my_core/my_core.dart'),
          reason: 'Direct export should map src to the exporting library');
    });

    test('should handle deep transitive chains', () {
      // Scenario: Main -> A -> B -> C (exports) -> Src
      // Expected: Src should map to C
      final mainLib = MockLibraryElement();
      final libA = MockLibraryElement();
      final libB = MockLibraryElement();
      final libC = MockLibraryElement();
      final srcLib = MockLibraryElement();

      mainLib.identifier = 'package:test/main.dart';
      libA.identifier = 'package:a/a.dart';
      libB.identifier = 'package:b/b.dart';
      libC.identifier = 'package:c/c.dart';
      srcLib.identifier = 'package:c/src/internal.dart';

      mainLib.importedLibraries = [libA];
      libA.importedLibraries = [libB];
      libB.importedLibraries = [libC];
      libC.exportedLibraries = [srcLib];

      final broaderImports = BroaderImports.create(mainLib);

      expect(broaderImports['package:c/src/internal.dart'],
          equals('package:c/c.dart'),
          reason:
              'Deep transitive import should map to the actual exporting library');
    });

    test('should not map unrelated imports', () {
      // Scenario: Main imports A and B, A imports C, B exports D
      // Expected: D should map to B, but C should not be mapped anywhere
      final mainLib = MockLibraryElement();
      final libA = MockLibraryElement();
      final libB = MockLibraryElement();
      final libC = MockLibraryElement();
      final libD = MockLibraryElement();

      mainLib.identifier = 'package:test/main.dart';
      libA.identifier = 'package:a/a.dart';
      libB.identifier = 'package:b/b.dart';
      libC.identifier = 'package:c/c.dart';
      libD.identifier = 'package:b/src/d.dart';

      mainLib.importedLibraries = [libA, libB];
      libA.importedLibraries = [libC];
      libB.exportedLibraries = [libD];

      final broaderImports = BroaderImports.create(mainLib);

      // D should map to B (its exporter)
      expect(
          broaderImports['package:b/src/d.dart'], equals('package:b/b.dart'));

      // C should not be mapped anywhere since it's not exported
      expect(broaderImports['package:c/c.dart'], isNull,
          reason: 'Imported but not exported libraries should not be mapped');
    });

    test('should handle multiple export chains from same import', () {
      // Scenario: Main imports A, A exports B and C
      // Expected: Both B and C should map to A
      final mainLib = MockLibraryElement();
      final libA = MockLibraryElement();
      final libB = MockLibraryElement();
      final libC = MockLibraryElement();

      mainLib.identifier = 'package:test/main.dart';
      libA.identifier = 'package:a/a.dart';
      libB.identifier = 'package:a/src/b.dart';
      libC.identifier = 'package:a/src/c.dart';

      mainLib.importedLibraries = [libA];
      libA.exportedLibraries = [libB, libC];

      final broaderImports = BroaderImports.create(mainLib);

      expect(
          broaderImports['package:a/src/b.dart'], equals('package:a/a.dart'));
      expect(
          broaderImports['package:a/src/c.dart'], equals('package:a/a.dart'));
    });
  });
}

/// Mock implementation of LibraryElem for testing
class MockLibraryElement implements LibraryElem {
  String identifier = '';

  Iterable<LibraryElem> exportedLibraries = [];

  Iterable<LibraryElem> importedLibraries = [];

  Iterable<LibraryImport> libraryImports = [];

  Iterable<ClassElem> classes = [];

  Iterable<EnumElem> enums = [];

  ClassElem? getClass(String className) => null;

  EnumElem? getEnum(String enumName) => null;

  // For this test, we don't need to implement other methods
  dynamic noSuchMethod(Invocation invocation) => null;
}
