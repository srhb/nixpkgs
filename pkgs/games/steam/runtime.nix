{ stdenv, fetchurl }:

stdenv.mkDerivation rec {

  name = "steam-runtime";
  # from https://repo.steampowered.com/steamrt-images-scout/snapshots/
  version = "0.20201203.1";

  src = fetchurl {
    url = "https://repo.steampowered.com/steamrt-images-scout/snapshots/${version}/steam-runtime.tar.xz";
    sha256 = "sha256-hOHfMi0x3K82XM3m/JmGYbVk5RvuHG+m275eAC0MoQc=";
    name = "scout-runtime-${version}.tar.gz";
  };

  buildCommand = ''
    mkdir -p $out
    tar -C $out --strip=1 -x -f $src
  '';

  meta = with stdenv.lib; {
    description = "The official runtime used by Steam";
    homepage = "https://github.com/ValveSoftware/steam-runtime";
    license = licenses.unfreeRedistributable; # Includes NVIDIA CG toolkit
    maintainers = with maintainers; [ hrdinka abbradar ];
  };
}
