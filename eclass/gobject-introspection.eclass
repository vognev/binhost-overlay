# @ECLASS: gobject-introspection.eclass
# @SUPPORTED_EAPIS: 7 8 9
# @BLURB: Helper functions for (cross)building gobject-introspection
# @DESCRIPTION:
# This eclass provides common functions to run gobject-introspection tools in a cross-compilation environment.

case ${EAPI} in
	7|8|9) ;;
	*) die "${ECLASS}: EAPI ${EAPI:-0} not supported" ;;
esac

inherit sysroot

gi_cross_fake_ldd() {
    mkdir -p "${T}/shims"

    install -m0755 /dev/stdin "${T}/sysroot-fake-ldd" <<-EOF
		#!/bin/sh

		if [ "\$1" = "--version" ]; then
		    echo "ldd (Gentoo musl smart-fake-ldd via llvm-readelf)"
		    exit 0
		fi

		SO_NAMES=\$(readelf -d "\$@" | grep NEEDED | sed -r 's/.*\[(.*)\].*/\1/')

		for so in \${SO_NAMES}; do
		    FOUND_PATH=""

		    if [ -n "\${WORKDIR}" ]; then
		        FOUND_PATH=\$(find "\${WORKDIR}" -name "\${so}" -print -quit 2>/dev/null)
		    fi

		    if [ -z "\${FOUND_PATH}" ] && [ -n "\${SYSROOT}" ]; then
		        FOUND_PATH=\$(find "\${SYSROOT}/usr/lib64" "\${SYSROOT}/lib64" "\${SYSROOT}/usr/lib" "\${SYSROOT}/lib" -name "\${so}" -print -quit 2>/dev/null)
		    fi

		    if [ -n "\${FOUND_PATH}" ]; then
		        echo "\${so} => \${FOUND_PATH} (0x00007ffff7f00000)"
		    else
		        echo "\${so} => not found"
		    fi
		done
EOF

    echo "${T}/sysroot-fake-ldd"
}

gi_wrap_ir_scanner() {
    local g_ir_scanner="${1}"

    mkdir -p "${T}/shims"

    if [ -f "${T}/shims/g-ir-scanner" ]; then
        echo "${T}/shims/g-ir-scanner"
        return 0
    fi

    install -m0755 /dev/stdin "${T}/shims/g-ir-scanner" <<-EOF
		#!/bin/sh
		unset LD_LIBRARY_PATH

		export CC=$(tc-getCC)
		export CXX=$(tc-getCXX)
		unset CPP # not wrapped by cross-wrappers

		exec "${g_ir_scanner}" --use-ldd-wrapper="$(gi_cross_fake_ldd)" \
		    --use-binary-wrapper="$(sysroot_make_run_prefixed)" \
			--add-include-path="${ESYSROOT}/usr/share/gir-1.0" \
			"\$@"
EOF

    echo "${T}/shims/g-ir-scanner"
}

gi_wrap_ir_compiler() {
	local g_ir_compiler="${1}"

	mkdir -p "${T}/shims"

    if [ -f "${T}/shims/g-ir-compiler" ]; then
        echo "${T}/shims/g-ir-compiler"
        return 0
    fi

    install -m0755 /dev/stdin "${T}/shims/g-ir-compiler" <<-EOF
		#!/bin/sh
		unset LD_LIBRARY_PATH

		exec "${g_ir_compiler}" --includedir="${ESYSROOT}/usr/share/gir-1.0" "\$@"
EOF

    echo "${T}/shims/g-ir-compiler"
}

gi_wrap_ir_generate() {
    local g_ir_generate="${1}"

	mkdir -p "${T}/shims"

    if [ -f "${T}/shims/g-ir-generate" ]; then
        echo "${T}/shims/g-ir-generate"
        return 0
    fi

    install -m0755 /dev/stdin "${T}/shims/g-ir-generate" <<-EOF
		#!/bin/sh
		unset LD_LIBRARY_PATH

		exec "${g_ir_generate}" "\$@"
EOF

    echo "${T}/shims/g-ir-generate"
}

gi_shim_python() {
    mkdir -p "${T}/shims"

    install -m0755 /dev/stdin "${T}/shims/${EPYTHON}" <<-EOF
		#!/bin/sh

		SYSROOT_RUN_PREFIXED="$(sysroot_make_run_prefixed)"

		exec "\${SYSROOT_RUN_PREFIXED}" "${ESYSROOT}/usr/bin/${EPYTHON}" "\${@}"
EOF

    echo "${T}/shims/${EPYTHON}"
}


gi_cross_meson_ini() {
	local scanner_path=$(gi_wrap_ir_scanner "/usr/bin/g-ir-scanner")
	local compiler_path=$(gi_wrap_ir_compiler "/usr/bin/g-ir-compiler")
	local generate_path=$(gi_wrap_ir_generate "/usr/bin/g-ir-generate")
	local python_path=$(gi_shim_python)

	cat > "${T}/gobject-introspection.${CHOST}.${ABI}.ini" <<-EOF
		[binaries]
		g-ir-scanner = '${scanner_path}'
		g-ir-compiler = '${compiler_path}'
		g-ir-generate = '${generate_path}'
		g-ir-python3 = '${python_path}'
	EOF

	echo "${T}/gobject-introspection.${CHOST}.${ABI}.ini"
}
