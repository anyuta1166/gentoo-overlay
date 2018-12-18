# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit systemd

DESCRIPTION="Recursive DNS Servers discovery Daemon (rdnssd) for IPv6"
HOMEPAGE="https://www.remlab.net/ndisc6/"
SRC_URI="https://www.remlab.net/files/${PN}/${P}.tar.bz2"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~arm ~x86 ~x64-macos"
IUSE="debug"

DEPEND="dev-lang/perl
	sys-devel/gettext"
RDEPEND=""

src_configure() {
	econf $(use_enable debug assert) \
		--localstatedir="${EPREFIX}/var"
}

src_install() {
	emake DESTDIR="${D}" install || die
	newinitd "${FILESDIR}"/rdnssd.rc-2 rdnssd || die
	newconfd "${FILESDIR}"/rdnssd.conf rdnssd || die
	systemd_dounit "${FILESDIR}"/rdnssd.service
	systemd_newtmpfilesd "${FILESDIR}/${PN}".tmpfiles.conf "${PN}".conf
	exeinto /etc/rdnssd
	newexe "${FILESDIR}"/resolvconf-2 resolvconf || die
	dodoc AUTHORS ChangeLog NEWS README || die
}
