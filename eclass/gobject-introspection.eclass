# @ECLASS: gobject-introspection.eclass
# @SUPPORTED_EAPIS: 7 8 9
# @BLURB: Helper functions for (cross)building gobject-introspection
# @DESCRIPTION:
# This eclass provides common functions to run gobject-introspection tools in a cross-compilation environment.

case ${EAPI} in
	7|8|9) ;;
	*) die "${ECLASS}: EAPI ${EAPI:-0} not supported" ;;
esac

gi_cross_fake_ldd() {
    mkdir -p "${T}/bin"

    install -m0755 /dev/stdin "${T}/sysroot-fake-ldd" <<-EOF
		#!/bin/sh

		if [ "\$1" = "--version" ]; then
		    echo "ldd (Gentoo musl smart-fake-ldd via llvm-readelf)"
		    exit 0
		fi

		SO_NAMES=\$(llvm-readelf -d "\$@" | grep NEEDED | sed -r 's/.*\[(.*)\].*/\1/')

		for so in \${SO_NAMES}; do
		    FOUND_PATH=""

		    if [ -n "\${WORKDIR}" ]; then
		        FOUND_PATH=\$(find "\${WORKDIR}" -name "\${so}" -print -quit 2>/dev/null)
		    fi

		    if [ -z "\${FOUND_PATH}" -a -n "\${SYSROOT}" ]; then
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
    local INTROSPECTION_BIN_DIR="${1}"

    if [ -f "${INTROSPECTION_BIN_DIR}/g-ir-scanner.orig" ]; then
        echo "${INTROSPECTION_BIN_DIR}/g-ir-scanner"
        return 0
    fi

    mv "${INTROSPECTION_BIN_DIR}/g-ir-scanner" "${INTROSPECTION_BIN_DIR}/g-ir-scanner.orig"

    install -m0755 /dev/stdin "${INTROSPECTION_BIN_DIR}/g-ir-scanner" <<-EOF
		#!/bin/sh
		unset LD_LIBRARY_PATH

		export PYTHONPATH="${INTROSPECTION_BIN_DIR}/../../$(get_libdir)/gobject-introspection"

		export CC=$(tc-getCC)
		export CXX=$(tc-getCXX)
		export CPP=$(tc-getCPP)

		exec "${INTROSPECTION_BIN_DIR}/g-ir-scanner.orig" --use-ldd-wrapper="$(gi_cross_fake_ldd)" --use-binary-wrapper="$(sysroot_make_run_prefixed)" \$@
EOF

    echo "${INTROSPECTION_BIN_DIR}/g-ir-scanner"
}

gi_wrap_ir_compiler() {
    local INTROSPECTION_BIN_DIR="${1}"

    if [ -f "${INTROSPECTION_BIN_DIR}/g-ir-compiler.orig" ]; then
        echo "${INTROSPECTION_BIN_DIR}/g-ir-compiler"
        return 0
    fi

    mv "${INTROSPECTION_BIN_DIR}/g-ir-compiler" "${INTROSPECTION_BIN_DIR}/g-ir-compiler.orig"

    install -m0755 /dev/stdin "${INTROSPECTION_BIN_DIR}/g-ir-compiler" <<-EOF
		#!/bin/sh
		unset LD_LIBRARY_PATH

		export PYTHONPATH="${INTROSPECTION_BIN_DIR}/../../$(get_libdir)/gobject-introspection"

		exec "${INTROSPECTION_BIN_DIR}/g-ir-compiler.orig" "$@"
EOF

    echo "${INTROSPECTION_BIN_DIR}/g-ir-compiler"
}

gi_wrap_ir_generate() {
    local INTROSPECTION_BIN_DIR="${1}"

    if [ -f "${INTROSPECTION_BIN_DIR}/g-ir-generate.orig" ]; then
        echo "${INTROSPECTION_BIN_DIR}/g-ir-generate"
        return 0
    fi

    mv "${INTROSPECTION_BIN_DIR}/g-ir-generate" "${INTROSPECTION_BIN_DIR}/g-ir-generate.orig"

    install -m0755 /dev/stdin "${INTROSPECTION_BIN_DIR}/g-ir-generate" <<-EOF
		#!/bin/sh
		unset LD_LIBRARY_PATH

		export PYTHONPATH="${INTROSPECTION_BIN_DIR}/../../$(get_libdir)/gobject-introspection"

		exec "${INTROSPECTION_BIN_DIR}/g-ir-generate.orig" "$@"
EOF

    echo "${INTROSPECTION_BIN_DIR}/g-ir-generate"
}
