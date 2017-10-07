#!/nix/store/flb9ar1xdd13c606aa4my9miy3iv4vyk-bash-4.4-p12/bin/sh

rm -rf test;
mkdir test; 
for i in *.sh; do ln -s ../$i test; done;
