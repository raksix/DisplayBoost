#!/usr/bin/env bash
#
# Verifies that the English documentation under docs/ and the Turkish documentation
# under docs/tr/ stay in sync.
#
# The file names differ between the two trees, so the mapping is explicit. When you add or
# remove a document, update the `pairs` list below and both indexes (docs/README.md and
# docs/tr/README.md).
#
# Usage: bash scripts/check-doc-parity.sh

set -euo pipefail

cd "$(dirname "$0")/.."

pairs=(
  "README.md:README_TR.md"
  "docs/README.md:docs/tr/README.md"
  "docs/00-overview.md:docs/tr/00-genel-bakis.md"
  "docs/01-virtual-display-driver.md:docs/tr/01-sanal-ekran-surucusu.md"
  "docs/02-capture-and-present.md:docs/tr/02-yakalama-ve-sunum.md"
  "docs/03-upscaling.md:docs/tr/03-olcekleme.md"
  "docs/04-prior-art.md:docs/tr/04-benzer-projeler.md"
  "docs/05-risks-and-limitations.md:docs/tr/05-riskler-ve-sinirlar.md"
  "docs/06-roadmap.md:docs/tr/06-yol-haritasi.md"
  "docs/07-references.md:docs/tr/07-kaynaklar.md"
)

failed=0

for pair in "${pairs[@]}"; do
  en="${pair%%:*}"
  tr="${pair##*:}"

  for file in "$en" "$tr"; do
    if [[ ! -f "$file" ]]; then
      echo "::error file=$file::Missing file. The bilingual pair '$en' <-> '$tr' is incomplete."
      failed=1
    fi
  done
done

# Catch a document that exists in one tree but was never registered as a pair.
en_count=$(find docs -maxdepth 1 -name '*.md' | wc -l | tr -d ' ')
tr_count=$(find docs/tr -maxdepth 1 -name '*.md' | wc -l | tr -d ' ')

if [[ "$en_count" != "$tr_count" ]]; then
  echo "::error::docs/ contains $en_count Markdown files but docs/tr/ contains $tr_count."
  echo "Add or remove the translation, then register the pair in scripts/check-doc-parity.sh."
  failed=1
fi

if [[ "$failed" -ne 0 ]]; then
  exit 1
fi

echo "OK: all ${#pairs[@]} document pairs are present (docs/: $en_count files, docs/tr/: $tr_count files)."
