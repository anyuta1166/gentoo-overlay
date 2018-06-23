# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit eutils

DESCRIPTION="LINUX based utility for use with gnuddrescue to aid with data recovery"
HOMEPAGE="https://sourceforge.net/projects/ddrutility/"
SRC_URI="mirror://sourceforge/${PN}/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

DOCS=( AUTHORS ChangeLog ddrutility.txt NEWS README THANKS )
HTML_DOCS=( ddrutility.html )

PATCHES=(
	"${FILESDIR}/${PN}-2.8-makefile.patch"
)

src_compile() {
	tc-export CC
	default
}
