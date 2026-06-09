#!/usr/bin/env bash
#
# install.sh — install the AI Design System Skills into ~/.claude/skills/
#
# Usage: bash install.sh
#
# Idempotent: re-running overwrites the skills with the latest version
# in this repo. Existing user skills (not in this pack) are left alone.

set -euo pipefail

SKILLS=(
  # Tier 1 — Bootstrap
  library-scaffold
  figma-readiness-check
  figma-tokens-extract
  codebase-conventions-scan

  # Tier 2 — Component loop
  component-from-figma
  manifest-styling-from-css
  verify-component
  showcase-page-generator
  screenshot-diff
  next-component-to-build

  # Tier 3 — Quality + prototyping
  library-lint
  demo-compliance-scanner
  token-drift-check
  figma-batch-probe
  prototype-from-brief
)

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="${HOME}/.claude/skills"

if [[ ! -d "${REPO_DIR}/skills" ]]; then
  echo "❌ Could not find a 'skills/' folder next to this script."
  echo "   Are you running it from inside a clone of ai-design-system-skills?"
  exit 1
fi

mkdir -p "${TARGET_DIR}"

echo "Installing AI Design System Skills → ${TARGET_DIR}"
echo

for skill in "${SKILLS[@]}"; do
  src="${REPO_DIR}/skills/${skill}"
  dst="${TARGET_DIR}/${skill}"

  if [[ ! -d "${src}" ]]; then
    echo "⚠️  Missing in repo: ${skill}  (skipping)"
    continue
  fi

  rm -rf "${dst}"
  cp -R "${src}" "${dst}"
  echo "✅ ${skill}"
done

echo
echo "All done. Open a fresh Claude Code session and try:"
echo "  \"List all skills available to me right now.\""
echo
echo "If you don't see the fifteen design-system skills, restart Claude Code."
