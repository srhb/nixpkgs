{ stdenv
, fetchurl

, autoreconfHook
, pkgconfig
, rsync

, cracklib
, kerberos
, pam
, libevent
, nspr
, nss
, openldap
, db
, sasl
, icu
, net_snmp
, pcre
, perl
, openssl
}:
let
  version = "1.4.1.2";
in
stdenv.mkDerivation rec {
  name = "389-ds-base-${version}";

  src = fetchurl {
    url = "https://releases.pagure.org/389-ds-base/389-ds-base-${version}.tar.bz2";
    sha256 = "13gdsjbrn94n8raf3amn9z5afa02r5y8g93c51b7h21g4zfg2xj1";
  };

  nativeBuildInputs = [ autoreconfHook pkgconfig ];

  buildInputs = [
    cracklib
    pam
    libevent
    nspr
    nss
    openldap
    sasl
    icu
    kerberos
    pcre
    perl
    openssl
    rsync
  ];

  postPatch = ''
    substituteInPlace include/ldaputil/certmap.h \
      --replace "nss3/cert.h" "nss/cert.h"
  '';

  preConfigure = ''
    # Fix for missing <sasl.h> during build
    export CFLAGS"=-I${sasl.dev}/include/sasl"
  '';

  configureFlags = [
    "--with-openldap"
    "--with-db"
    "--with-db-inc=${db.dev}/include"
    "--with-db-lib=${db.out}/lib"
    "--with-netsnmp=${net_snmp}"
  ];

  meta = with stdenv.lib; {
    homepage = http://www.port389.org/;
    description = "Enterprise-class Open Source LDAP server for Linux";
    license = licenses.gpl2;
    platforms = platforms.linux;
  };
}
