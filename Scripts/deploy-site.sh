#!/bin/bash
# Builds site/ from the current working tree and force-pushes the static
# output to keelapps/keelhaven-site:gh-pages — the public repo GitHub Pages
# serves at https://keelhaven.app/ (the custom domain rides along in the build
# output as site/public/CNAME; see docs/WEBSITE.md).
#
# This is the manual twin of .github/workflows/website.yml (same output,
# same branch); use it when Actions minutes are exhausted. The workflow
# force-pushes too, so the next CI deploy simply overwrites this one.
set -euo pipefail
cd "$(dirname "$0")/.."

branch=$(git branch --show-current)
if [ "$branch" != "main" ]; then
  echo "⚠️  Deploying the working tree of '$branch', not main."
fi

npm --prefix site ci
npm --prefix site run build

dist="site/.vitepress/dist"
# Pages runs Jekyll by default, which drops VitePress's underscore-prefixed
# asset paths — .nojekyll turns that off.
touch "$dist/.nojekyll"

git -C "$dist" init -q -b gh-pages
git -C "$dist" add -A
git -C "$dist" commit -q -m "Manual deploy from $branch @ $(git rev-parse --short HEAD)"
git -C "$dist" push -q --force https://github.com/keelapps/keelhaven-site.git gh-pages
rm -rf "$dist/.git"

echo "Deployed → https://keelhaven.app/ (Pages rebuild takes ~1 min)"
