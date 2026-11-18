# Copyright 2026
# Distributed under the terms of the GNU General Public License v3

EAPI=8

inherit cmake xdg

# last upstream commit touching linux/ (Qt client; the Rust rewrite is still a branch)
COMMIT=154ed17c057db38de964c679a82d71a791375bb8

DESCRIPTION="AirPods control: noise control modes, battery, ear detection, conversational awareness"
HOMEPAGE="https://github.com/kavishdevar/librepods"
SRC_URI="https://github.com/kavishdevar/librepods/archive/${COMMIT}.tar.gz -> ${P}.tar.gz"
S="${WORKDIR}/${PN}-${COMMIT}/linux"

# GPL-3 app, MIT QR-Code-generator; the bundled SF Symbols icon font is Apple's
LICENSE="GPL-3 MIT all-rights-reserved"
SLOT="0"
KEYWORDS="amd64"
RESTRICT="mirror bindist"

DEPEND="
	dev-libs/openssl:=
	dev-qt/qtbase:6[dbus,gui,network,widgets]
	dev-qt/qtconnectivity:6[bluetooth]
	dev-qt/qtdeclarative:6
	media-libs/libpulse
"
RDEPEND="
	${DEPEND}
	net-wireless/bluez
"
BDEPEND="
	dev-qt/qttools:6[linguist]
	virtual/pkgconfig
"

PATCHES=(
	# upstream tries SBC-XQ before "a2dp-sink" (= AAC): keep AAC when it re-enables audio
	"${FILESDIR}"/${PN}-prefer-aac.patch
)
