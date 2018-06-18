# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit eutils

MY_P="EasyRSA-${PV}"

DESCRIPTION="Small RSA key management package, based on OpenSSL"
HOMEPAGE="http://openvpn.net/"
SRC_URI="https://github.com/OpenVPN/easy-rsa/releases/download/v${PV}/${MY_P}.tgz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86"
IUSE="libressl"

DEPEND="!libressl? ( >=dev-libs/openssl-0.9.6:0 )
	libressl? ( dev-libs/libressl )"
RDEPEND="${DEPEND}
	!<net-vpn/openvpn-2.3"

S="${WORKDIR}/${MY_P}"

PATCHES=(
	"${FILESDIR}/${PN}-3.0.3-fix-paths.patch"
)

src_prepare() {
	default
	sed -i 's|./easyrsa|easyrsa|' easyrsa || die
}

src_install() {
	exeinto /usr/bin
	doexe easyrsa
	insinto /etc/easy-rsa
	newins vars.example vars
	doins openssl-1.0.cnf
	doins -r x509-types
	dodoc README.quickstart.md ChangeLog
	dodoc -r doc
}
