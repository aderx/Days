#!/usr/bin/env bash
set -euo pipefail

level="${1:-patch}"
project_file="Days.xcodeproj/project.pbxproj"

if [[ ! -f "$project_file" ]]; then
  echo "Run this script from the repository root." >&2
  exit 1
fi

current_version="$(
  grep -m 1 "MARKETING_VERSION = " "$project_file" |
  sed -E 's/.*MARKETING_VERSION = ([^;]+);/\1/'
)"

IFS='.' read -r major minor patch <<< "$current_version"
major="${major:-1}"
minor="${minor:-0}"
patch="${patch:-0}"

case "$level" in
  patch)
    patch=$((patch + 1))
    ;;
  minor)
    minor=$((minor + 1))
    patch=0
    ;;
  major)
    major=$((major + 1))
    minor=0
    patch=0
    ;;
  *)
    echo "Usage: $0 [patch|minor|major]" >&2
    exit 1
    ;;
esac

next_version="${major}.${minor}.${patch}"
current_build="$(
  grep -m 1 "CURRENT_PROJECT_VERSION = " "$project_file" |
  sed -E 's/.*CURRENT_PROJECT_VERSION = ([0-9]+);/\1/'
)"
next_build=$((current_build + 1))

NEXT_VERSION="$next_version" NEXT_BUILD="$next_build" perl -0pi -e '
  s/MARKETING_VERSION = [^;]+;/MARKETING_VERSION = $ENV{NEXT_VERSION};/g;
  s/CURRENT_PROJECT_VERSION = [0-9]+;/CURRENT_PROJECT_VERSION = $ENV{NEXT_BUILD};/g;
' "$project_file"

echo "Version: ${current_version} -> ${next_version}"
echo "Build: ${current_build} -> ${next_build}"
