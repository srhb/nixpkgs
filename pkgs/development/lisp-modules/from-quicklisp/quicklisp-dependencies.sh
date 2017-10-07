#!/nix/store/flb9ar1xdd13c606aa4my9miy3iv4vyk-bash-4.4-p12/bin/sh

[ -z "$NIX_QUICKLISP_DIR" ] && {
  export NIX_QUICKLISP_DIR="$(mktemp -d --tmpdir nix-quicklisp.XXXXXX)"
}

[ -f "$NIX_QUICKLISP_DIR/setup.lisp" ] || {
  "$(dirname "$0")/quicklisp-beta-env.sh" "$NIX_QUICKLISP_DIR" &> /dev/null < /dev/null
}

sbcl --noinform --eval "(with-output-to-string (*standard-output*) (load \"$NIX_QUICKLISP_DIR/setup.lisp\"))" --eval "(with-output-to-string (*standard-output*) (with-output-to-string (*error-output*) (with-output-to-string (*trace-output*) (ql:quickload :$1))))" --eval "(format t \"~{~a~%~}\" (mapcar 'ql::name (mapcar 'car (cdr (ql::dependency-tree \"$1\")))))" --eval '(quit)' --script
