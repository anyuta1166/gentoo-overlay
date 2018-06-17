# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit eutils systemd

if [[ ${PV} = *9999* ]]; then
	EGIT_REPO_URI="https://github.com/TelegramMessenger/MTProxy.git"
	inherit git-r3
else
        SRC_URI=""
        KEYWORDS="~amd64 ~x86"
fi


DESCRIPTION="Simple MT-Proto proxy"
HOMEPAGE="https://github.com/TelegramMessenger/MTProxy"

LICENSE="GPL-2"
SLOT="0"
IUSE=""

DEPEND="dev-libs/openssl
	sys-libs/zlib"
RDEPEND="${DEPEND}
	net-misc/curl"

DOCS=( README.md )

PATCHES=(
        "${FILESDIR}/${PN}-9999-compile-flags.patch"
)

src_compile() {
        tc-export CC AR
	default
}


src_install() {
	dosbin objs/bin/mtproto-proxy
	exeinto "/usr/libexec/${PN}"
	doexe "${FILESDIR}/start.sh"
	keepdir "/var/lib/${PN}"
	systemd_dounit "${FILESDIR}/${PN}.service"
	systemd_dounit "${FILESDIR}/${PN}-config.service"
	systemd_dounit "${FILESDIR}/${PN}-config.timer"
        einstalldocs
}
