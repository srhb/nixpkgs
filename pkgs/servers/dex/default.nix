{ lib, buildGoPackage, fetchFromGitHub }:

let version = "2.9.0"; in

buildGoPackage rec {
  name = "dex-${version}";

  goPackagePath = "github.com/coreos/dex";

  src = fetchFromGitHub {
    rev = "v${version}";
    owner = "coreos";
    repo = "dex";
    sha256 = "03ss75aaz557ia10alyidpsv6dz35ssrhzz3jf6chb6hkd1hb77b";
  };

  subPackages = [
    "cmd/dex"
  ];

  buildFlagsArray = [
    "-ldflags=-w -X ${goPackagePath}/version.Version=${src.rev}"
  ];

  meta = {
    description = "OpenID Connect and OAuth2 identity provider with pluggable connectors";
    license = lib.licenses.asl20;
    homepage = https://github.com/coreos/dex;
    maintainers = with lib.maintainers; [benley];
    platforms = lib.platforms.unix;
  };
}
