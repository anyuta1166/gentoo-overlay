# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit rebar

DESCRIPTION="unicode_util compatibility library"
HOMEPAGE="https://github.com/benoitc/unicode_util_compat"
SRC_URI="https://github.com/benoitc/${PN}/archive/${PV}.tar.gz
	-> ${P}.tar.gz"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~amd64 ~arm ~ia64 ~ppc ~sparc ~x86"

DEPEND=">=dev-lang/erlang-18.0"
RDEPEND="${DEPEND}"

DOCS=( README.md )
