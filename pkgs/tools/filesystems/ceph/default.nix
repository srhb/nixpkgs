{ stdenv
, fetchurl
, babeltrace
, boost
, cmake
, curl
, expat
, fuse
, git
, gperf
, keyutils
, leveldb
, libaio
, linux
, lttng-ust
, nss
, openldap
, python
, pythonPackages
, snappy
, udev
, utillinux
, liburcu
, less
}:

callPackage ./generic.nix (args // rec {
  version = "9.2.0";

  buildInputs = [
    less
    liburcu
    babeltrace
    boost
    cmake
    curl
    expat
    fuse
    git
    gperf
    keyutils
    leveldb
    libaio
    linux.dev
    lttng-ust
    nss
    openldap
    python
    pythonPackages.boost
    pythonPackages.cython
    pythonPackages.sphinx
    stdenv
    snappy
    udev
    utillinux
  ];

  src = fetchurl {
    url = "http://download.ceph.com/tarballs/ceph_${version}.orig.tar.gz";
    sha256 = "05jrgjfjl14z488y5l33dyz7mkg099m4403n76xx9fikkjs38y5l";
  };

  configurePhase = ''
    patchShebangs .
    echo hi
    ./do_cmake.sh -DCMAKE_INSTALL_PREFIX="$out" -DWITH_SYSTEM_BOOST=true
    substituteInPlace src/key_value_store/kv_flat_btree_async.cc --replace \
      "/usr/include/asm-generic/" \
      "${linux.dev}/lib/modules/${linux.version}/source/include/uapi/asm-generic/"
  '';

  preBuild = ''
    cd build
  '';
  
  enableParallelBuilding = true;
}
