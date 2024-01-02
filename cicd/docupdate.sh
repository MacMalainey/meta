#!/bin/env bash
set -e

# Update Progress page in documentation
git clone git@github.com:ZOSOpenTools/meta.git meta_update
cd meta_update
python3 tools/getbinaries.py

# Generate zopen API Reference
mkdir -p docs/api
mkdir -p docs/reference
. ./.env
export ZOPEN_ROOTFS="na" # To workaround sourcing zopen-config error
mkdir -p "man/man1/"
zopen-help2man "man/man1/" # Generate man pages

cat <<EOF > docs/reference/zopen-reference.md
# zopen reference documentation
This page provides information about the zopen interface. Click on any of the zopen commands listed below to access the reference guide describing how to utilize that command.
EOF

# Generate html and markdown pages
for man in man/man1/*.1;
do
  base=${man##*/};
  name=${base%%.1};
  html="docs/reference/${name}.html";
  echo '<iframe src="reference/'"${name}"'.html" frameborder="0" style="overflow:hidden;overflow-x:hidden;overflow-y:hidden;height:100vh;width:100vw;position:absolute;top:0px;left:0px;right:0px;bottom:0px" height="100%" width="100%"></iframe>' > docs/reference/${name}.md
  echo "* [${name}](/reference/${name})" >> docs/reference/zopen-reference.md
  groff -m mandoc -Thtml -Wall "${man}" >"${html}";
done

# Generate Release cache
python3 tools/create_release_cache.py --verbose --output-file docs/api/zopen_releases.json

# Commit it all back to the repo
git config --global user.email "zosopentools@ibm.com"
git config --global user.name "ZOS Open Tools"
git add docs/*.md
git add docs/images/*.png
git add docs/api/*
git add docs/reference/*
git commit -m "Updating docs/apis/reference"
git pull --rebase
git push origin
