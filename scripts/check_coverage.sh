#!/bin/bash
set -ex

apt-get update && apt-get install -y bc

echo "📊 Calculating JaCoCo code coverage..."

THRESHOLD=${COVERAGE_THRESHOLD:-80}

COVERED=$(grep -A 1 '<counter type="INSTRUCTION"' target/site/jacoco/jacoco.xml \
           | grep -oP 'covered="\K\d+' | paste -sd+ - | bc)

MISSED=$(grep -A 1 '<counter type="INSTRUCTION"' target/site/jacoco/jacoco.xml \
           | grep -oP 'missed="\K\d+' | paste -sd+ - | bc)

TOTAL=$((COVERED + MISSED))
PERCENT=$((COVERED * 100 / TOTAL))

echo "✅ Code coverage = $PERCENT% (threshold = $THRESHOLD%)"

# Write single-line summary to coverage-output/coverage.txt
echo "Code coverage: $PERCENT% (threshold: $THRESHOLD%)"

if [ "$PERCENT" -lt "$THRESHOLD" ]; then
  echo "❌ Coverage below threshold"
  exit 1
else
  echo "✅ Coverage OK"
fi
