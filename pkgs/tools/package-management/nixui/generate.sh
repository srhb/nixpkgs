#!/nix/store/flb9ar1xdd13c606aa4my9miy3iv4vyk-bash-4.4-p12/bin/sh -e

node2nix -i pkg.json -c nixui.nix -e ../../../development/node-packages/node-env.nix
