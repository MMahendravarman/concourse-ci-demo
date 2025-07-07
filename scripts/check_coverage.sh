#!/bin/bash
set -e

# === CONFIGURATION ===
THRESHOLD=${COVERAGE_THRESHOLD:-80}

echo "🔍 Reading PR metadata..."
PR_NUMBER=$(cat metadata/pr)
PR_TITLE=$(jq -r .title .git/resource/metadata.json)
PR_AUTHOR=$(jq -r .author .git/resource/metadata.json)
BASE_SHA=$(cat .git/resource/base_sha)
HEAD_SHA=$(cat .git/resource/head_sha)

echo "📄 PR #$PR_NUMBER – $PR_TITLE by $PR_AUTHOR"
echo "Base SHA: $BASE_SHA"
echo "Head SHA: $HEAD_SHA"

# === Calculate JaCoCo instruction coverage ===
echo "📊 Calculating code coverage..."
COVERED=$(grep -A 1 '<counter type="INSTRUCTION"' target/site/jacoco/jacoco.xml \
           | grep -oP 'covered="\K\d+' \
           | paste -sd+ - | bc)

MISSED=$(grep -A 1 '<counter type="INSTRUCTION"' target/site/jacoco/jacoco.xml \
           | grep -oP 'missed="\K\d+' \
           | paste -sd+ - | bc)

TOTAL=$((COVERED + MISSED))
PERCENT=$((COVERED * 100 / TOTAL))

echo "✅ Code coverage = $PERCENT% (threshold = $THRESHOLD%)"

# === Dynamically extract repo owner and name ===
REPO_URL=$(git remote get-url origin)  # e.g., https://github.com/owner/repo.git
REPO_PATH=$(echo "$REPO_URL" | sed -E 's|.*github\.com[:/](.+)\.git|\1|')  # owner/repo
REPO_OWNER=$(echo "$REPO_PATH" | cut -d'/' -f1)
REPO_NAME=$(echo "$REPO_PATH" | cut -d'/' -f2)

# === Post comment to PR ===
COMMENT="🧪 **Code coverage:** $PERCENT% (Threshold: $THRESHOLD%)
📄 PR: *$PR_TITLE* by @$PR_AUTHOR
🔀 Commits: $BASE_SHA → $HEAD_SHA"

API_URL="https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/issues/$PR_NUMBER/comments"

echo "💬 Posting comment to PR..."
curl -s -X POST "$API_URL" \
  -H "Authorization: token ${GITHUB_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{\"body\": \"$COMMENT\"}"

# === Fail build if below threshold ===
if [ "$PERCENT" -lt "$THRESHOLD" ]; then
  echo "❌ Code coverage ($PERCENT%) is below threshold ($THRESHOLD%). Failing build."
  exit 1
else
  echo "✅ Code coverage check passed."
fi