#!/nix/store/flb9ar1xdd13c606aa4my9miy3iv4vyk-bash-4.4-p12/bin/sh -e

xsltproc --stringparam os linux generate-platforms.xsl repository-11.xml > platforms-linux.nix
xsltproc --stringparam os macosx generate-platforms.xsl repository-11.xml > platforms-macosx.nix
