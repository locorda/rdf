import 'package:locorda_rdf_core/core.dart';

extension QuadBlankNodeExtension on Quad {
  Set<BlankNodeTerm> get blankNodes => {
        if (subject is BlankNodeTerm) subject as BlankNodeTerm,
        if (object is BlankNodeTerm) object as BlankNodeTerm,
        if (graphName is BlankNodeTerm) graphName as BlankNodeTerm,
      };
}
