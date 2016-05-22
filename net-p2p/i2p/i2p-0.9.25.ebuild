# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI="6"

inherit eutils java-pkg-2 java-ant-2 systemd user readme.gentoo-r1

DESCRIPTION="A privacy-centric, anonymous network."
HOMEPAGE="https://geti2p.net"
SRC_URI="https://download.i2p2.de/releases/${PV}/i2psource_${PV}.tar.bz2"

LICENSE="Apache-2.0 Artistic BSD CC-BY-2.5 CC-BY-3.0 CC-BY-SA-3.0 EPL-1.0 GPL-2 GPL-3 LGPL-2.1 LGPL-3 MIT public-domain WTFPL-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="+ecdsa nls"
CDEPEND="dev-java/tomcat-jstl-impl:0
	dev-java/tomcat-jstl-spec:0
	dev-java/java-service-wrapper:0
	dev-java/jrobin:0
	dev-java/slf4j-api:0
	dev-java/slf4j-simple:0
	>=dev-java/bcprov-1.50:0"
DEPEND="${CDEPEND}
	dev-java/eclipse-ecj:*
	dev-libs/gmp:*
	nls? ( sys-devel/gettext )
	>=virtual/jdk-1.7"
RDEPEND="${CDEPEND}
	ecdsa? (
		|| (
			dev-java/icedtea:7[-sunec]
			dev-java/icedtea:8[-sunec]
			dev-java/icedtea:7[nss,-sunec]
			dev-java/icedtea-bin:7[nss]
			dev-java/icedtea-bin:7
			dev-java/icedtea-bin:8
			dev-java/oracle-jre-bin
			dev-java/oracle-jdk-bin
		)
	)
	!ecdsa? ( >=virtual/jre-1.7 )"

# Absolute path of I2P's system-wide data resources directory.
I2P_DATA_DIR="${EROOT}usr/share/${PN}"

# Absolute path of I2P's system-wide runtime state directory. 
I2P_STATE_DIR="${EROOT}var/lib/${PN}"

#* The "updater" task should be manually expunged from the "pkg" task's
#  dependencies in "build.xml" *OR*
#* The "distclean" and "installer" tasks should be run instead.
#
#We favour the latter, for obvious reasons.
EANT_BUILD_TARGET="distclean installer"
EANT_GENTOO_CLASSPATH="bcprov,tomcat-jstl-impl,tomcat-jstl-spec,java-service-wrapper,jrobin,slf4j-api,slf4j-simple"
JAVA_ANT_ENCODING="UTF-8"

pkg_setup() {
	enewgroup ${PN}
	enewuser ${PN} -1 -1 "${I2P_STATE_DIR}" ${PN}
}

src_unpack() {
	default_src_unpack
	java-ant_rewrite-classpath "${S}"/build.xml
}

src_prepare() {
	# Unconditionally avoid building Windows-specific executables.
	echo "noExe=true" >> override.properties || die '"echo" failed.'

	# Conditionally disable "gettext" support.
	if ! use nls; then
		echo "require.gettext=false" >> override.properties || die '"echo" failed.'
	fi
	eapply_user
}

src_install() {
	cd pkg-temp || die '"cd" failed.'

	# Prevent I2P startup from autostarting a browser (typically, "lynx").
	# Dismantled, this is:
	#
	# * "-n", suppressing printing of lines by default.
	# * "~p", printing only the index of I2P's UrlLauncher application.
	local url_launcher_index="$(sed -n -e\
		'/UrlLauncher/s~^clientApp\.\([0-9]\+\)\..*$~\1~p' clients.config)"
	sed -i -e\
		'/^clientApp\.'${url_launcher_index}'\.startOnLoad=/s~true~false~' \
		clients.config || die '"sed" failed.'

	# Replace I2P's default data directory with ours.
	sed -i -e 's~%INSTALL_PATH~'${I2P_DATA_DIR}'~g' \
		eepget i2prouter runplain.sh || die '"sed" failed.'
	sed -i -e 's~\$INSTALL_PATH~'${I2P_DATA_DIR}'~g' \
		wrapper.config || die '"sed" failed.'

	# Replace I2P's default user-specific home directory with the real thing.
	# Dismantled, this is:
	#
	# * "/a\", appending all following lines to the currently matched line.
	sed -i -e '/I2P=/a\
USER_HOME="$HOME"\
SYSTEM_java_io_tmpdir="$USER_HOME/.i2p"' \
		i2prouter || die '"sed" failed.'
	sed -i -e 's~%\(USER_HOME\)~$\1~g' i2prouter || die '"sed" failed.'
	sed -i -e 's~%\(SYSTEM_java_io_tmpdir\)~$\1~g' \
		i2prouter runplain.sh || die '"sed" failed.'

	# This enables us to use listed libs from system
	sed -i \
		-e '/^wrapper\.java\.classpath\.1=/a\
wrapper.java.classpath.2='${EROOT}'usr/share/bcprov/lib/*.jar\
wrapper.java.classpath.3='${EROOT}'usr/share/tomcat-jstl-impl/lib/*.jar\
wrapper.java.classpath.4='${EROOT}'usr/share/tomcat-jstl-spec/lib/*.jar\
wrapper.java.classpath.5='${EROOT}'usr/share/java-service-wrapper/lib/*.jar\
wrapper.java.classpath.6='${EROOT}'usr/share/jrobin/lib/*.jar\
wrapper.java.classpath.7='${EROOT}'usr/share/slf4j-api/lib/*.jar\
wrapper.java.classpath.8='${EROOT}'usr/share/slf4j-simple/lib/*.jar' \
		-e '/^wrapper\.java\.library\.path\.2=/a\
wrapper.java\.library\.path.3='${EROOT}'usr/lib/java-service-wrapper' \
		wrapper.config || die '"sed" failed.'

	java-pkg_jarinto "${I2P_DATA_DIR}"/lib
	for i in \
		BOB commons-el commons-logging i2p i2psnark i2ptunnel jasper-compiler \
		jasper-runtime javax.servlet jbigi jetty-* mstreaming org.mortbay.* \
		router routerconsole sam standard streaming systray systray4j; do
		java-pkg_dojar lib/${i}.jar
	done

	# Install all bundled web applications.
	java-pkg_dowar webapps/*.war

	# Install binaries.
	exeinto "${I2P_DATA_DIR}"
	doexe eepget i2prouter runplain.sh

	# Install resources.
	insinto "${I2P_DATA_DIR}"
	doins blocklist.txt hosts.txt *.config
	doins -r certificates docs eepsite geoip scripts

	# Install documentation.
	dodoc history.txt INSTALL-headless.txt LICENSE.txt
	doman man/*
	dodoc -r licenses

	# Set up symlinks for binaries
	dosym "${I2P_DATA_DIR}"/i2prouter /usr/bin/i2prouter
	dosym "${I2P_DATA_DIR}"/eepget /usr/bin/eepget
	dosym /usr/bin/wrapper "${I2P_DATA_DIR}"/i2psvc

	# Install daemon files
	newinitd "${FILESDIR}/${PN}.initd" "${PN}"
	systemd_dounit "${FILESDIR}/${PN}.service"

	keepdir "${I2P_STATE_DIR}"
	fperms 750 "${I2P_STATE_DIR}"
	fowners ${PN}:${PN} "${I2P_STATE_DIR}"

	# Contents of the "/usr/share/doc/${P}/README.gentoo" file to be installed.
	DOC_CONTENTS="
	For responsivity, I2P should typically be added the default runlevel: e.g.,\\n
	\\trc-update add i2p default\\n\\n
	After starting the I2P service, I2P will be accessible via the web-based I2P\\n
	Router Console at:\\n
	\\thttp://localhost:7657\\n\\n
	I2P customization should be isolated to \"${I2P_STATE_DIR}/.i2p/\" to\\n
	prevent future updates from overwriting changes."

	# Install Gentoo-specific documentation.
	readme.gentoo_create_doc
}

pkg_postinst() {
	readme.gentoo_print_elog

	# On subsequent updates, print the following instructions.
	if [[ -n ${REPLACING_VERSIONS} ]]; then
		elog \
'If I2P fails to properly start after this upgrade, check the I2P logfile at'
		elog \
'"/var/log/i2p/log-router-0.txt". When in doubt, the simplest solution is to'
		elog \
'remove your entire I2P configuration and begin anew: e.g.,'
		elog
		elog '    $ sudo mv '${I2P_STATE_DIR}' /tmp/.i2p.bad'
		elog '    $ sudo rc-service i2p restart'
		elog
		elog \
'While I2P does attempt to preserve backward compatibility across upgrades,'
		elog \
"Murphy's Law and personal experience suggests otherwise."
	fi

	ewarn 'Currently, the i2p team does not enforce to use ECDSA keys. But it is more and'
	ewarn 'more pushed. To help the network, you are recommended to have either:'
	ewarn '  dev-java/icedtea[-sunec,nss]'
	ewarn '  dev-java/icedtea-bin[nss]'
	ewarn '  dev-java/icedtea[-sunec] and bouncycastle (bcprov)'
	ewarn '  dev-java/icedtea-bin and bouncycastle (bcprov)'
	ewarn '  dev-java/oracle-jre-bin'
	ewarn '  dev-java/oracle-jdk-bin'
	ewarn 'Alternatively you can just use Ed25519 keys - which is a stronger algorithm anyways.'
	ewarn
	ewarn "This is purely a run-time issue. You're free to build i2p with any JDK, as long as"
	ewarn 'the JVM you run it with is one of the above listed and from the same or a newer generation'
	ewarn 'as the one you built with.'
}
