#!/nix/store/flb9ar1xdd13c606aa4my9miy3iv4vyk-bash-4.4-p12/bin/sh -e
cd "$(dirname "$0")"
sp="$(nix-build -Q --no-out-link update.nix -A update)"
cat "$sp" > upstream-info.nix
