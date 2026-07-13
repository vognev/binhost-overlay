EAPI=8

CRATES="
	addr2line-0.25.1
	adler2-2.0.1
	allocator-api2-0.2.18
	cc-1.2.0
	cfg-if-1.0.4
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
	rustc-demangle-0.1.27
	rustc-literal-escaper-0.0.7
	shlex-1.3.0
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

DESCRIPTION="Compile native musl std from system rust-src"
SLOT="${PV}"
KEYWORDS="amd64"

BDEPEND="=dev-lang/rust-bin-${PV}*[rust-src]"

SRC_URI="$(cargo_crate_uris)"

S="${WORKDIR}/rust-std-src/library"

src_unpack() {
	cargo_src_unpack

	mkdir -p "${WORKDIR}/rust-std-src" || die
	cp -R "/opt/rust-bin-${PV}/lib/rustlib/src/rust/library" "${WORKDIR}/rust-std-src/" || die
}

src_compile() {
	export CARGO_BUILD_TARGET="x86_64-unknown-linux-musl"
	export RUSTFLAGS="-Zforce-unstable-if-unmarked -C linker=x86_64-pc-linux-musl-clang -C link-arg=--sysroot=/usr/x86_64-pc-linux-musl -C link-arg=--rtlib=compiler-rt"
	export RUSTC_BOOTSTRAP=1

	cargo build --release -p sysroot --features llvm-libunwind
}

src_install() {
	local target_dir="/opt/rust-bin-${PV}/lib/rustlib/x86_64-unknown-linux-musl/lib"
	dodir "${target_dir}"
	cd "${WORKDIR}/rust-std-src/library/target/x86_64-unknown-linux-musl/release/deps" || die
	cp *.rlib "${D}/${target_dir}/" || die
}
