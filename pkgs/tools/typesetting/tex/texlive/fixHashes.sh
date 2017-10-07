#!/nix/store/flb9ar1xdd13c606aa4my9miy3iv4vyk-bash-4.4-p12/bin/sh

echo "{"
grep -v -F '.bin-' | while read path; do
    hash=`nix-hash --type sha1 --base32 "$path"`
    echo -n "$path" | sed -E 's/[^-]*-texlive-(.*)/"\1"/'
    echo "=\"$hash\";"
done
echo "}"

