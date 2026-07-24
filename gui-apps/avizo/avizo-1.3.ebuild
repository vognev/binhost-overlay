# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

VALA_MIN_API_VERSION="0.48"

inherit meson vala xdg

DESCRIPTION="A neat notification daemon"
HOMEPAGE="https://github.com/heyjuvi/avizo"
SRC_URI="https://github.com/heyjuvi/avizo/archive/refs/tags/${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="
	gui-libs/gtk-layer-shell[introspection,vala]
"
DEPEND="${RDEPEND}"
BDEPEND="
	$(vala_depend)
	dev-build/meson
	virtual/pkgconfig
"

src_prepare() {
	default
	vala_setup
}

src_configure() {
	meson_src_configure
}