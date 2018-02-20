{ stdenv, fetchurl }:

stdenv.mkDerivation rec {

  version = "v0.0.20";
  variant = "_0.0.20_linux_amd64";

  src = fetchurl {
    url = "https://github.com/cloudnativelabs/kube-router/releases/download/${version}/${variant}.tar.gz";
    sha256 = "03bx6d0bmxgnxzmkkvh9j24yz15gz5hqq842ap53mgdn4zj717yh";
  };

  name = "kube-router-${version}";
  phases = "unpackPhase installPhase";

  unpackPhase = "tar -xf $src";

  installPhase = ''
    mkdir -p "$out/bin"
    cp kube-router $out/bin
    chmod a+x "$out/bin/kube-router"
  '';

  meta = {
    homepage = "https://www.kube-router.io/";
    description = "Kube router - FUTURE-PROOF KUBERNETES NETWORKING";
  };
}
