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

# @FUNCTION: cross_shim_help2man
# @DESCRIPTION:
# Initializes the help2man host wrapper.
cross_shim_help2man()
{
    mkdir -p "${T}/shims"

    install -m0755 /dev/stdin "${T}/shims/help2man" <<-EOF
        #!/bin/sh

        HELP2MAN=/usr/bin/help2man
        SYSROOT_RUN_PREFIXED=$(sysroot_make_run_prefixed)

        exe=""
        for arg in "\$@"; do
            if [ -x "\${arg}" ]; then
                if [ -z "\${exe}" ]; then
                    exe="\${arg}"
                else
                    echo "bashrc-cross: Found multiple executables." >&2
                    exit 1
                fi
            else
                set -- "\$@" "\${arg}"
            fi
            shift
        done

        if [ -z "\${exe}" ]; then
            exec "\${HELP2MAN}" "\$@"
        fi

        temp_file=\$(mktemp) || exit 1
        trap 'rm -f "\$temp_file"' EXIT

        echo '#!/bin/sh' > "\$temp_file"
        echo "exec \"\${SYSROOT_RUN_PREFIXED}\" \"\${exe}\" \"\\\$@\"" >> "\$temp_file"
        chmod +x "\$temp_file"

        exec "\${HELP2MAN}" "\$@" "\$temp_file"
EOF

    einfo "bashrc-cross: Injected g-ir-scanner wrapper via runtime check"
}

# @FUNCTION: cross_vapigen
# @DESCRIPTION:
# Initializes the vapigen host wrapper.
cross_vapigen()
{
    mkdir -p "${T}/shims"

    local vapigen_exe=$(basename $VAPIGEN)

    install -m0755 /dev/stdin "${T}/shims/${vapigen_exe}" <<-EOF
		#!/bin/sh

		exec ${VAPIGEN} \
		    --girdir="${ESYSROOT}/usr/share/gir-1.0" \
    	    --vapidir="${ESYSROOT}/usr/share/vala/vapi" \
		    "\$@"
EOF

    echo "${T}/shims/${vapigen_exe}"
}

# @FUNCTION: cross_pkg_config_setup
# @DESCRIPTION:
# Initializes the unified pkg-config cross-shim with dynamic variable support.
cross_pkg_config_setup() {
	tc-is-cross-compiler || return 0
    [[ "${PKG_CONFIG}" == "${T}/shims"* ]] && return 0

	local shim_dir="${T}/shims"
	mkdir -p "${shim_dir}" || die

    local real_pkg_config="${PKG_CONFIG}"
	[[ -z "${real_pkg_config}" ]] && real_pkg_config=$(tc-getPKG_CONFIG)
	[[ -z "${real_pkg_config}" ]] && real_pkg_config=pkg-config
    real_pkg_config=$(type -P "${real_pkg_config}")

	if [[ -z "${real_pkg_config}" ]]; then
		ewarn "cross-wrappers: Unable to locate original pkg-config binary!"
        return 0
	fi

	install -m0755 /dev/stdin "${shim_dir}/${CHOST}-pkg-config" <<-EOF || die
		#!/bin/sh

		if [[ ":\${PKG_CONFIG_PATH}:" != *:"${ESYSROOT}/usr/share/pkgconfig":* ]]; then
		    export PKG_CONFIG_PATH="${ESYSROOT}/usr/share/pkgconfig:\${PKG_CONFIG_PATH:+:\${PKG_CONFIG_PATH}}"
		fi

		if [[ ":\${PKG_CONFIG_PATH}:" != *:"${ESYSROOT}/usr/$(get_libdir)/pkgconfig":* ]]; then
		    export PKG_CONFIG_PATH="${ESYSROOT}/usr/$(get_libdir)/pkgconfig:\${PKG_CONFIG_PATH:+:\${PKG_CONFIG_PATH}}"
		fi

		EXTRA_DEFINES=""
		if [ -f "${T}/pkg-config.defines" ]; then
		    while IFS='=' read -r key val; do
		        [ -n "\${key}" ] && EXTRA_DEFINES="\${EXTRA_DEFINES} --define-variable=\${key}=\${val}"
		    done < "${T}/pkg-config.defines"
		fi

		exec ${real_pkg_config} \${EXTRA_DEFINES} "\$@"
EOF

	export PKG_CONFIG="${shim_dir}/${CHOST}-pkg-config"
}

# @FUNCTION: cross_pkg_config_define
# @USAGE: <variable_name> <value>
# @DESCRIPTION:
# Dynamically registers a --define-variable override for the cross-pkg-config shim.
cross_pkg_config_define() {
	tc-is-cross-compiler || return 0
	[[ $# -ne 2 ]] && die "Usage: cross_pkg_config_define <variable_name> <value>"

	# Записуємо нову змінну для шима
	echo "$1=$2" >> "${T}/pkg-config.defines" || die
	einfo "cross-wrappers: Registered pkg-config dynamic define: $1=$2"
}
