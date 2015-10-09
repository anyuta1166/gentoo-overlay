# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI="5"

inherit eutils java-pkg-2 java-ant-2 systemd user readme.gentoo

DESCRIPTION="A privacy-centric, anonymous network."
HOMEPAGE="https://geti2p.net"
SRC_URI="https://download.i2p2.de/releases/${PV}/i2psource_${PV}.tar.bz2"

LICENSE="Apache-2.0 Artistic BSD CC-BY-2.5 CC-BY-3.0 CC-BY-SA-3.0 EPL-1.0 GPL-2 GPL-3 LGPL-2.1 LGPL-3 MIT public-domain WTFPL-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="nls"
DEPEND="dev-java/eclipse-ecj:*
	dev-java/jakarta-jstl
	dev-java/java-service-wrapper
	dev-java/jrobin
	dev-java/slf4j-api
	dev-java/slf4j-simple
	dev-libs/gmp:*
	nls? ( sys-devel/gettext )
	>=dev-java/bcprov-1.50:0
	>=virtual/jdk-1.6:="
RDEPEND="${DEPEND}
	>=virtual/jre-1.6"

# Absolute path of I2P's system-wide data resources directory.
I2P_DATA_DIR="${EROOT}usr/share/${PN}"

# Absolute path of I2P's system-wide runtime state directory. 
I2P_STATE_DIR="${EROOT}var/lib/${PN}"

EANT_BUILD_TARGET="distclean installer"
EANT_GENTOO_CLASSPATH="bcprov,jakarta-jstl,java-service-wrapper,jrobin,slf4j-api,slf4j-simple"

pkg_setup() {
	enewgroup ${PN}
	enewuser ${PN} -1 -1 "${I2P_STATE_DIR}" ${PN}
}

src_unpack() {
	default_src_unpack
	java-ant_rewrite-classpath "${S}"/build.xml
}

src_prepare() {
	# We're on GNU/Linux, we don't need .exe files
	echo "noExe=true" >> override.properties || die '"echo" failed.'
	if ! use nls; then
		echo "require.gettext=false" >> override.properties || die '"echo" failed.'
	fi
}

src_install() {
	cd pkg-temp || die "Where did our stuffs go?"

	# Prevent I2P startup from autostarting a browser (typically, "lynx").
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
wrapper.java.classpath.3='${EROOT}'usr/share/jakarta-jstl/lib/*.jar\
wrapper.java.classpath.4='${EROOT}'usr/share/java-service-wrapper/lib/*.jar\
wrapper.java.classpath.5='${EROOT}'usr/share/jrobin/lib/*.jar\
wrapper.java.classpath.6='${EROOT}'usr/share/slf4j-api/lib/*.jar\
wrapper.java.classpath.7='${EROOT}'usr/share/slf4j-simple/lib/*.jar' \
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

	# Set up symlinks for binaries
	dosym /usr/bin/wrapper "${I2P_DATA_DIR}"/i2psvc
	dosym "${I2P_DATA_DIR}"/i2prouter /usr/bin/i2prouter
	dosym "${I2P_DATA_DIR}"/eepget /usr/bin/eepget

	# Install main files and basic documentation
	exeinto "${I2P_DATA_DIR}"
	insinto "${I2P_DATA_DIR}"
	doins blocklist.txt hosts.txt *.config
	doexe eepget i2prouter runplain.sh
	dodoc history.txt INSTALL-headless.txt LICENSE.txt
	doman man/*

	# Install other directories
	doins -r certificates docs eepsite geoip scripts
	dodoc -r licenses
	java-pkg_dowar webapps/*.war

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
	I2P customization should be isolated to \"${EROOT}var/lib/i2p/.i2p/\" to\\n
	prevent future updates from overwriting changes."

	# Install Gentoo-specific documentation.
	readme.gentoo_create_doc
}

pkg_postinst() {
	readme.gentoo_print_elog
}
