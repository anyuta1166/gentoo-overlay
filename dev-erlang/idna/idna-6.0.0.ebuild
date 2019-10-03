# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit rebar

DESCRIPTION="Erlang IDNA implementation"
HOMEPAGE="https://github.com/benoitc/erlang-idna"
SRC_URI="https://github.com/benoitc/erlang-idna/archive/${PV}.tar.gz
	-> ${P}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~arm ~ia64 ~ppc ~sparc ~x86"

DEPEND=">=dev-lang/erlang-18.0
	>=dev-erlang/unicode_util_compat-0.4.1"
RDEPEND="${DEPEND}"

DOCS=( CHANGELOG README.md )

S="${WORKDIR}/erlang-idna-${PV}"

src_prepare() {
	rebar_src_prepare
	rm rebar.config.script || die
}
