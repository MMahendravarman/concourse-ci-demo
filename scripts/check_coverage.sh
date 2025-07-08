#!/bin/bash
set -e

# Ensure bc is installed
apt-get update && apt-get install -y bc

echo "📊 Calculating JaCoCo code coverage..."

THRESHOLD=${COVERAGE_THRESHOLD:-80}
JACOCO_XML="target/site/jacoco/jacoco.xml"

if [ ! -f "$JACOCO_XML" ]; then
  echo "❌ JaCoCo report not found at $JACOCO_XML"
  exit 1
fi

COVERED=$(grep -A 1 '<counter type="INSTRUCTION"' "$JACOCO_XML" \
           | grep -oP 'covered="\K\d+' | paste -sd+ - | bc)

MISSED=$(grep -A 1 '<counter type="INSTRUCTION"' "$JACOCO_XML" \
           | grep -oP 'missed="\K\d+' | paste -sd+ - | bc)

TOTAL=$((COVERED + MISSED))

if [ "$TOTAL" -eq 0 ]; then
  echo "❌ No instructions found in JaCoCo report."
  exit 1
fi

PERCENT=$((COVERED * 100 / TOTAL))

echo "✅ Code coverage = $PERCENT% (threshold = $THRESHOLD%)"
echo "Code coverage: $PERCENT% (threshold: $THRESHOLD%)" > ../coverage-output/coverage.txt

if [ "$PERCENT" -lt "$THRESHOLD" ]; then
  echo "❌ Code coverage ($PERCENT%) is below threshold ($THRESHOLD%)"
  exit 1
else
  echo "✅ Code coverage check passed."
fi
