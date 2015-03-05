#!/bin/sh
sed -i -e "1i ---\nlayout: guides\n---" *-*.md
sed -i -e "1i ---\nlayout: default\n---" index.md
sed -i -e "1i ---\nlayout: default\n---" README.md
jekyll build
git checkout -- *.md
cp -r _assets/images _site/
cp -r _assets/javascripts _site/
cp -r _assets/stylesheets _site/
