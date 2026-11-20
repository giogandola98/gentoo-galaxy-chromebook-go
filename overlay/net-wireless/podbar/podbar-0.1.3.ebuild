# Copyright 2026
# Distributed under the terms of the GNU General Public License v3

EAPI=8

CRATES="
	arc-swap@1.9.5
	async-broadcast@0.7.2
	async-recursion@1.2.0
	async-trait@0.1.92
	autocfg@1.5.1
	bitflags@2.13.2
	bumpalo@3.20.4
	bytes@1.12.2
	cfg-if@1.0.5
	crossbeam-queue@0.3.14
	crossbeam-utils@0.8.23
	endi@1.1.1
	enumflags2@0.7.12
	enumflags2_derive@0.7.12
	equivalent@1.0.3
	errno@0.3.15
	event-listener-strategy@0.5.4
	event-listener@5.4.2
	fastrand@2.5.0
	futures-core@0.3.34
	futures-io@0.3.34
	futures-lite@2.6.1
	futures-macro@0.3.34
	futures-task@0.3.34
	futures-util@0.3.34
	getrandom@0.4.3
	hashbrown@0.17.1
	hex@0.4.3
	indexmap@2.14.2
	js-sys@0.3.107
	libc@0.2.191
	linux-raw-sys@0.12.1
	memchr@2.8.3
	memoffset@0.9.1
	mio@1.2.5
	once_cell@1.21.4
	ordered-stream@0.2.0
	parking@2.2.1
	pastey@0.2.3
	pin-project-lite@0.2.17
	proc-macro-crate@3.5.0
	proc-macro2@1.0.107
	quote@1.0.47
	r-efi@6.0.0
	rustix@1.1.6
	rustversion@1.0.23
	serde@1.0.229
	serde_core@1.0.229
	serde_derive@1.0.229
	serde_repr@0.1.21
	signal-hook-registry@1.4.8
	slab@0.4.12
	socket2@0.6.5
	syn@2.0.119
	syn@3.0.10
	tempfile@3.27.0
	tokio-macros@2.7.2
	tokio@1.54.1
	toml_datetime@1.1.3+spec-1.1.0
	toml_edit@0.25.19+spec-1.1.0
	toml_parser@1.1.5+spec-1.1.0
	tracing-attributes@0.1.31
	tracing-core@0.1.36
	tracing@0.1.44
	uds_windows@1.2.1
	unicode-ident@1.0.27
	uuid@1.29.3
	wasi@0.11.1+wasi-snapshot-preview1
	wasm-bindgen-macro-support@0.2.130
	wasm-bindgen-macro@0.2.130
	wasm-bindgen-shared@0.2.130
	wasm-bindgen@0.2.130
	windows-link@0.2.1
	windows-sys@0.61.2
	winnow@1.0.5
	zbus@5.19.0
	zbus_macros@5.19.0
	zbus_names@4.3.5
	zcheapstr@1.2.0
	zvariant@5.15.1
	zvariant_derive@5.15.1
	zvariant_utils@4.2.0
"

inherit cargo

DESCRIPTION="Bluetooth tray for Wayland bars with AirPods battery, noise control and ear detection"
HOMEPAGE="https://github.com/giogandola98/podbar"
SRC_URI="
	https://github.com/giogandola98/podbar/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz
	${CARGO_CRATE_URIS}
"

LICENSE="GPL-3+"
# Dependent crate licenses
LICENSE+=" Apache-2.0 MIT Unicode-3.0 Unlicense"
SLOT="0"
KEYWORDS="amd64"

RDEPEND="
	net-wireless/bluez
	media-libs/libpulse
"

