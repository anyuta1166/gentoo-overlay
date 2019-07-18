# Copyright 1999-2018 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit eutils

DESCRIPTION="Small RSA key management package, based on OpenSSL"
HOMEPAGE="https://openvpn.net/"
SRC_URI="https://github.com/OpenVPN/easy-rsa/releases/download/v${PV}/EasyRSA-nix-${PV}.tgz -> ${P}.tgz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86"
IUSE="+ipsec libressl"

DEPEND="!libressl? ( >=dev-libs/openssl-0.9.6:0 )
	libressl? ( dev-libs/libressl )"
RDEPEND="${DEPEND}
	!<net-vpn/openvpn-2.3"

S="${WORKDIR}/EasyRSA-${PV}"

PATCHES=(
	"${FILESDIR}/${PN}-3.0.5-fix-paths.patch"
	"${FILESDIR}/${PN}-3.0.5-p12-nopass-friendly-name.patch"
)

src_prepare() {
	default
	use ipsec && eapply "${FILESDIR}/${PN}-3.0.4-ipsec-support.patch"
	sed -i 's|./easyrsa|easyrsa|' easyrsa || die
}

src_install() {
	exeinto /usr/bin
	doexe easyrsa
	insinto /etc/easy-rsa
	newins vars.example vars
	doins openssl-easyrsa.cnf
	doins -r x509-types
	dodoc README.md README.quickstart.md ChangeLog
	dodoc -r doc
}
