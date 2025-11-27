#!/bin/bash

# PRs to process
PRS=()

# Temporary file to store PR data
TEMP_FILE=$(mktemp)
SORTED_FILE=$(mktemp)

echo "Fetching merge commit information..."

# For each PR, find the merge commit and its date
for pr in "${PRS[@]}"; do
    # Find merge commit for this PR
    COMMIT=$(git log --merges --all --grep="Merge pull request #${pr}" --format="%H|%ci|%s" | head -1)

    if [ -n "$COMMIT" ]; then
        echo "$COMMIT|$pr" >> "$TEMP_FILE"
        echo "Found PR #${pr}"
    else
        echo "WARNING: Could not find merge commit for PR #${pr}"
    fi
done

# Sort by date and save to a file
sort -t'|' -k2 "$TEMP_FILE" > "$SORTED_FILE"

echo ""
echo "PRs ordered by merge date (oldest to newest):"
echo "=============================================="

# Display ordered PRs
cat "$SORTED_FILE" | while IFS='|' read -r hash date time timezone message pr; do
    echo "$date $time | PR #$pr | $hash"
    echo "  $message"
    echo ""
done

echo ""
echo "Cherry-pick commands in order:"
echo "==============================="

# Generate cherry-pick commands
cat "$SORTED_FILE" | while IFS='|' read -r hash date time timezone message pr; do
    echo "git cherry-pick -m 1 $hash  # PR #$pr - $date"
done

echo ""
read -p "Do you want to execute the cherry-picks now? (y/n) " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Starting cherry-pick process..."
    echo "If you encounter conflicts or empty commits, you can:"
    echo "  - For empty commits (already applied): git cherry-pick --skip"
    echo "  - For conflicts: resolve them, then git cherry-pick --continue"
    echo "  - To abort everything: git cherry-pick --abort"
    echo ""

    cat "$SORTED_FILE" | while IFS='|' read -r hash date time timezone message pr; do
        echo ""
        echo "=========================================="
        echo "Cherry-picking PR #$pr ($hash)..."
        echo "Date: $date $time"
        echo "=========================================="

        if git cherry-pick -m 1 "$hash"; then
            echo "✓ Successfully cherry-picked PR #$pr"
        else
            EXIT_CODE=$?
            echo ""
            echo "⚠ Cherry-pick stopped for PR #$pr"
            echo ""
            echo "This could be because:"
            echo "  1. There are conflicts that need manual resolution"
            echo "  2. The commit is empty (changes already applied)"
            echo ""
            echo "To continue:"
            echo "  - If there are conflicts: resolve them, stage the files, then run: git cherry-pick --continue"
            echo "  - If the commit is empty: run: git cherry-pick --skip"
            echo "  - To abort the entire process: run: git cherry-pick --abort"
            echo ""
            echo "After resolving, you can re-run this script and it will continue from the next PR."
            echo ""
            echo "Remaining PRs will be shown below. You can cherry-pick them manually:"
            echo "----------------------------------------------------------------"

            # Show remaining commits
            FOUND=0
            cat "$SORTED_FILE" | while IFS='|' read -r h d t tz m p; do
                if [ "$FOUND" -eq 1 ]; then
                    echo "git cherry-pick -m 1 $h  # PR #$p - $d"
                fi
                if [ "$h" = "$hash" ]; then
                    FOUND=1
                fi
            done

            rm "$TEMP_FILE" "$SORTED_FILE"
            exit 1
        fi
    done

    echo ""
    echo "=============================================="
    echo "All cherry-picks completed successfully!"
    echo "=============================================="
fi

# Cleanup
rm "$TEMP_FILE" "$SORTED_FILE"

