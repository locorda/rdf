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
echo "1. Review the commit: git show HEAD"
echo "2. If changes needed: See CONTRIBUTING.md for manual tag recreation process"
echo "3. Push: git push origin main --tags"
echo "4. Publish: melos publish --no-dry-run"
