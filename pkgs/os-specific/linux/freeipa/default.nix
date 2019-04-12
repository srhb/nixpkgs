{ stdenv
, fetchFromGitHub
, autoreconfHook
, pkgconfig

, nspr
, nss
, kerberos
, openldap
, openssl
, popt
, sasl
, xmlrpc_c
, ding-libs
, _389-ds-base
, sssd
, libuuid
, talloc
, tevent
, samba
, libunistring
, libverto
, systemd

, python3
, python3Packages
}:

stdenv.mkDerivation rec {
  pname = "freeipa";
  version = "4.7.2";

  src = fetchFromGitHub {
    owner = "freeipa";
    repo = "freeipa";
    rev = "release-4-7-2";
    sha256 = "0mziavcxcha6xpc0j55y00sal2v7l0x2q8dxywl329r3n26a36na";
  };

  nativeBuildInputs = [ autoreconfHook pkgconfig ];

  buildInputs = [
    _389-ds-base
    ding-libs
    kerberos
    libunistring
    libuuid
    libverto
    nspr
    nss
    openldap
    openssl
    popt
    samba
    sasl
    sssd
    systemd
    talloc
    tevent
    xmlrpc_c
  ]
  ++ pythonInputs
  ;

  pythonInputs = with python3Packages; [
    python3
    wrapPython

    asn1crypto
    cffi
    cryptography
    dns
    ldap
    netaddr
    netifaces
    setuptools
    six
  ];

  pythonPath = pythonInputs;

  configureFlags = [
    "--with-ipaplatform=fedora"
    "--disable-server"
  ];

  postPatch = ''
    patchShebangs .
    substitute ${./paths.py} ./ipaplatform/paths.py \
      --subst-var out \
      --subst-var-by kerberos ${kerberos}
    substituteInPlace client/ipa-join.c \
      --replace "/usr/sbin/ipa-getkeytab" "$out/bin/ipa-getkeytab"
  '';

  postFixup = ''
    wrapPythonPrograms
  '';
}
