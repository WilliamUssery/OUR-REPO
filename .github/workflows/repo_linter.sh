#!/bin/bash
set -eo pipefail

# Lint each awesome list that this pull request adds to readme.md.
#
# A list counts as new when its URL is on an added line of the diff but not on
# a removed one. Fixing an existing entry's description or indentation shows up
# as one removed and one added line with the same URL, so it is not linted.

DIFF=$(git diff origin/main -- readme.md)

# Print the list URLs on one side of the diff: "+" for added lines, "-" for removed.
list_urls() {
	(grep "^$1" <<< "$DIFF" || true) |
	(grep -Eo 'https://[^) ]*#readme' || true) |
	sed 's/#readme$//' |
	sort -u
}

NEW_URLS=$(comm -23 <(list_urls '+') <(list_urls '-'))

if [ -z "$NEW_URLS" ]; then
	echo "No new link found in the format:  https://....#readme"
	exit 0
fi

for url in $NEW_URLS; do
	echo "Cloning $url"
	dir=$(mktemp -d)
	git clone "$url" "$dir"
	(cd "$dir" && npx awesome-lint)
done
