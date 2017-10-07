#!/nix/store/flb9ar1xdd13c606aa4my9miy3iv4vyk-bash-4.4-p12/bin/bash
set -o xtrace
cd $(dirname $0)
find . -name text.nix
testfiles=$(find . -name test.nix)
nix-build -E "with import <nixpkgs> {}; callPackage testing/driver.nix { testFiles = [ $testfiles ]; }" --show-trace && cat result
