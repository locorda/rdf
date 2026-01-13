import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:rdf_mapper_annotations/rdf_mapper_annotations.dart';
import 'package:rdf_vocabularies_core/xsd.dart';

@RdfLiteral()
class LiteralString {
  @RdfValue()
  final String foo;
  LiteralString({required this.foo});
}

@RdfLiteral()
class Rating {
  @RdfValue() // Marks this property as the source for the literal value
  final int stars;

  Rating(this.stars) {
    if (stars < 0 || stars > 5) {
      throw ArgumentError('Rating must be between 0 and 5 stars');
    }
  }
}

@RdfLiteral()
class LocalizedText {
  @RdfValue()
  final String text;

  @RdfLanguageTag()
  final String language;

  LocalizedText(this.text, this.language);
}

@RdfLiteral(Xsd.double)
class LiteralDouble {
  @RdfValue()
  final double foo;
  LiteralDouble({required this.foo});
}

@RdfLiteral(Xsd.integer)
class LiteralInteger {
  @RdfValue()
  final int value;
  LiteralInteger({required this.value});
}

@RdfLiteral.custom(
  toLiteralTermMethod: 'formatCelsius',
  fromLiteralTermMethod: 'parse',
)
class Temperature {
  final double celsius;

  Temperature(this.celsius);

  // Instance method for serialization
  LiteralContent formatCelsius() => LiteralContent('$celsius°C');

  // Static method for deserialization
  static Temperature parse(LiteralContent term) =>
      Temperature(double.parse(term.value.replaceAll('°C', '')));
}

@RdfLiteral.custom(
  toLiteralTermMethod: 'toRdf',
  fromLiteralTermMethod: 'fromRdf',
)
class CustomLocalizedText {
  final String text;
  final String language;
  CustomLocalizedText(this.text, this.language);

  // Instance method for serialization
  LiteralContent toRdf() => LiteralContent.withLanguage(text, language);

  // Static method for deserialization
  static CustomLocalizedText fromRdf(LiteralContent term) =>
      CustomLocalizedText(term.value, term.language ?? 'en');
}

@RdfLiteral.custom(
  toLiteralTermMethod: 'toMilliunit',
  fromLiteralTermMethod: 'fromMilliunit',
  datatype: Xsd.int,
)
class DoubleAsMilliunit {
  final double value;

  DoubleAsMilliunit(this.value);

  // Instance method for serialization
  LiteralContent toMilliunit() =>
      LiteralContent((value * 1000).round().toString());

  // Static method for deserialization
  static DoubleAsMilliunit fromMilliunit(LiteralContent term) =>
      DoubleAsMilliunit(int.parse(term.value) / 1000.0);
}

@RdfLiteral.namedMapper('testLiteralMapper')
class LiteralWithNamedMapper {
  final String value;

  LiteralWithNamedMapper(this.value);
}

@RdfLiteral.mapper(TestLiteralMapper)
class LiteralWithMapper {
  final String value;

  LiteralWithMapper(this.value);
}

@RdfLiteral.mapperInstance(TestLiteralMapper2())
class LiteralWithMapperInstance {
  final String value;

  LiteralWithMapperInstance(this.value);
}

class TestLiteralMapper implements LiteralTermMapper<LiteralWithMapper> {
  final IriTerm? datatype = null;
  const TestLiteralMapper();

  @override
  LiteralWithMapper fromRdfTerm(
    LiteralTerm term,
    DeserializationContext context, {
    bool bypassDatatypeCheck = false,
  }) {
    return LiteralWithMapper(term.value);
  }

  @override
  LiteralTerm toRdfTerm(LiteralWithMapper value, SerializationContext context) {
    return LiteralTerm(value.value);
  }
}

class TestLiteralMapper2
    implements LiteralTermMapper<LiteralWithMapperInstance> {
  final IriTerm? datatype = null;
  const TestLiteralMapper2();

  @override
  LiteralWithMapperInstance fromRdfTerm(
    LiteralTerm term,
    DeserializationContext context, {
    bool bypassDatatypeCheck = false,
  }) {
    return LiteralWithMapperInstance(term.value);
  }

  @override
  LiteralTerm toRdfTerm(
    LiteralWithMapperInstance value,
    SerializationContext context,
  ) {
    return LiteralTerm(value.value);
  }
}

@RdfLiteral()
class LiteralWithNonConstructorValue {
  @RdfValue()
  late final String value;

  LiteralWithNonConstructorValue();
}

@RdfLiteral()
class LocalizedTextWithNonConstructorLanguage {
  @RdfValue()
  final String text;

  @RdfLanguageTag()
  late final String language;

  LocalizedTextWithNonConstructorLanguage(this.text);
}

@RdfLiteral()
class LiteralLateFinalLocalizedText {
  @RdfValue()
  late final String baseValue;

  @RdfLanguageTag()
  late final String language;
}
