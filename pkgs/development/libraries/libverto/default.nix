{ stdenv
, fetchFromGitHub
, autoreconfHook
, pkgconfig
}:

stdenv.mkDerivation rec {
  pname = "libverto";
  version = "0.3.1";

  src = fetchFromGitHub {
    owner = "latchset";
    repo = "libverto";
    rev = version;
    sha256 = "0m7vqfg2a9nwv9jz7mslacyv5xhfxnq7rnzdf9994mdcmrwqf1l4";
  };

  nativeBuildInputs = [ autoreconfHook pkgconfig ];

  # FIXME: Why is the original order problematic? freeipa chokes on it
  postPatch = ''
    sed -i '/exec_prefix/d' *.in
    sed -i '2iexec_prefix=@exec_prefix@' *.in
  '';

  meta = with stdenv.lib; {
    homepage = https://github.com/latchset/libverto;
    description = "An async event loop abstraction library";
    license = licenses.mit;
    platforms = platforms.linux;
    maintainers = with maintainers; [ srhb ];
  };
}
