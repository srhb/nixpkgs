{ stdenv, lib, fetchurl, jre_headless, makeWrapper, gawk }:

stdenv.mkDerivation rec {
  name = "cerebro-${version}";
  version = "0.7.2";

  src = fetchurl {
    url = "https://github.com/lmenezes/cerebro/releases/download/v${version}/cerebro-${version}.tgz";
    sha256 = "0jlvzbng21ps09v5vwx9mh6jfb5mwkwirm8mrvam09c356yikw63";
  };

  buildInputs = [ makeWrapper jre_headless gawk ];

  installPhase = ''
    mkdir $out
    cp -r bin conf lib README.md $out/

    wrapProgram $out/bin/cerebro \
      --set JAVA_HOME "${jre_headless}" \
      --prefix PATH : ${lib.makeBinPath [ gawk ]}

    substituteInPlace $out/conf/application.conf --replace 'data.path = "./cerebro.db"' 'data.path = "/tmp/cerebro.db"'

    cat << EOF > $out/conf/logback.xml
    <configuration>

    <conversionRule conversionWord="coloredLevel" converterClass="play.api.libs.logback.ColoredLevel"/>

    <appender name="STDOUT" class="ch.qos.logback.core.ConsoleAppender">
        <encoder>
            <pattern>%coloredLevel %logger{15} - %message%n%xException{5}</pattern>
        </encoder>
    </appender>

    <logger name="play" level="INFO"/>
    <logger name="application" level="INFO"/>

    <!-- Off these ones as they are annoying, and anyway we manage configuration ourself -->
    <logger name="com.avaje.ebean.config.PropertyMapLoader" level="OFF"/>
    <logger name="com.avaje.ebeaninternal.server.core.XmlConfigLoader" level="OFF"/>
    <logger name="com.avaje.ebeaninternal.server.lib.BackgroundThread" level="OFF"/>
    <logger name="com.gargoylesoftware.htmlunit.javascript" level="OFF"/>

    <root level="ERROR">
        <appender-ref ref="STDOUT"/>
    </root>

    </configuration> 
    EOF

  '';

  meta = with stdenv.lib; {
    homepage = https://github.com/lmenezes/cerebro/;
    description = "cerebro is an open source(MIT License) elasticsearch web admin tool built using Scala, Play Framework, AngularJS and Bootstrap.";
    license = licenses.mit;
    platforms = platforms.all;
  };

}
