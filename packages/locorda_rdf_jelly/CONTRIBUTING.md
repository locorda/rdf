# Contributing to locorda_rdf_jelly

Thank you for your interest in contributing to `locorda_rdf_jelly`! We welcome contributions of all kinds—bug reports, feature requests, documentation improvements, and code.

## How to Contribute

1. **Fork the repository** and create your branch from `main`.
2. **Open an issue** to discuss your idea, bug, or feature request if it is significant.
3. **Write tests** for any new features or bug fixes.
4. **Run `dart analyze` and `dart test`** to ensure code quality and correctness.
5. **Submit a pull request** with a clear description of your changes and why they are needed.

## Conformance Testing

This package includes the official [Jelly-RDF conformance test suite](https://w3id.org/jelly/dev/specification/conformance). To run it:

```sh
dart test test/src/jelly_from_jelly_test.dart test/src/jelly_to_jelly_test.dart
```

### Generating the EARL Conformance Report

To generate an [EARL 1.0](https://www.w3.org/TR/EARL10-Schema/) report for submission to the [Jelly-RDF conformance reports](https://github.com/Jelly-RDF/jelly-rdf.github.io/tree/main/docs/conformance/reports):

```sh
cd packages/locorda_rdf_jelly
dart tool/generate_earl_report.dart            # writes locorda_rdf_jelly.ttl
dart tool/generate_earl_report.dart output.ttl  # custom output path
```

The script runs all 187 conformance tests, marks RDF-star and generalized RDF tests as `earl:inapplicable`, and outputs a Turtle file ready for submission via PR.

## Code Style
- Follow Dart best practices and formatting (`dart format`).
- Write clear, concise documentation for public APIs.
- Include usage examples where relevant.

## Community
- Be respectful and constructive in all interactions.
- See the [AI Policy](README.md#ai-policy) for how we leverage generative AI.

## License
By contributing, you agree that your contributions will be licensed under the MIT License.

---

Happy coding!
