# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
VALA_USE_DEPEND="vapigen"

inherit cmake vala virtualx gobject-introspection cross-wrappers

DESCRIPTION="Ayatana Application Indicators (Shared Library)"
HOMEPAGE="https://github.com/AyatanaIndicators/ayatana-ido"
SRC_URI="https://github.com/AyatanaIndicators/${PN}/archive/${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="LGPL-2.1 LGPL-3 GPL-3"
SLOT="0"
KEYWORDS="~alpha amd64 arm arm64 ~loong ppc ppc64 ~riscv ~sparc x86"

IUSE="test"
RESTRICT="!test? ( test )"

RDEPEND="
	>=dev-libs/glib-2.58:2
	>=dev-libs/gobject-introspection-1.82.0-r2
	>=x11-libs/gtk+-3.24:3[introspection]
"
DEPEND="
	${RDEPEND}
	x11-base/xorg-proto
"
BDEPEND="
	$(vala_depend)
	dev-util/glib-utils
	test? ( dev-cpp/gtest )
"

src_prepare() {
	cmake_src_prepare
	vala_setup
}

src_configure() {
	local mycmakeargs+=(
		-DVALA_COMPILER="${VALAC}"
		-DVAPI_GEN="${VAPIGEN}"
		-DENABLE_TESTS="$(usex test)"
	)

	if tc-is-cross-compiler; then
		local _ir_scanner=$(gi_wrap_ir_scanner "/usr/bin/g-ir-scanner")
		local _ir_compiler=$(gi_wrap_ir_compiler "/usr/bin/g-ir-compiler")
		local _ir_girdir=$(gi_ir_girdir)

		mycmakeargs+=(
			-DCMAKE_FIND_ROOT_PATH="${ESYSROOT}"
			-DINTROSPECTION_SCANNER="$_ir_scanner"
			-DINTROSPECTION_COMPILER="$_ir_compiler"
			-DINTROSPECTION_GIRDIR="$_ir_girdir"
			-DVAPI_GEN="$(cross_vapigen)"
		)
	fi

	cmake_src_configure
}

src_test() {
	virtx cmake_src_test
}
