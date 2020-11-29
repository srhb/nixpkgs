{ stdenv
, fetchFromGitHub
, scons
, lib

, boost
, eigen
, fmt
, gtest
, libyamlcpp
, sundials

, python3Packages
, pythonSupport ? "none"
}:

let
  hasPython = pythonSupport != "none";
in

stdenv.mkDerivation rec {
  pname = "cantera";
  version = "2.5.0b1";
  src = fetchFromGitHub {
    owner = "Cantera";
    repo = "cantera";
    rev = "v${version}";
    sha256 = "0gvy2n6j1rd0zz548fcnv9scskzay1k94919mdh1vaidd6q1hp1s";
  };

  nativeBuildInputs = [
    scons
  ] ++ lib.optionals hasPython [
    python3Packages.cython
  ];

  buildInputs = [
    boost
    eigen
    fmt
    gtest
    libyamlcpp
    sundials
  ];

  propagatedBuildInputs = with python3Packages; lib.optionals hasPython [
    ruamel_yaml
    numpy
    setuptools
  ];

  sconsFlags = [
    # Avoid vendored deps wherever possible, we want full control.
    "system_fmt=y"
    "system_eigen=y"

    # Don't drop our (already very clean) build env, needed for includes etc.
    "env_vars=all"

    # eigen has a weird include path
    "extra_inc_dirs=${eigen}/include/eigen3"

    # FIXME: Maybe try and split this build out?
    "python_package=${pythonSupport}"
  ];

  # Make sure we don't accidentally grab a vendored dep
  postUnpack = ''
    rm -r source/ext/{fmt,googletest,sundials,yaml-cpp}
  '';

  preBuild = ''
    sconsFlagsArray+=("--jobs=$NIX_BUILD_CORES")
  '';

  meta = with lib; {
    description = "Cantera is an open-source collection of object-oriented software tools for problems involving chemical kinetics, thermodynamics, and transport processes.";
    homepage = "https://cantera.org";
    license = licenses.bsd3;
  };
}
