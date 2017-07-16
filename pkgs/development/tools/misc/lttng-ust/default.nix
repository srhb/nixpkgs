{ stdenv, fetchurl, liburcu, withPython ? true, python, pythonPackages }:

# NOTE:
#   ./configure ...
#   [...]
#   LTTng-UST will be built with the following options:
#
#   Java support (JNI): Disabled
#   sdt.h integration:  Disabled
#   [...]
#
# Debian builds with std.h (systemtap).

stdenv.mkDerivation rec {
  version = "2.9.1";
  name = "lttng-ust-${version}";

  src = fetchurl {
    url = "https://lttng.org/files/lttng-ust/${name}.tar.bz2";
    sha256 = "196snxrs1p205jz566rwxh7dqzsa3k16c7vm6k7i3gdvrmkx54dq";
  };

  buildInputs = [ liburcu ];
  propagatedBuildInputs = [ python ];

  preBuild = "patchShebangs tools";

  meta = with stdenv.lib; {
    description = "LTTng Userspace Tracer libraries";
    homepage = http://lttng.org/;
    license = licenses.lgpl21Plus;
    platforms = platforms.linux;
    maintainers = [ maintainers.bjornfor ];
  };

}
