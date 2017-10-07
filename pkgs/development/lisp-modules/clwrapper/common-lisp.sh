#!/nix/store/flb9ar1xdd13c606aa4my9miy3iv4vyk-bash-4.4-p12/bin/sh

source "@out@"/bin/cl-wrapper.sh "${NIX_LISP_COMMAND:-$(@ls@ "@lisp@/bin"/* | @head@ -n 1)}" "$@"
