{ stdenv, fetchFromGitHub }:

stdenv.mkDerivation  rec {
  version = "12.1.0";
  name = "ceph-${version}";

  src = fetchFromGitHub {
    owner = "ceph";
    repo = "ceph";
    rev = "v${version}";
    fetchSubmodules = true;
    sha256 = "0a2v3bgkrbkzardcw7ymlhhyjlwi08qmcm7g34y2sjsxk9bd78an";
  };

  configurePhase = ''
    patchShebangs .
    ./do_cmake.sh -DWITH_SYSTEM_BOOST=true
  '';

  preBuildPhase = ''
    substituteInPlace src/
    cd build
  '';
}
