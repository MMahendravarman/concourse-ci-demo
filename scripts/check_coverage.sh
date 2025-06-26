#!/bin/bash
set -e

# === CONFIGURATION ===
THRESHOLD=${COVERAGE_THRESHOLD:-80}

# === Get PR Number from github-pr-resource metadata ===
PR_NUMBER=$(cat ../pull-request/metadata/pr)

# === Dynamically extract repo owner and name ===
cd ../pull-request
REPO_URL=$(git remote get-url origin)  # e.g., https://github.com/owner/repo.git
REPO_PATH=$(echo "$REPO_URL" | sed -E 's|.*github\.com[:/](.+)\.git|\1|')  # owner/repo
REPO_OWNER=$(echo "$REPO_PATH" | cut -d'/' -f1)
REPO_NAME=$(echo "$REPO_PATH" | cut -d'/' -f2)
cd - > /dev/null

# === Calculate JaCoCo coverage ===
COVERED=$(grep -A 1 '<counter type="INSTRUCTION"' target/site/jacoco/jacoco.xml \
           | grep -oP 'covered="\K\d+' \
           | paste -sd+ - | bc)

MISSED=$(grep -A 1 '<counter type="INSTRUCTION"' target/site/jacoco/jacoco.xml \
           | grep -oP 'missed="\K\d+' \
           | paste -sd+ - | bc)

TOTAL=$((COVERED + MISSED))
PERCENT=$((COVERED * 100 / TOTAL))

echo "Code coverage = $PERCENT% (threshold = $THRESHOLD%)"

# === Post comment to PR ===
COMMENT="Code coverage: **$PERCENT%** (Threshold: $THRESHOLD%)"
API_URL="https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/issues/$PR_NUMBER/comments"

curl -s -X POST "$API_URL" \
  -H "Authorization: token ${GITHUB_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{\"body\": \"$COMMENT\"}"

# === Fail if below threshold ===
if [ "$PERCENT" -lt "$THRESHOLD" ]; then
  echo "❌ Code coverage ($PERCENT%) is below threshold ($THRESHOLD%)"
  exit 1
else
  echo "✅ Code coverage check passed."
fi
