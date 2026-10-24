#!/bin/zsh
# Copies the website (docs/) into the doodle-site repo checkout next to this project.
set -e
cd "$(dirname "$0")/.."
SITE="${1:-../doodle-site}"
[[ -d "$SITE/.git" ]] || { echo "No doodle-site checkout at $SITE"; exit 1; }
rsync -a --delete --exclude .git --exclude README.md docs/ "$SITE/"
touch "$SITE/.nojekyll"
echo "Website copied to $SITE. Commit and push it from there."
