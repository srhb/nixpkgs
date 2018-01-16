{ stdenv, buildGoPackage, fetchFromGitHub }:

buildGoPackage rec {
  name = "elasticsearch-exporter-${version}";
  version = "1.0.1";
  rev = "v${version}";

  goPackagePath = "github.com/justwatchcom/elasticsearch_exporter";

  src = fetchFromGitHub {
    inherit rev;
    owner = "justwatchcom";
    repo = "elasticsearch_exporter";
    sha256 = "1l200hwg6nrbw6g815jfylfkbkk4p3w6f6kglf3sa7nfz9qrcszq";
  };

  meta = with stdenv.lib; {
    description = "Prometheus exporter for elasticsearch";
    homepage = https://github.com/justwatchcom/elasticsearch_exporter;
    license = licenses.asl20;
    maintainers = with maintainers; [ eskytthe ];
    platforms = platforms.unix;
  };
}
