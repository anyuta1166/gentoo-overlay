# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

PYTHON_COMPAT=( python3_{5,6} )

inherit python-single-r1 systemd

if [[ ${PV} = *9999* ]]; then
	EGIT_REPO_URI="https://github.com/alexbers/mtprotoproxy.git"
	inherit git-r3
else
	SRC_URI="https://github.com/alexbers/${PN}/archive/v${PV}.tar.gz -> ${P}.tar.gz"
	KEYWORDS="~amd64 ~x86"
fi

DESCRIPTION="Fast and simple to setup MTProto Proxy"
HOMEPAGE="https://github.com/alexbers/mtprotoproxy"

LICENSE="MIT"
SLOT="0"
IUSE=""
REQUIRED_USE="${PYTHON_REQUIRED_USE}"

DEPEND="${PYTHON_DEPS}"
RDEPEND="${DEPEND}
	|| ( dev-python/cryptography dev-python/pycryptodome dev-python/pycrypto dev-python/pyaes )
	dev-python/uvloop"

DOCS=( README.md )

src_install() {
	newsbin "${PN}.py" "${PN}"
	python_fix_shebang "${ED%/}/usr/sbin/${PN}"
	insinto /etc
	newins config.py "${PN}.conf"
	systemd_dounit "${FILESDIR}/${PN}.service"
	einstalldocs
}
