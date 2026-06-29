#!/usr/bin/env bash
# validate-skill.sh — Check that SKILL.md meets Agent Skills specification
# Usage: ./tests/validate-skill.sh

set -uo pipefail
# Note: not using set -e because some checks use exit codes intentionally

SKILL_FILE="SKILL.md"
PASS=0
FAIL=0

green() { echo -e "\033[32m✓\033[0m $*"; ((PASS++)); }
red()   { echo -e "\033[31m✗\033[0m $*"; ((FAIL++)); }
info()  { echo -e "\033[34m→\033[0m $*"; }

echo "========================================="
echo "  Skill Scout — Validation"
echo "========================================="
echo ""

# Check SKILL.md exists
if [ -f "$SKILL_FILE" ]; then
    green "SKILL.md exists"
else
    red "SKILL.md not found"
    exit 1
fi

# Check YAML frontmatter delimiters
if head -1 "$SKILL_FILE" | grep -q '^---$'; then
    green "YAML frontmatter opening delimiter (---) found"
else
    red "Missing YAML frontmatter opening delimiter (---)"
fi

# Check second --- delimiter exists (closes frontmatter)
CLOSING_DELIM=$(awk 'NR>1 && /^---$/ {found=1; exit} END {print found+0}' "$SKILL_FILE")
if [ "$CLOSING_DELIM" = "1" ]; then
    green "YAML frontmatter closing delimiter (---) found"
else
    red "Missing YAML frontmatter closing delimiter (---)"
fi

# Required field: name
if grep -m1 '^name:' "$SKILL_FILE" > /dev/null 2>&1; then
    green "Required field 'name' present"
else
    red "Missing required field 'name'"
fi

# Required field: description
if grep -m1 '^description:' "$SKILL_FILE" > /dev/null 2>&1; then
    green "Required field 'description' present"
else
    red "Missing required field 'description'"
fi

# Check description is not empty
DESC_LINE=$(grep -A1 '^description:' "$SKILL_FILE" | tail -1)
DESC_VALUE=$(echo "$DESC_LINE" | wc -c)
if [ "$DESC_VALUE" -gt 10 ]; then
    green "Description has meaningful content"
else
    red "Description may be too short or empty (got: $DESC_LINE)"
fi

# Check that the file has actual instruction content after frontmatter
POST_FM=$(awk '/^---$/{i++; next} i>=2 && !/^[[:space:]]*$/' "$SKILL_FILE" | head -3 | wc -l)
if [ "${POST_FM:-0}" -ge 1 ]; then
    green "File has instruction content after frontmatter"
else
    red "No instruction content found after frontmatter"
fi

# Check for key sections
for section in "Workflow" "Trigger" "Output" "Principles"; do
    if grep -qi "$section" "$SKILL_FILE"; then
        green "Section '$section' found"
    else
        red "Section '$section' may be missing"
    fi
done

# Check keyword-mappings reference exists
if [ -f "references/keyword-mappings.md" ]; then
    green "Reference file references/keyword-mappings.md exists"
else
    red "Reference file references/keyword-mappings.md missing"
fi

# Check README exists
if [ -f "README.md" ]; then
    green "README.md exists"
else
    red "README.md missing"
fi

echo ""
echo "========================================="
echo "  Results: $PASS passed, $FAIL failed"
echo "========================================="

if [ "$FAIL" -gt 0 ]; then
    echo "⚠️  Some checks failed. Review before publishing."
    exit 1
else
    echo "✅ All checks passed! Ready to publish."
    exit 0
fi
