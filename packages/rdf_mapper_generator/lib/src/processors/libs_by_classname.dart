// import 'package:analyzer/dart/element/element2.dart';

import 'package:rdf_mapper_generator/src/analyzer_wrapper/analyzer_wrapper_models.dart';

/// Helper class for resolving public library imports by exported class names.
/// This is used during code generation to generate proper import statements
/// for referenced classes and their static members.

class LibsByClassName {
  final Map<String, LibraryElem> _libsByExportedNames;

  LibsByClassName(this._libsByExportedNames);

  /// Gets the library associated with the provided export name.
  ///
  /// Returns the [LibraryElem] for the given export [name],
  /// or null if no library was found with that name.
  LibraryElem? operator [](String name) => _libsByExportedNames[name];

  static LibsByClassName create(LibraryElem libraryElement) {
    final libs = libraryElement.importedLibraries;

    final libsByExportedNames = {
      for (final lib in libs)
        for (final name in lib.exportDefinedNames) name: lib,
    };
    return LibsByClassName(libsByExportedNames);
  }
}
