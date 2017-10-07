{ ccacheStdenv
, fetchgit
, overrideCC
, gcc5
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
, jemalloc
, lttng-ust
, nss
, glibc
, openldap
, python
, pythonPackages
, snappy
, udev
, utillinux
, liburcu
, less
, makeWrapper
}:

let
stdenv' = ccacheStdenv;
in
stdenv'.mkDerivation rec {
  version = "12.2.1";
  name = "ceph-${version}";
  
  src = fetchgit {
    url = "https://github.com/ceph/ceph.git";
    rev   = "v${version}";
    sha256 = "1psavy89afi2zlj6slpzp57mvna3mn9860kgmldz02va9sxmxh09";
  };

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
    pythonPackages.prettytable
    pythonPackages.boost
    pythonPackages.cython
    pythonPackages.sphinx
    snappy
    udev
    utillinux
    makeWrapper
  ];

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

  postBuild = ''
    wrapProgram bin/ceph
  '';

  
  enableParallelBuilding = true;
}
