{ stdenv
, fetchurl
, dpkg
, makeWrapper
, zlib
}:

let
  version = "8.2.4.10";

  src = fetchurl {
    url = ftp://ftp.legato.com/pub/NetWorker/Cumulative_Hotfixes/8.2/8.2.4.10/nw824_linux_x86_64.tar.gz;
    sha256 = "07m4f0byz61q7sxq5nc99m6053b3snwgsnc55qbmacwx6vi6l4dq";
  };
in

stdenv.mkDerivation rec {
  name = "networker-client-${version}";

  inherit src;
  buildInputs = [
    dpkg
    makeWrapper
    zlib
  ];

  postUnpack = ''
    dpkg -x linux_x86_64/lgtoclnt_9999_amd64.deb linux_x86_64/client
  '';

  installPhase = ''
    mkdir -p $out/bin
    cd client
    cp -R usr/lib usr/bin opt $out
    cp -Rn usr/sbin/* $out/bin/
  '';
  
  dontMoveSbin = true;

  postFixup = let
    rpath = stdenv.lib.concatStringsSep ":" [
      "${stdenv.cc.cc.lib}/lib"
      "${zlib}/lib"
      "$out/lib"
      "$out/lib/nsr/lib64"
      "$out/lib/nsr/lib64/cst"
    ];
  in
  ''
    # Path interpreter and rpath of all executables and shared objects
    for file in $(find $out -type f \( -executable -o -name \*.so\* \) ); do
      patchelf --set-interpreter \
        ${stdenv.glibc}/lib/ld-linux-x86-64.so.2 $file || true
      patchelf --set-rpath ${rpath} $file || true
    done

    # networker has strong opinions on its executables 
    # being hardlinked. To avoid failing in case this has happened,
    # we ensure that stat lies to nsrexecd when it probes itself.

    gcc -shared -fPIC -DSTOREPATH=\"$out\" "${./fakestat.c}" -o "$out/lib/fakestat.so" -ldl

    find $out/bin -type f -executable | while read file; do
      wrapProgram "$file" --prefix LD_PRELOAD : "$out/lib/fakestat.so"
    done
  '';
}
