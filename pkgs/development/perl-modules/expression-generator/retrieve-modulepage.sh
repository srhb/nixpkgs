#!/nix/store/flb9ar1xdd13c606aa4my9miy3iv4vyk-bash-4.4-p12/bin/sh

module_basename="$1";

./grab-url.sh "http://search.cpan.org/dist/$module_basename/" "$module_basename".html;
