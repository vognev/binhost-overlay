EAPI=8

CRATES="
	addr2line-0.25.1
	adler2-2.0.1
	cc-1.2.0
	cfg-if-1.0.4
	compiler_builtins-0.1.160
	dlmalloc-0.2.11
	foldhash-0.2.0
	fortanix-sgx-abi-0.6.1
	getopts-0.2.24
	gimli-0.32.3
	hashbrown-0.16.1
	hermit-abi-0.5.2
	libc-0.2.178
	memchr-2.7.6
	miniz_oxide-0.8.9
	moto-rt-0.16.0
	object-0.37.3
	r-efi-5.3.0
	r-efi-alloc-2.1.0
	rand-0.9.2
	rand_core-0.9.3
	rand_xorshift-0.4.0
	rustc-demangle-0.1.26
	rustc-literal-escaper-0.0.7
	shlex-1.3.0
	std_detect-0.1.5
	unwinding-0.2.8
	vex-sdk-0.27.1
	wasi-0.11.1+wasi-snapshot-preview1
	wasi-0.14.4+wasi-0.2.4
	windows-link-0.2.1
	windows-sys-0.60.2
	windows-targets-0.53.5
	windows_aarch64_gnullvm-0.53.1
	windows_aarch64_msvc-0.53.1
	windows_i686_gnu-0.53.1
	windows_i686_gnullvm-0.53.1
	windows_i686_msvc-0.53.1
	windows_x86_64_gnu-0.53.1
	windows_x86_64_gnullvm-0.53.1
	windows_x86_64_msvc-0.53.1
	wit-bindgen-0.45.1
"

inherit cargo

DESCRIPTION="Compile -binhost- std from system rust-src"
SLOT="${PV}"
KEYWORDS="amd64"

BDEPEND="=dev-lang/rust-bin-${PV}*[rust-src]"

SRC_URI="$(cargo_crate_uris)"

S="${WORKDIR}/rust-std-src/library"

FAKE_TARGET_TRIPLET="x86_64-binhost-linux-gnu"

src_unpack() {
	cargo_src_unpack

	mkdir -p "${WORKDIR}/rust-std-src" || die

	cp -R "${EPREFIX}/opt/rust-bin-${PV}/lib/rustlib/src/rust/library" "${WORKDIR}/rust-std-src/" || die

	cp "${FILESDIR}/${FAKE_TARGET_TRIPLET}.json" "${WORKDIR}" || die
}

src_compile() {
	local rust_path="${EPREFIX}/opt/rust-bin-${PV}/bin"
	local target_spec_dir="${EPREFIX}/opt/rust-bin-${PV}/lib/rustlib/targets"
	local -x PATH="${rust_path}:${PATH}"
	export RUSTC="${rust_path}/rustc"

	# Keep WORKDIR first so this package can build even before first install.
	export RUST_TARGET_PATH="${WORKDIR}:${target_spec_dir}"

	einfo "Using rustc: $(rustc --version)"
	einfo "Using cargo: $(cargo --version)"
	einfo "Using RUST_TARGET_PATH: ${RUST_TARGET_PATH}"

	export CARGO_BUILD_TARGET="${FAKE_TARGET_TRIPLET}"
	export RUSTFLAGS="-Z force-unstable-if-unmarked"
	export RUSTC_BOOTSTRAP=1

	cargo build --release -p sysroot --features llvm-libunwind || die "Failed to build std"
}

src_install() {
	local target_lib_dir="/opt/rust-bin-${PV}/lib/rustlib/${FAKE_TARGET_TRIPLET}/lib"
	local target_bin_dir="/opt/rust-bin-${PV}/bin"
	local target_spec_dir="/opt/rust-bin-${PV}/lib/rustlib/targets"

	sed -e "s|@@REAL_RUSTC@@|${target_bin_dir}/rustc|g" \
		-e "s|@@RUST_TARGET_PATH@@|${target_spec_dir}|g" \
        -e "s|@@FAKE_TARGET_TRIPLET@@|${FAKE_TARGET_TRIPLET}|g" \
        "${FILESDIR}/rustc-wrapper.in" > "${T}/${FAKE_TARGET_TRIPLET}-rustc" || die

	# todo: rustdoc wraper for completeness
	exeinto "${target_bin_dir}"
	doexe "${T}/${FAKE_TARGET_TRIPLET}-rustc"

	cd "${WORKDIR}/rust-std-src/library/target/${FAKE_TARGET_TRIPLET}/release/deps" || die
	insinto "${target_lib_dir}"
	doins *.rlib

	insinto "${target_spec_dir}"
	doins "${WORKDIR}/${FAKE_TARGET_TRIPLET}.json"
}
