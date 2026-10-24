#!/bin/zsh
# Copies the website (docs/) into the doodle-pin repo checkout next to this project.
set -e
cd "$(dirname "$0")/.."
SITE="${1:-../doodle-pin}"
[[ -d "$SITE/.git" ]] || { echo "No doodle-pin checkout at $SITE"; exit 1; }
rsync -a --delete --exclude .git --exclude README.md docs/ "$SITE/"
touch "$SITE/.nojekyll"
echo "Website copied to $SITE. Commit and push it from there."
