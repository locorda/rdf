#!/usr/bin/env bash

# Release script for Locorda RDF Suite
# Usage: ./release.sh <version>
# Example: ./release.sh 0.11.3

set -e  # Exit on error

if [ -z "$1" ]; then
  echo "Error: Version number required"
  echo "Usage: ./release.sh <version>"
  echo "Example: ./release.sh 0.11.3"
  exit 1
fi

VERSION=$1

echo "🚀 Setting version to $VERSION for all packages..."

dart run melos version \
  -V locorda_rdf_canonicalization:"$VERSION" \
  -V locorda_rdf_core:"$VERSION" \
  -V locorda_rdf_mapper:"$VERSION" \
  -V locorda_rdf_mapper_annotations:"$VERSION" \
  -V locorda_rdf_mapper_generator:"$VERSION" \
  -V locorda_rdf_terms_core:"$VERSION" \
  -V locorda_rdf_terms_generator:"$VERSION" \
  -V locorda_rdf_xml:"$VERSION"

echo "✅ Version updated to $VERSION"
echo ""
echo "Next steps:"
echo "1. Update CHANGELOG.md files"
echo "2. Commit: git add . && git commit -m 'chore: release v$VERSION'"
echo "3. Tag: git tag v$VERSION"
echo "4. Push: git push origin main --tags"
echo "5. Publish: melos publish --no-dry-run"
