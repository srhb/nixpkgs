#!/nix/store/flb9ar1xdd13c606aa4my9miy3iv4vyk-bash-4.4-p12/bin/sh -e

( echo "John Doe"
  echo "My Company"
  echo "My Organization"
  echo "My City"
  echo "My State"
  echo "US"
  echo "yes"
) | keytool --genkeypair --alias myfirstapp --keystore ./keystore --storepass mykeystore
