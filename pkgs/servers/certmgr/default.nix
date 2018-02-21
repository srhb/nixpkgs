{ stdenv, buildGoPackage, fetchFromGitHub }:

buildGoPackage rec {
  version = "1.5.0";
  name = "certmgr-${version}";

  goPackagePath = "github.com/cloudflare/certmgr/";

  nativeBuildInputs = [ ];

  src = fetchFromGitHub {
    owner = "cloudflare";
    repo = "certmgr";
    rev = "v${version}";
    sha256 = "04f9bsdsnpbaqynvbmqdg024v5dccvfvxdgpzp73bgbjrv9c6vxx";
  };

  meta = with stdenv.lib; {
    homepage = https://cfssl.org/;
    description = "Cloudflare's certificate manager";
    platforms = platforms.linux;
    license = licenses.bsd2;
    maintainers = with maintainers; [ srhb ];
  };
}
