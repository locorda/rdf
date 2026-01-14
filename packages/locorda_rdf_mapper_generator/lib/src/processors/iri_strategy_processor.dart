import 'dart:math';

// import 'package:analyzer/dart/constant/value.dart';
// import 'package:analyzer/dart/element/element2.dart';
import 'package:locorda_rdf_mapper/mapper.dart';
import 'package:locorda_rdf_mapper_generator/src/analyzer_wrapper/analyzer_wrapper_models.dart';
import 'package:locorda_rdf_mapper_generator/src/processors/models/base_mapping_info.dart';
import 'package:locorda_rdf_mapper_generator/src/processors/models/mapper_info.dart';
import 'package:locorda_rdf_mapper_generator/src/processors/processor_utils.dart';
import 'package:locorda_rdf_mapper_generator/src/templates/code.dart';
import 'package:locorda_rdf_mapper_generator/src/templates/util.dart';
import 'package:locorda_rdf_mapper_generator/src/validation/validation_context.dart';

/// Processes IRI strategy templates and extracts variable information.
///
/// This processor analyzes IRI templates used in @RdfGlobalResource annotations
/// to extract variables, validate patterns, and categorize variables by their source.
class IriStrategyProcessor {
  static IriStrategyInfo? processIriStrategy(
      ValidationContext context, DartObject iriValue, ClassElem classElement) {
    // Check if we have an iri field (for the standard constructor)
    final templateFieldValue = getField(iriValue, 'template')?.toStringValue();
    final fragmentTemplateFieldValue =
        getField(iriValue, 'fragmentTemplate')?.toStringValue();
    final providedAsFieldValue = getFieldStringValue(iriValue, 'providedAs');
    final mapper = getMapperRefInfo<IriTermMapper>(iriValue);
    final (template, templateInfo, iriParts) =
        processIriPartsAndTemplateWithFragment(context, classElement,
            templateFieldValue, fragmentTemplateFieldValue, mapper);
    final (iriMapperType, typeWarnings) =
        _getIriMapperType(classToCode(classElement), iriParts);
    typeWarnings.forEach(context.addWarning);
    return IriStrategyInfo(
      mapper: mapper,
      template: template,
      fragmentTemplate: fragmentTemplateFieldValue,
      templateInfo: templateInfo,
      iriMapperType: iriMapperType,
      providedAs: providedAsFieldValue,
    );
  }

  static (String?, IriTemplateInfo?, List<IriPartInfo>)
      processIriPartsAndTemplateWithFragment(
          ValidationContext context,
          ClassElem classElement,
          String? template,
          String? fragmentTemplate,
          MapperRefInfo? mapper) {
    final iriParts = findIriPartFields(classElement);
    if (mapper == null && (template == null || template.isEmpty)) {
      if (iriParts.length != 1) {
        context.addError(
            'No @RdfIriPart annotations found, but no custom mapper is specified. If you are using IriStrategy() default constructor without any arguments, you have to provide @RdfIriPart annotation on exactly one field.');
      } else {
        template = '{+${iriParts.first.name}}';
      }
    }

    // Process template if it exists
    IriTemplateInfo? templateInfo = template == null
        ? null
        : processTemplate(context, template, iriParts,
            fragmentTemplate: fragmentTemplate);

    if (templateInfo == null && mapper == null) {
      if (iriParts.length != 1) {
        context.addError(
            'No @RdfIriPart annotations found, but no custom mapper is specified. If you are using IriStrategy() default constructor without any arguments, you have to provide @RdfIriPart annotation on exactly one field.');
      }
    }
    return (template, templateInfo, iriParts);
  }

  static void _warnAboutUnused(
      Iterable<IriPartInfo> unusedIriParts, ValidationContext context) {
    // Generate warning for unused @RdfIriPart annotation
    for (final unused in unusedIriParts) {
      context.addWarning(
          'Property \'${unused.dartPropertyName}\' is annotated with @RdfIriPart(\'${unused.name}\') but \'${unused.name}\' is not used in the IRI template');
    }
  }

  /// Processes IRI templates with fragment support.
  ///
  /// When a fragment template is provided, this function:
  /// 1. Processes the base template to extract its variables
  /// 2. Processes the fragment template to extract its variables
  /// 3. Combines variables from both templates
  /// 4. Returns a unified IriTemplateInfo with combined information
  ///
  /// The base template is stored in the IriTemplateInfo, and the fragment template
  /// is passed separately through the annotation info for use in code generation.
  static IriTemplateInfo? processTemplate(
    ValidationContext context,
    String baseTemplate,
    List<IriPartInfo> iriParts, {
    String? fragmentTemplate,
  }) {
    if (baseTemplate.isEmpty) {
      context.addError('Base IRI template cannot be empty');
      return null;
    }
    if (fragmentTemplate == null) {
      final (r, unused) = _processTemplate(context, baseTemplate, iriParts);
      _warnAboutUnused(unused, context);
      return r;
    }
    if (fragmentTemplate.isEmpty) {
      context.addError('Fragment template cannot be empty');
      return null;
    }

    // Process both templates separately for validation
    final (baseInfo, unused1) =
        _processTemplate(context, baseTemplate, iriParts);
    final (fragmentInfo, unused2) = _processTemplate(
        context, fragmentTemplate, iriParts,
        allowRelative: true);

    if (baseInfo == null || fragmentInfo == null) {
      return null;
    }

    // only iri parts that are unused in both templates are really unused
    final unused = unused1.toSet().intersection(unused2.toSet());
    _warnAboutUnused(unused, context);

    // Combine variables from both templates for dependency tracking
    final combinedVariables = {
      ...baseInfo.variableNames,
      ...fragmentInfo.variableNames
    };
    final combinedPropertyVariables = {
      ...baseInfo.propertyVariables,
      ...fragmentInfo.propertyVariables
    };
    final combinedContextVariables = {
      ...baseInfo.contextVariableNames,
      ...fragmentInfo.contextVariableNames
    };
    final combinedErrors = [
      ...baseInfo.validationErrors,
      ...fragmentInfo.validationErrors
    ];
    final combinedWarnings = [...baseInfo.warnings, ...fragmentInfo.warnings];

    // Store only the base template - fragment will be handled in code generation
    // This avoids validation issues with the synthetic combined template
    return IriTemplateInfo(
      template: baseTemplate,
      fragmentTemplate: fragmentTemplate,
      variables: combinedVariables,
      propertyVariables: combinedPropertyVariables,
      contextVariables: combinedContextVariables,
      isValid: baseInfo.isValid && fragmentInfo.isValid,
      validationErrors: combinedErrors,
      warnings: combinedWarnings,
      iriParts: iriParts,
    );
  }

  /// Processes an IRI template and extracts information about variables and validation.
  ///
  /// Returns an [IriTemplateInfo] containing parsed template data, or null if the
  /// template is invalid or empty.
  static (IriTemplateInfo?, List<IriPartInfo> unusedIriParts) _processTemplate(
      ValidationContext context, String template, List<IriPartInfo> iriParts,
      {bool allowRelative = false}) {
    try {
      if (template.isEmpty) {
        context.addError('IRI template cannot be empty');
        return (null, iriParts);
      }
      final variables = _extractVariables(template);
      final (propertyResult, unusedIriParts) =
          _findPropertyVariables(variables, iriParts);

      final propertyNames =
          propertyResult.propertyVariables.map((pn) => pn.name).toSet();
      final contextVariables = Set.unmodifiable(variables.entries
          .where((entry) => !propertyNames.contains(entry.key))
          .map((entry) => entry.value)
          .toSet());
      final validationResult =
          _validateTemplate(template, variables, allowRelative: allowRelative);
      validationResult.errors.forEach(context.addError);
      validationResult.warnings.forEach(context.addWarning);
      propertyResult.warnings.forEach(context.addWarning);

      return (
        IriTemplateInfo(
          template: template,
          fragmentTemplate: null,
          iriParts: iriParts,
          variables: Set.unmodifiable(
              {...propertyResult.propertyVariables, ...contextVariables}),
          propertyVariables: propertyResult.propertyVariables,
          contextVariables: contextVariables,
          isValid: validationResult.isValid,
          validationErrors: validationResult.errors,
          warnings: propertyResult.warnings,
        ),
        unusedIriParts
      );
    } catch (e) {
      context.addError('Failed to process template: $e');
      return (
        IriTemplateInfo(
          template: template,
          fragmentTemplate: null,
          iriParts: iriParts,
          variables: Set.unmodifiable(<VariableName>{}),
          propertyVariables: Set.unmodifiable(<VariableName>{}),
          contextVariables: Set.unmodifiable(<VariableName>{}),
          isValid: false,
          validationErrors: ['Failed to process template: $e'],
          warnings: [],
        ),
        iriParts
      );
    }
  }

  /// Extracts all variable names from an IRI template.
  ///
  /// Variables are identified by the pattern {variableName} or {+variableName} in the template.
  /// The + prefix ( reserved expansion) is stripped from the variable name.
  /// Returns a set of unique variable names.
  static Map<String, VariableName> _extractVariables(String template) {
    final variables = <String, VariableName>{};
    final regex = RegExp(r'\{([^}]+)\}');
    final matches = regex.allMatches(template);

    for (final match in matches) {
      final variableName = match.group(1);
      if (variableName != null && variableName.isNotEmpty) {
        // Strip the + prefix for RFC 6570 reserved expansion
        final cleanVariableName = variableName.startsWith('+')
            ? variableName.substring(1)
            : variableName;
        variables[cleanVariableName] = VariableName(
            name: cleanVariableName,
            dartPropertyName: cleanVariableName,
            canBeUri: variableName.startsWith('+'));
      }
    }

    return Map.unmodifiable(variables);
  }

  /// Identifies which variables correspond to properties annotated with @RdfIriPart.
  ///
  /// Scans the class element for fields with @RdfIriPart annotations and matches
  /// them against the extracted variables. Also detects unused @RdfIriPart annotations
  /// that don't correspond to any template variable.
  static (_PropertyVariablesResult, List<IriPartInfo> unusedIriParts)
      _findPropertyVariables(
          Map<String, VariableName> variables, List<IriPartInfo> iriParts) {
    final propertyVariables = <VariableName>{};
    final warnings = <String>[];
    final unusedIriParts = <IriPartInfo>[];
    for (final iriPart in iriParts) {
      final name = iriPart.name;
      if (variables.containsKey(name)) {
        final variable = variables[name]!;
        propertyVariables.add(VariableName(
            name: name,
            dartPropertyName: iriPart.dartPropertyName,
            canBeUri: variable.canBeUri,
            isMappedValue: iriPart.isMappedValue));
      } else {
        unusedIriParts.add(iriPart);
      }
    }

    return (
      _PropertyVariablesResult(
        propertyVariables: Set.unmodifiable(propertyVariables),
        warnings: warnings,
      ),
      unusedIriParts
    );
  }

  static List<IriPartInfo> findIriPartFields(ClassElem classElement) {
    final result = <IriPartInfo>[];

    for (final field in classElement.fields) {
      if (field.isStatic || field.isSynthetic) continue;

      // Check for @RdfIriPart annotation
      final annotation =
          extractIriPartAnnotation(field.name, field.annotations);
      if (annotation == null) continue;

      result.add(IriPartInfo(
        name: annotation.name,
        dartPropertyName: field.name,
        type: typeToCode(field.type),
        pos: annotation.pos,
      ));
    }

    return result;
  }

  /// Validates an IRI template for correctness and common issues.
  ///
  /// Checks for:
  /// - Valid URI syntax when variables are substituted
  /// - Proper variable syntax
  /// - No unescaped special characters
  /// - Reasonable URI structure
  static _TemplateValidationResult _validateTemplate(
      String template, Map<String, VariableName> variables,
      {bool allowRelative = false}) {
    final errors = <String>[];
    final warnings = <String>[];

    // Check for basic template syntax issues
    if (!_hasValidVariableSyntax(template)) {
      errors.add(
          'Invalid variable syntax. Variables must be in format {variableName}');
    }

    // Check for unmatched braces
    if (!_hasMatchedBraces(template)) {
      errors.add('Unmatched braces in template');
    }

    // Validate as URI template by substituting variables with dummy values
    final testUri = _createTestUri(template, variables);
    if (!_isValidUriStructure(testUri, allowRelative: allowRelative)) {
      errors.add('Template does not produce valid URI structure');
    }

    // Check for forbidden characters in variable names
    for (final variable in variables.values) {
      if (!_isValidVariableName(variable.name)) {
        errors.add(
            'Invalid variable name: ${variable.name}. Variable names must be valid identifiers');
      }
    }
    if (!allowRelative) {
      // Warn about relative URIs (might be intentional)
      // Templates starting with {+variable} are valid if the variable contains a complete URI
      final startsWithReservedExpansion =
          RegExp(r'^\{\+\w+\}').hasMatch(template);

      // allow arbitrary schemes like mailto:, urn:, tag: etc.
      final startsWithScheme = RegExp(r'^\w+:').hasMatch(template);
      if (!template.contains('://') &&
          !template.startsWith('/') &&
          !startsWithScheme &&
          !startsWithReservedExpansion) {
        warnings.add(
            'Template "$template" appears to be a relative URI. Consider using absolute URIs for global resources');
      }
    }

    return _TemplateValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  /// Checks if the template has valid variable syntax.
  /// Supports both {variable} and {+variable} patterns (RFC 6570).
  static bool _hasValidVariableSyntax(String template) {
    // Check for invalid patterns like {{, }}, {}, { }, etc.
    final invalidPatterns = [
      RegExp(r'\{\{'), // Double opening brace
      RegExp(r'\}\}'), // Double closing brace
      RegExp(r'\{\s*\}'), // Empty braces or braces with only whitespace
      RegExp(r'\{\+\s*\}'), // Empty braces with + prefix
      RegExp(
          r'\{[^a-zA-Z_+][^}]*\}'), // Variables not starting with letter, underscore, or +
      RegExp(
          r'\{\+[^a-zA-Z_][^}]*\}'), // Variables with + not followed by letter or underscore
    ];

    return !invalidPatterns.any((pattern) => pattern.hasMatch(template));
  }

  /// Checks if all braces in the template are properly matched.
  static bool _hasMatchedBraces(String template) {
    int braceCount = 0;

    for (int i = 0; i < template.length; i++) {
      if (template[i] == '{') {
        braceCount++;
      } else if (template[i] == '}') {
        braceCount--;
        if (braceCount < 0) {
          return false; // Closing brace without opening
        }
      }
    }

    return braceCount == 0; // All braces matched
  }

  /// Creates a test URI by substituting variables with dummy values.
  /// Handles both regular {variable} and RFC 6570 {+variable} patterns.
  static String _createTestUri(
      String template, Map<String, VariableName> variables) {
    String testUri = template;

    for (final variable in variables.values) {
      if (variable.canBeUri) {
        testUri =
            testUri.replaceAll('{+${variable.name}}', 'https://example.org');
      } else {
        // Replace regular {variable} patterns with simple test values
        testUri = testUri.replaceAll('{${variable.name}}', 'test_value');
      }
    }

    return testUri;
  }

  /// Validates that the test URI has a reasonable structure.
  static bool _isValidUriStructure(String testUri,
      {bool allowRelative = false}) {
    try {
      final uri = Uri.parse(testUri);
      if (allowRelative) {
        // it parses - that is good enough for relative URI or fragment-only templates
        return true;
      }
      // Basic validation - should have scheme or be absolute path
      if (uri.scheme.isEmpty && !testUri.startsWith('/')) {
        return false;
      }

      // Check for obviously invalid patterns
      if (testUri.contains('//') && !testUri.contains('://')) {
        return false; // Double slashes not following scheme
      }

      // Check for consecutive slashes after the scheme
      if (testUri.contains('://')) {
        final afterScheme = testUri.substring(testUri.indexOf('://') + 3);
        if (afterScheme.contains('//')) {
          return false; // Multiple consecutive slashes in path
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Validates that a variable name is a valid identifier.
  static bool _isValidVariableName(String variable) {
    // Must start with letter or underscore, followed by letters, digits, or underscores
    final regex = RegExp(r'^[a-zA-Z_][a-zA-Z0-9_]*$');
    return regex.hasMatch(variable) && variable.isNotEmpty;
  }

  static (IriMapperType?, List<String>) _getIriMapperType(
      Code resourceClassType, List<IriPartInfo> iriParts) {
    if (iriParts.isEmpty) {
      return (
        IriMapperType(
            Code.combine([
              Code.type('IriTermMapper', importUri: importRdfMapper),
              Code.literal('<'),
              resourceClassType,
              Code.literal('>')
            ]),
            []),
        []
      );
    }
    // Sort by position
    final iriPartFields = [...iriParts]..sort((a, b) => a.pos.compareTo(b.pos));

    // Validate positions
    if (iriPartFields.length > 1) {
      final positions = iriPartFields.map((e) => e.pos).toSet();
      if (positions.length != iriPartFields.length) {
        return (null, ['Duplicate position values in RdfIriPart annotations']);
      }
      final minPos = iriPartFields.map((e) => e.pos).reduce(min);
      if (minPos != 1) {
        return (null, ['RdfIriPart annotations must start at position 1']);
      }
    }

    return (
      IriMapperType(
          Code.combine([
            Code.type('IriTermMapper', importUri: importRdfMapper),
            Code.literal('<('),
            Code.combine(
                iriPartFields
                    .map((f) => Code.combine(
                        [f.type, Code.literal(' ${f.dartPropertyName}')]))
                    .toList(),
                separator: ', '),
            Code.literal(',)>')
          ]),
          List.unmodifiable(iriPartFields)),
      []
    );
  }
}

/// Internal model for template validation results.
class _TemplateValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;

  const _TemplateValidationResult({
    required this.isValid,
    required this.errors,
    required this.warnings,
  });
}

/// Internal model for property variable analysis results.
class _PropertyVariablesResult {
  final Set<VariableName> propertyVariables;
  final List<String> warnings;

  const _PropertyVariablesResult({
    required this.propertyVariables,
    required this.warnings,
  });
}
