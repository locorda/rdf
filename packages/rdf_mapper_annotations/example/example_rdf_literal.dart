import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:rdf_mapper_annotations/rdf_mapper_annotations.dart';
import 'package:rdf_vocabularies_core/rdf.dart';
import 'package:rdf_vocabularies_core/xsd.dart';

// --- Example classes with RdfValue annotation ---

/// Rating class using @RdfValue - everything is delegated to the stars property
@RdfLiteral()
class EnhancedRating {
  @RdfValue()
  final int stars;

  EnhancedRating(this.stars) {
    if (stars < 0 || stars > 5) {
      throw ArgumentError('Rating must be between 0 and 5 stars');
    }
  }
}

/// Example for a class that uses custom conversion methods
@RdfLiteral.custom(
  toLiteralTermMethod: 'formatCelsius',
  fromLiteralTermMethod: 'parse',

  /// If you leave out the datatype, it will be `Xsd.string` by default.
  /// Note that you may have compatibility issues with other RDF libraries
  /// if you use a datatype that is not in the `Xsd` namespace.
  datatype: IriTerm('http://example.org/temperature'),
)
class Temperature {
  final double celsius;

  Temperature(this.celsius);

  // Custom formatting method used by the @RdfLiteral annotation
  LiteralContent formatCelsius() => LiteralContent(
        '$celsius°C',
      );

  // Static method for parsing text back into a Temperature instance
  static Temperature parse(LiteralContent term) {
    return Temperature(double.parse(term.value.replaceAll('°C', '')));
  }
}

// --- Example with Language Tag ---

@RdfLiteral()
class LocalizedText {
  @RdfValue()
  final String text;

  @RdfLanguageTag()
  final String languageTag;

  LocalizedText(this.text, this.languageTag);

  // Convenience constructors for common languages
  LocalizedText.en(String text) : this(text, 'en');
  LocalizedText.de(String text) : this(text, 'de');
  LocalizedText.fr(String text) : this(text, 'fr');
}

// --- Generated Mappers (for demonstration) ---

/// This class would be automatically generated based on EnhancedRating annotations
class GeneratedEnhancedRatingMapper
    implements LiteralTermMapper<EnhancedRating> {
  @override
  IriTerm get datatype => Xsd.string;

  @override
  LiteralTerm toRdfTerm(EnhancedRating rating, SerializationContext context) {
    // The stars property is recognized based on the @RdfValue annotation
    return context.toLiteralTerm(rating.stars);
  }

  @override
  EnhancedRating fromRdfTerm(LiteralTerm term, DeserializationContext context,
      {bool bypassDatatypeCheck = false}) {
    return EnhancedRating(context.fromLiteralTerm<int>(term));
  }
}

/// This class would be automatically generated based on Temperature annotations
class GeneratedTemperatureMapper implements LiteralTermMapper<Temperature> {
  final IriTerm datatype = IriTerm('http://example.org/temperature');
  @override
  LiteralTerm toRdfTerm(Temperature temp, SerializationContext context) {
    return temp.formatCelsius().toLiteralTerm(
          datatype,
        );
  }

  @override
  Temperature fromRdfTerm(LiteralTerm term, DeserializationContext context,
      {bool bypassDatatypeCheck = false}) {
    // Convert back to a Temperature instance with the static parse method
    return Temperature.parse(LiteralContent.fromLiteralTerm(term));
  }
}

/// This class would be automatically generated based on LocalizedText annotations
class GeneratedLocalizedTextMapper implements LiteralTermMapper<LocalizedText> {
  final IriTerm datatype = Rdf.langString;
  @override
  LiteralTerm toRdfTerm(LocalizedText localized, SerializationContext context) {
    // Use the @RdfValue property for the value and @RdfLanguageTag for the language
    var value = localized.text;
    var languageTag = localized.languageTag;

    var term = context.toLiteralTerm(value);
    assert(
      term.datatype == Xsd.string,
      'LocalizedText should be serialized as xsd:string',
    );
    return LiteralTerm.withLanguage(term.value, languageTag);
  }

  @override
  LocalizedText fromRdfTerm(LiteralTerm term, DeserializationContext context,
      {bool bypassDatatypeCheck = false}) {
    // Note that we are using <String> because the term.value is a String -
    // if it was a custom type, we would specify that type here, basically
    // allowing us to use classes like Name, Description etc. if we wanted to
    var value = context.fromLiteralTerm<String>(LiteralTerm(term.value));
    var language = term.language!;
    // Extract both the value and language tag from the RDF term
    return LocalizedText(value, language);
  }
}
