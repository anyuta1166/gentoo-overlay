# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7
inherit autotools git-r3 systemd

DESCRIPTION="A TCP, UDP, and SCTP network bandwidth measurement tool"
HOMEPAGE="https://github.com/esnet/iperf/"
EGIT_REPO_URI="https://github.com/esnet/iperf/"

LICENSE="BSD"
SLOT="3"
KEYWORDS=""
IUSE="libressl sctp static-libs"

DEPEND="
	!libressl? ( dev-libs/openssl:0= )
	libressl? ( dev-libs/libressl:0= )
	sctp? ( net-misc/lksctp-tools )
"
RDEPEND="
	${DEPEND}
"
S=${WORKDIR}/${P/_/}
DOCS="README.md RELNOTES.md"

src_configure() {
	econf \
		$(use_enable static-libs static) \
		$(use_with sctp)
}

src_install() {
	default
	newconfd "${FILESDIR}"/iperf.confd iperf3
	newinitd "${FILESDIR}"/iperf3.initd iperf3
	systemd_dounit contrib/iperf3.service
	find "${ED}" -name '*.la' -delete || die
}
