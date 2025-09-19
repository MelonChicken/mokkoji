#!/bin/bash
# CI Script: Prevent versioned/duplicate filenames
# Usage: ./tools/ci/check_forbidden_filenames.sh

set -e

echo "🔍 Checking for forbidden versioned filenames..."

# Pattern for forbidden filename suffixes
forbidden_pattern="(_v[0-9]+|_old|_copy|_bak|_final|_new|ver[0-9]+)\\.dart$"

# Check if any Dart files match the forbidden pattern
if forbidden_files=$(find lib -name "*.dart" -type f | grep -E "$forbidden_pattern"); then
  echo "❌ FORBIDDEN versioned filenames detected:"
  echo "$forbidden_files"
  echo ""
  echo "📋 Canonical implementations policy:"
  echo "   • Use single canonical file per functionality"
  echo "   • Avoid versioned suffixes like _v2, _old, _new"
  echo "   • See CONTRIBUTING.md for guidelines"
  echo "   • See POLISHING_REPORT.md for migration examples"
  exit 1
fi

echo "✅ No forbidden filenames found"
echo "📝 All Dart files follow canonical naming conventions"