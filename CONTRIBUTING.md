# Contributing to Locorda RDF Suite

Thank you for your interest in contributing to the Locorda RDF Suite!

## Development Setup

This is a monorepo managed by [Melos](https://melos.invertase.dev/). To get started:

```bash
# Install melos globally
dart pub global activate melos

# Bootstrap the workspace (links local packages and installs dependencies)
melos bootstrap
```

## Release Process

### Version Management

All packages in this monorepo use **synchronized versioning** - they all share the same version number for consistency.

To release a new version, use the provided release script:

```bash
# Set the desired version and apply it to all packages
./release.sh 0.11.3
```

See [release.sh](release.sh) for implementation details.

### Release Steps

1. **Run the release script:**
   ```bash
   ./release.sh <version>
   ```
   
   This will:
   - Update all `pubspec.yaml` files with the new version
   - Update all `CHANGELOG.md` files
   - Create a git commit with the changes
   - Create a git tag `v<version>`

2. **Review the automated commit:**
   ```bash
   # Check what melos changed
   git show HEAD
   
   # If you need to make manual adjustments to CHANGELOGs:
   export VERSION=<version>
   # First, delete the tags melos created
   git tag -d locorda_rdf_canonicalization-v$VERSION
   git tag -d locorda_rdf_core-v$VERSION
   git tag -d locorda_rdf_mapper-v$VERSION
   git tag -d locorda_rdf_mapper_annotations-v$VERSION
   git tag -d locorda_rdf_mapper_generator-v$VERSION
   git tag -d locorda_rdf_terms_core-v$VERSION
   git tag -d locorda_rdf_terms_generator-v$VERSION
   git tag -d locorda_rdf_xml-v$VERSION
   
   # Reset the commit
   git reset --soft HEAD~1
   
   # Make your edits, then commit and manually recreate tags
   git add .
   git commit -m "chore: release v$VERSION"
   git tag locorda_rdf_canonicalization-v$VERSION
   git tag locorda_rdf_core-v$VERSION
   git tag locorda_rdf_mapper-v$VERSION
   git tag locorda_rdf_mapper_annotations-v$VERSION
   git tag locorda_rdf_mapper_generator-v$VERSION
   git tag locorda_rdf_terms_core-v$VERSION
   git tag locorda_rdf_terms_generator-v$VERSION
   git tag locorda_rdf_xml-v$VERSION
   ```

3. **Push to GitHub:**
   ```bash
   git push origin main --tags
   ```

4. **Publish to pub.dev:**
   ```bash
   # Dry run to verify everything
   melos publish --dry-run
   
   # Note: dry-run will show warnings about library naming conventions
   # (e.g., expecting locorda_rdf_mapper_annotations.dart instead of annotations.dart)
   # These can be ignored - we intentionally use shorter import names
   
   # Actual publish
   melos publish --no-dry-run
   ```

## Testing

```bash
# Run all tests (unit + build-runner)
melos run test

# Run build-runner tests (slow, only build_runner tests)
melos run test:build-runner

# Run tests for a specific package
cd packages/<package_name>
dart test
```

**Note:** Integration tests are marked with `tags: ['build-runner']` and involve build_runner code generation, which is significantly slower.

## Code Quality

```bash
# Analyze all packages
melos run analyze

# Format all packages
melos run format
```

## Package-Specific Guidelines

Some packages have their own `CONTRIBUTING.md` with additional guidelines:

- [locorda_rdf_core](packages/locorda_rdf_core/CONTRIBUTING.md)
- [locorda_rdf_mapper](packages/locorda_rdf_mapper/CONTRIBUTING.md)
- [locorda_rdf_mapper_generator](packages/locorda_rdf_mapper_generator/CONTRIBUTING.md)
- [locorda_rdf_canonicalization](packages/locorda_rdf_canonicalization/CONTRIBUTING.md)
- [locorda_rdf_xml](packages/locorda_rdf_xml/CONTRIBUTING.md)

## Questions?

Feel free to open an issue for questions or discussions about contributing.
