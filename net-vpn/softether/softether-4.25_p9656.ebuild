# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

DATE="2018.01.15"
MY_P="v${PV/_p/-}"

inherit eutils systemd

DESCRIPTION="Multi-protocol VPN software"
HOMEPAGE="http://www.softether.org/"
SRC_URI="http://www.softether-download.com/files/${PN}/${MY_P}-rtm-${DATE}-tree/Source_Code/${PN}-src-${MY_P}-rtm.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="debug"

RDEPEND="dev-libs/openssl:0=
	sys-libs/ncurses:0=
	sys-libs/readline:0=
	sys-libs/zlib"
DEPEND="${RDEPEND}"

S=${WORKDIR}/${MY_P}

DOCS=( AUTHORS.TXT ChangeLog README )
# Prohibit to modify number of threads
PATCHES=(
	"${FILESDIR}/${PN}-4.04-sandbox.patch"
	"${FILESDIR}/${PN}-4.25-compile-flags.patch"
)

src_prepare() {
	default
	sed -i -e 's|/opt/|/opt/softether/|g' systemd/*.service || die
	rm -f configure || die
	if use amd64; then
		cp src/makefiles/linux_64bit.mak Makefile || die
	elif use x86; then
		cp src/makefiles/linux_32bit.mak Makefile || die
	fi
}

src_compile() {
	tc-export CC AR RANLIB
	# -j1 is necessary to prevent random build failures due to a race condition
	emake -j1 DEBUG="$(usex debug YES NO '' '')" || die "emake failed"
}

src_install() {
	insinto "/opt/${PN}"
	doins src/bin/BuiltHamcoreFiles/unix/hamcore.se2
	for inst in vpnclient vpnserver vpnbridge vpncmd; do
		dosym ../hamcore.se2 "/opt/${PN}/${inst}/hamcore.se2"
		exeinto "/opt/${PN}/${inst}"
		doexe "bin/${inst}/${inst}"
	done
	for inst in vpnclient vpnserver vpnbridge; do
		newinitd "${FILESDIR}/${PN}-${inst}.initd" "${PN}-${inst}"
		systemd_dounit "systemd/${PN}-${inst}.service"
	done
	einstalldocs
}
