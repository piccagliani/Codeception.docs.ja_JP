#!/bin/sh
rm -f ./site/*.html
sed -i -e "1i ---\n---" *.md
jekyll build
git checkout -- .
